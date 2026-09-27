# Linux Bootstrapper

This script keeps the configuration in sync between computers that run Ubuntu 26.04. You can also use it to configure the system after a new installation of the operating system.

## Usage

```bash
git clone https://github.com/benhur-araujo/linux-bootstrapper.git
cd linux-bootstrapper
./linux_bootstrapper.sh --full  # Install or update all, and apply the configs
./linux_bootstrapper.sh --diff  # Install only the missing packages (default)
```

If you give no argument, the script does the same as `--diff`. For all other arguments, the script prints the usage and stops.

## Repository layout

```text
linux_bootstrapper.sh                 # Entry point: all install/config steps
libs/helpers.sh                       # has_command, parse_args, usage, log
configs/vim/vimrc                     # Soft-linked to ~/.vimrc
configs/bash/bashrc                   # Soft-linked to ~/.bashrc
configs/bash/bash_aliases             # Soft-linked to ~/.bash_aliases
configs/bash/inputrc                  # Soft-linked to ~/.inputrc
configs/bash/blerc                    # Soft-linked to ~/.blerc
configs/teams-for-linux/              # Copied to /etc/teams-for-linux/
configs/claude/CLAUDE.md              # Soft-linked to ~/.claude/
configs/claude/settings.json          # Soft-linked to ~/.claude/
configs/claude/statusline-command.sh  # Soft-linked to ~/.claude/
configs/claude/docs/                  # Soft-linked to ~/.claude/docs
```

## Features

### General system preferences

- Add the current `$USER` to the sudoers file (sudo with no password)
- Laptop lid behavior - ignore when you close it
- Disable IPv6 with `/etc/sysctl.d`
- Enable lingering (`loginctl enable-linger`), thus the user services continue to run when you are not logged in

### APT repositories

- pgAdmin: PostgreSQL admin tool APT repository
- Terraform: HashiCorp Terraform APT repository
- VSCode: Visual Studio Code APT repository
- GitHub CLI: GitHub CLI APT repository
- Glow: Charm CLI markdown renderer APT repository
- 1Password: 1Password APT repository, with the debsig policy and keyring

### APT packages

- vim-gtk3, tree, git: Essential tools
- git-delta: Pager for git diffs with changed words highlighted
- bash-completion: Shell improvements
- flameshot: Screenshot tool
- tilix: Terminal emulator
- jq, yq, gnupg, code, gh, shellcheck, bat, glow, pre-commit: Dev tools
- ansible, terraform: IaC tools
- apt-transport-https: APT package for safe package operations
- xdotool, chrome-gnome-shell, gnome-browser-connector, xclip, zoxide
- openconnect, nmap: Network tools
- python3-pip, python3.14-venv, python3-tk: Python tools
- pgadmin4-desktop: PostgreSQL admin desktop client
- 1password-cli: 1Password command-line tool

### Installations that APT does not manage

- Google Chrome: Web browser
- ble.sh: Bash line editor for autosuggestions and syntax highlighting (nightly release, in `~/.local/share/blesh`)
- asdf: Version manager for many runtime languages (latest tag)
- kubectl: Kubernetes command-line tool
- Docker: Container platform (adds `$USER` to the `docker` group)
- Azure CLI: Microsoft Azure command-line tool
- Kubelogin: Kubernetes credential (exec) plugin for Azure authentication
- Terragrunt: Wrapper for Terraform
- Terraform-docs: Documentation generator for Terraform modules (v0.17.0)
- K9S: Kubernetes cluster TUI (latest release)
- ArgoCD CLI: Argo CD command-line tool (latest release)
- Minikube: Local Kubernetes cluster
- Helm: Kubernetes package manager
- Claude CLI: Anthropic Claude Code CLI
- Microsoft Teams: teams-for-linux, with `/etc/teams-for-linux/config.json` that enables the auth reauth recovery
- 1Password: 1Password desktop application
- uv: Python package and project manager

### Package configurations

- Tilix: Set as the default terminal, appearance changes (transparency, size, font), and keybindings for sessions, tabs, paging and zoom
- Vim: `configs/vim/vimrc` soft-linked to `~/.vimrc` (vim-plug with `context.vim`, 4-space indentation, relative numbers, system clipboard), and the `vim-terraform` plugin cloned into `~/.vim/pack/plugins/start`
- Bash: `configs/bash/bashrc` (based on the Ubuntu default, with a prompt that shows the full path and the git branch), `configs/bash/bash_aliases`, `configs/bash/inputrc` (vi mode, history search on Up and Down) and `configs/bash/blerc` (ble.sh settings) soft-linked into `~`. The kubectl, `k`, helm and asdf completions are generated into `~/.local/share/bash-completion/completions`
- Git: Global user name and email, and `delta` as the pager (changed-word highlight, line numbers, side-by-side view)
- Claude Code: `configs/claude` soft-linked into `~/.claude` (`CLAUDE.md`, `settings.json`, `statusline-command.sh`, `docs`)

### Gnome preferences

- Ubuntu Dock settings
- Show the battery percent
- Never suspend automatically (on battery or AC)
- Permit a speaker volume more than 100%
- Remove the trash from the Ubuntu dock
- Windows and workspaces settings (4 fixed workspaces, custom switch and move shortcuts)
- Custom shortcuts for Bluetooth, Flameshot, Mute Mic, and Sound Settings
- Changes to the default shortcuts (Home, switch-applications, screenshot UI)
- Disable the Desktop Icons NG (DING) extension

### Gnome extensions

- Clipboard History
- Notification Counter
- Dash to Panel
- Space Bar

## Notes

- The script is for Ubuntu 26.04. Some package names are related to the release, for example `python3.14-venv`.
- You must have `sudo`. The first `sudo` command asks for a password. After that, `$USER` can use sudo with no password.
- The Claude Code, Bash and Vim soft-links point to the clone directory. The Claude Code soft-links also need `~/.claude` to exist. Do not move or delete the clone after a run.
- Personal values are in the code. Change them before you run the script with a different account: the git `user.name` and `user.email` in `linux_bootstrapper.sh`, and the `PATH` entries and the script aliases in `configs/bash/bashrc` and `configs/bash/bash_aliases`.
- The shell configuration is for Bash only. The script does not change your default shell. If your default shell is not Bash, run `chsh -s /bin/bash`.
- Log out and log in again after the first run, thus the `docker` group membership becomes effective.
- Examine the script and change it for your requirements.
