#!/bin/bash
# Claude Code status line.
# Displays: git repository name, git branch, context window size used,
# token quota used in the 5-hour window, model effort level, model name.
# All fields are sourced from the JSON payload Claude Code passes on stdin,
# with git commands (skipping optional locks) as a fallback for repo/branch.

# All payload fields are read with one jq call, because the status line is
# drawn many times and each process start adds delay.
# A "-" marks a field that the payload does not give.
# shellcheck disable=SC2016
IFS=$'\t' read -r cwd repo_name branch used_tokens used_5h effort model < <(
  /bin/cat | jq -r '[
    (.workspace.current_dir // .cwd // "-"),
    (.workspace.repo.name // "-"),
    (.workspace.git_worktree // "-"),
    (.context_window.total_input_tokens // "-"),
    (.rate_limits.five_hour.used_percentage // "-"),
    (.effort.level // "unknown"),
    (.model.display_name // "unknown")
  ] | @tsv'
)
for field in cwd repo_name branch used_tokens; do
  [ "${!field}" = "-" ] && printf -v "$field" '%s' ""
done

# Makes a token count easier to read, e.g. 3990925 -> 4.0M tokens.
humanize_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM tokens", n/1000000;
    else if (n >= 1000) printf "%.1fk tokens", n/1000;
    else printf "%d tokens", n;
  }'
}

# --- Git repository name ---
if [ -z "$repo_name" ] && [ -n "$cwd" ]; then
  toplevel=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  [ -n "$toplevel" ] && repo_name=$(basename "$toplevel")
fi
[ -z "$repo_name" ] && repo_name="no-repo"

# --- Git branch ---
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi
[ -z "$branch" ] && branch="no-branch"

# --- Context tokens used (absolute count, human-readable) ---
# total_input_tokens reflects tokens currently in the context window
# (including cache reads/writes), i.e. the actual context size used.
if [ -n "$used_tokens" ]; then
  context_display=$(humanize_tokens "$used_tokens")
else
  context_display="N/A"
fi

# --- Token quota used in the 5-hour window ---
# Green is less than 50% used, yellow 50% to 80%, red more than 80%.
if [ "$used_5h" = "-" ]; then
  quota_5h="5h: N/A"
else
  if [ "$used_5h" -lt 50 ]; then
    quota_color="1;32"
  elif [ "$used_5h" -le 80 ]; then
    quota_color="1;33"
  else
    quota_color="1;31"
  fi
  quota_5h=$(printf '5h: \033[%sm%s%%\033[0m' "$quota_color" "$used_5h")
fi

printf "\033[1;36m%s\033[0m \033[1;32m(%s)\033[0m \033[1;33mCtx: %s\033[0m %s \033[0;37m[%s]\033[0m \033[1;34m%s\033[0m\n" \
  "$repo_name" "$branch" "$context_display" "$quota_5h" "$effort" "$model"
