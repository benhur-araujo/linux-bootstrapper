# Bash Review 01 — linux_bootstrapper.sh

Review questions on the bash concepts used in `linux_bootstrapper.sh`
and `libs/helpers.sh`.

## Progress

| Question | Topic | Status |
|---|---|---|
| 1 | `readonly` and exit status | Answered — correct |
| 2 | `[@]` against `[*]` | Answered — corrected |
| 3 | `set -e` suspension | Answered — correct |
| 4 | `sudo` and redirection | Answered — mechanism corrected |
| 5 | Pipelines and subshells | Answered — correct |
| 6 | `${1:---diff}` | Answered — partial |
| 7 | Booleans in `[[ ]]` | Answered — correct |
| 8 | `pipefail` | Answered — correct |
| 9 | Here-doc delimiter quoting | Answered — partial |
| 10 | `ln -sfn` | Open |
| 11 | Redirection order | Open |
| 12 | Brace expansion | Open |

## Question 1 — readonly and exit status

Why split `SCRIPT_DIR="$(...)"` and `readonly SCRIPT_DIR` onto two lines?

### My answer

The exit code of `readonly SCRIPT_DIR="$(cmd)"` is always 0 because of the
`readonly` command.

### Key points

- `readonly` is a builtin command. The line's exit status is the command's
  status, so the failure of `$(cmd)` is lost.
- Same for `local`, `declare`, `export`, `typeset`. Lines 139, 210 and 221
  split for this reason.
- With `set -e` a failing `cd`/`pwd` does not abort. `SCRIPT_DIR` holds a
  wrong value and `source` fails later with a confusing message.
- A plain `SCRIPT_DIR="$(cmd)"` is an assignment, not a command, so its
  status is the status of the command substitution.

## Question 2 — array expansion

What is the difference between `"${apt_packages[@]}"` and
`"${apt_packages[*]}"`?

### My answer

The whole array items separated by spaces.

### Correction

That describes `[*]`. Both are quoted, but quoting acts differently:

- `"${arr[@]}"` gives N separate words, one for each element. Quoting is
  applied to each element.
- `"${arr[*]}"` gives one single word. Elements are joined by the first
  character of `IFS`.

```bash
files=("my report.pdf" "notes.txt")
rm "${files[@]}"   # 2 args, correct
rm "${files[*]}"   # 1 arg,  fails
rm ${files[@]}     # 3 args, deletes the wrong files
```

Rule: `[@]` keeps element boundaries, `[*]` removes them. Use `[@]` for
arguments.

## Question 3 — set -e suspension

Why does `set -e` not abort at `if ! has_command gh; then`?

### My answer

`set -e` ignores the command exit status in `if` conditionals.

### Key points

`set -e` is off in these contexts:

- The condition of `if`, `while`, `until`.
- Any command followed by `&&` or `||`, except the last of the chain.
- Any command with a `!` before it.
- All commands of a pipeline except the last one.

The rule: `-e` is off where the shell already uses the exit status to make
a decision.

Two traps:

- Suspension does not go into a function body, but it applies to the
  function call. `has_command` is safe only because you always call it in
  a condition.
- `((count++))` returns 1 when the result is 0, so it kills the script
  under `-e`. Use `count=$((count+1))` or `((count++)) || true`.

## Question 4 — sudo and redirection

Why does `sudo echo "text" > /etc/foo` fail with permission denied?

### My answer

`echo` runs as sudo, but the redirection opens a new shell with my user,
and my user can have no permission to write in that location.

### Correction

No new shell is opened. The redirection is done by the current shell,
before `sudo` runs.

Order of operations for a simple command:

1. Parse the line.
2. Expand words.
3. Set up redirections — `open()` is called here, as your user.
4. `fork()` and `exec()` the command.

The `open()` at step 3 fails, so step 4 never happens. `sudo` is never
executed.

Fixes used in the script:

- Line 20: `echo "..." | sudo tee file > /dev/null`. The `open()` happens
  inside `tee`, which runs as root.
- Line 42: `sudo sh -c 'echo "..." > file'`. A root shell does the
  redirection. The single quotes must stay, so that `$(lsb_release -cs)`
  is expanded by the root shell.
- Line 27: `sudo tee file <<EOF`. Same `tee` method, with a here-doc on
  stdin.

## Question 5 — pipelines and subshells

Why `readarray -t arr < <(cmd)` and not `cmd | readarray -t arr`?

### My answer

`readarray` would run in a subshell and the result is discarded.

### Key points

- Each component of a pipeline runs in its own subshell. The array is
  filled in a child that exits immediately. The failure is silent.
- `<(cmd)` is process substitution. It makes a `/dev/fd/63` handle, and
  the outer `<` redirects it into stdin. There is no pipeline, so
  `readarray` runs in the main shell.
- `shopt -s lastpipe` is an alternative, but it works only when job
  control is off.
- Process substitution hides the exit status of the inner command. If
  `gnome-extensions list` fails, the loop does nothing and `set -e` sees
  no error.

## Question 6 — default value expansion

What does `${1:---diff}` mean, and which `set` option makes it necessary?

### My answer

It parses the first argument. If it does not exist, it uses `--diff` as
the default.

### Key points

- Read it as `${1` + `:-` + `--diff}`. Only the first dash belongs to the
  operator.
- `${1:-x}` substitutes when `$1` is unset **or empty**. `${1-x}`
  substitutes only when `$1` is unset. Your form is the correct one.
- The same colon rule applies to `${x:=v}`, `${x:?msg}` and `${x:+v}`.
- The option not named: `set -u`. Without `:-`, an unset `$1` aborts the
  script with `$1: unbound variable`.
- `"$@"` with zero arguments is exempt from `-u`, so `main "$@"` is safe.

## Question 7 — booleans in double brackets

Inside `[[ $is_full_install ]]`, what does bash test?

### My answer

`[[ false ]]` returns true. `$is_full_install` as a bare command runs
`false`.

### Key points

- A single word inside `[[ ]]` is shorthand for `[[ -n word ]]`. The
  string `false` is not empty, so the test is true.
- As a bare command, `true` and `false` are builtins that return 0 and 1.
  The string value becomes a real exit status.
- Live bug: lines 309, 322, 333 and 345 use the string form, so those
  `elif` branches always run. In `--diff` mode the script re-clones
  vim-terraform and the zsh plugins on each run.

Fixes, best first:

```bash
elif [[ -d ~/.vim/... && $is_full_install == true ]]; then
elif [[ -d ~/.vim/... ]] && $is_full_install; then
```

Guard: never put a boolean variable bare inside `[[ ]]`.

## Question 8 — pipefail

Without `pipefail`, what is the status of
`curl -f https://bad.url | sudo gpg --dearmor -o keyring.gpg`?

### My answer

`curl` fails but `gpg` succeeds, exit 0, and it writes an empty keyring.

### Key points

- Default: the status of a pipeline is the status of the last command
  only. With `pipefail` it is the rightmost non-zero status.
- The empty keyring is the worst result. The script continues and writes
  the `.list` file. The error appears at the next `apt update`, far from
  the cause, and breaks apt for all other packages.
- `-f` in `curl -fsS` is necessary. Without it, curl returns 0 on an HTTP
  404 and pipes the HTML error page into `gpg`. `pipefail` cannot help
  there.
- Flags: `-f` fail on HTTP error, `-s` silent, `-S` show errors with
  `-s`, `-L` follow redirects.
- Line 118 has no `-f`. A 404 writes an HTML page to `/tmp/chrome.deb`.

## Question 9 — here-doc delimiter quoting

Why does `<<EOF` expand `$USER` and `<<'EOF'` not?

### My answer

`'EOF'` treats everything as simple strings. `<<EOF` runs expansions.

### Key points

- The quoting of the **delimiter word** decides, not the body. `<<'EOF'`,
  `<<"EOF"` and `<<\EOF` all have the same effect.
- Unquoted expands more than variables: `$( )`, backticks and `\`
  escapes are all active.
- Line 27 wanted `<<'EOF'`. The body has no `$` today, but quote by
  default and unquote only when expansion is necessary.
- `helpers.sh:10` is correctly unquoted, because `$0` must expand.
- `<<-EOF` removes leading tabs (not spaces) from the body and the
  delimiter. `<<<"string"` is a here-string, one line on stdin.

## Question 10 — ln -sfn

`ln -sfn "$SCRIPT_DIR/configs/claude/docs" ~/.claude/docs`. What does `-n`
do, and what goes wrong on the second run with plain `ln -sf`?

### My answer

Not answered.

## Question 11 — redirection order

What does `2>&1 > /dev/null` do, and why is it not the same as
`> /dev/null 2>&1`?

### My answer

Not answered.

## Question 12 — brace expansion

Does `for i in {1..$count}` loop? Why?

### My answer

Not answered.

## Bugs found in the script

1. `linux_bootstrapper.sh:225` — the closing quote is in the wrong place,
   so `mv` gets one argument with a space. ArgoCD install always fails.
2. Lines 309, 322, 333, 345 — `$is_full_install` inside `[[ ]]` is always
   true, so `--diff` re-clones the plugins on each run.
3. Line 333 — the path has no `custom/` element, so it never matches the
   directory made at line 331.
4. Line 118 — `curl -sL` has no `-f`.
