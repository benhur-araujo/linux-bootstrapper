#!/bin/bash
# Claude Code status line.
# Displays: git repository name, git branch, context window size used, model name.
# All fields are sourced from the JSON payload Claude Code passes on stdin,
# with git commands (skipping optional locks) as a fallback for repo/branch.

input=$(/bin/cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

# --- Git repository name ---
repo_name=$(echo "$input" | jq -r '.workspace.repo.name // empty')
if [ -z "$repo_name" ] && [ -n "$cwd" ]; then
  toplevel=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
  [ -n "$toplevel" ] && repo_name=$(basename "$toplevel")
fi
[ -z "$repo_name" ] && repo_name="no-repo"

# --- Git branch ---
branch=$(echo "$input" | jq -r '.workspace.git_worktree // empty')
if [ -z "$branch" ] && [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi
[ -z "$branch" ] && branch="no-branch"

# --- Context tokens used (absolute count, human-readable) ---
# total_input_tokens reflects tokens currently in the context window
# (including cache reads/writes), i.e. the actual context size used.
used_tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
if [ -n "$used_tokens" ]; then
  context_display=$(awk -v n="$used_tokens" 'BEGIN {
    if (n >= 1000000) printf "%.1fM tokens", n/1000000;
    else if (n >= 1000) printf "%.1fk tokens", n/1000;
    else printf "%d tokens", n;
  }')
else
  context_display="N/A"
fi

# --- Model name ---
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

printf "\033[1;36m%s\033[0m \033[1;32m(%s)\033[0m \033[1;33mCtx: %s\033[0m \033[1;34m%s\033[0m\n" \
  "$repo_name" "$branch" "$context_display" "$model"
