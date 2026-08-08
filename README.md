## Linux Bootstraper
This script is designed to help keep configurations synchronized between computers running Ubuntu 26.04, or to configure the system after a fresh O.S installation.

### Usage
```bash
git clone https://github.com/benhur-araujo/linux-bootstraper.git
cd linux-bootstraper
./linux_bootstraper.sh --full  # Install or update everything, and apply configs
./linux_bootstraper.sh --diff  # Install only missing packages, and apply configs (default)
```
Running the script with no argument is equivalent to `--diff`. Any other argument prints the usage and exits.

### Repository layout
```
linux_bootstraper.sh              # Entry point: all install/config steps
libs/helpers.sh                   # has_command, get_opt, usage, log
configs/vimrc                     # Copied to ~/.vimrc
configs/zshrc                     # Copied to ~/.zshrc
configs/etc/teams-for-linux/      # Copied to /etc/teams-for-linux/
```
The script resolves its own directory, so it can be invoked from anywhere, but it must be run from a clone because it copies files out of `configs/`.

### Features
#### General system preferences
- Add current `$USER` to the sudoers file (passwordless sudo)
- Laptop lid behavior - ignore when closing it
- Disable IPv6 via `/etc/sysctl.d`
- Enable lingering (`loginctl enable-linger`) so user services keep running while logged out
- Create `~/.claude` soft-links to the `ai-workflow` project (docs, CLAUDE.md, skills, settings.json, statusline-command.sh)

#### Bootstrap dependencies
Installed first, before any repository is added: `curl`, `wget`, `gpg`, `software-properties-common`.

#### Add APT Repositories
- pgAdmin: PostgreSQL admin tool APT repository
- Terraform: HashiCorp Terraform APT repository
- VSCode: Visual Studio Code APT repository
- GitHub CLI: GitHub CLI APT repository
- Glow: Charm CLI markdown renderer APT repository
- 1Password: 1Password APT repository, including the debsig verification policy and keyring

#### APT Packages Installations
- vim-gtk3, tree, git: Essential tools
- zsh, bash-completion: Shell enhancements
- flameshot: Screenshot tool
- tilix: Terminal emulator
- jq, yq, gnupg, code, gh, shellcheck, bat, glow, pre-commit: Dev tools
- ansible, terraform: IaC tools
- apt-transport-https: APT package for secure package handling
- xdotool, chrome-gnome-shell, gnome-browser-connector, xclip, zoxide
- openconnect, nmap: Networking tools
- python3-pip, python3.14-venv, python3-tk: Python tooling
- pgadmin4-desktop: PostgreSQL admin desktop client
- 1password-cli: 1Password command-line tool

#### Non-Package Managed Installations
- Google Chrome: Web browser
- Oh My Zsh: Zsh configuration framework
- asdf: Version manager for multiple runtime languages (latest tag)
- kubectl: Kubernetes command-line tool
- Docker: Containerization platform (adds `$USER` to the `docker` group)
- AZURE CLI: Microsoft Azure command-line tool
- Kubelogin: A Kubernetes credential (exec) plugin implementing Azure authentication
- Terragrunt: Wrapper for Terraform
- Terraform-docs: Documentation generator for Terraform modules (pinned to v0.17.0)
- K9S: Kubernetes cluster TUI (latest release)
- ArgoCD CLI: Argo CD command-line tool (latest release)
- Minikube: Local Kubernetes cluster
- Helm: Kubernetes package manager
- Claude CLI: Anthropic Claude Code CLI
- Microsoft Teams: teams-for-linux, plus `/etc/teams-for-linux/config.json` enabling auth reauth recovery
- 1Password: 1Password desktop application

#### Packages Configurations
- Tilix: Set as default terminal, appearance tweaks (transparency, size, font), and custom keybindings for sessions, tabs, paging and zoom
- Vim: `configs/vimrc` copied to `~/.vimrc` (vim-plug bootstrap with `context.vim`, 4-space indentation, relative numbers, system clipboard), plus the `vim-terraform` plugin cloned into `~/.vim/pack/plugins/start`
- Zsh: `configs/zshrc` copied to `~/.zshrc` (robbyrussell theme with a custom prompt, kubectl/general aliases, az/aws/terragrunt/helm completions), plus the zsh-autosuggestions, zsh-syntax-highlighting and kubectl-autocomplete plugins under `~/.oh-my-zsh/custom/plugins`
- Git: Global user name and email

#### Gnome Preferences
- Ubuntu Dock settings
- Show battery percentage
- Never auto-suspend (on battery or AC)
- Remove trash from the Ubuntu dock
- Manage Windows & Workspaces settings (4 fixed workspaces, custom switch/move shortcuts)
- Custom shortcuts for Bluetooth, Flameshot, Mute Mic, and Sound Settings
- Change default shortcuts (Home, switch-applications, screenshot UI)
- Disable Desktop Icons NG (DING) extension

#### Gnome Extensions
Downloaded from `extensions.gnome.org` at URLs pinned to a specific extension version, installed, then every user extension is enabled.

- Clipboard History
- Notification Counter
- Dash to Panel
- Space Bar

### Notes
- This script assumes Ubuntu 26.04 as the operating system. Some package names are release-specific (for example `python3.14-venv`).
- `sudo` is required. The first `sudo` call prompts for a password; afterwards `$USER` is granted passwordless sudo.
- The `~/.claude` soft-links expect `~/.claude` to exist and `~/github-projects/ai-workflow` to be cloned.
- Personal values are hardcoded and should be changed before running on another account: the git `user.name`/`user.email` in `linux_bootstraper.sh`, and the `PATH` entries and script aliases in `configs/zshrc`.
- Log out and back in after the first run so the `docker` group membership and the zsh default shell take effect.
- Make sure to review and customize the script based on your requirements.
