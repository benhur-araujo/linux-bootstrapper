#!/bin/bash

# I have 2 computers running Ubuntu 26.04. I'm having a hard time keeping their configs synced.
# I've created this script to do that for me.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR

# source library functions
source "$SCRIPT_DIR/libs/helpers.sh"

# Default running mode
is_full_install=false

########## General System Preferences ###############
configure_system() {
    # Add current user to sudoers file
    echo "%$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/"$USER" > /dev/null
    echo "$USER added to sudoers file"

    # Laptop Lid behavior - Ignore when closing it
    sudo sed -i "s/^#HandleLidSwitch=suspend$/HandleLidSwitch=ignore/" /etc/systemd/logind.conf

    # Disable IPv6
    sudo tee /etc/sysctl.d/99-disable-ipv6.conf >/dev/null <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF

    # Keep session manager running when I'm not logged in
    sudo loginctl enable-linger "$USER"
}

########## Add APT Sources ###########
add_apt_sources() {
    # pgAdmin
    if [[ ! -f /usr/pgadmin4/bin/pgadmin4 ]]; then
        curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /etc/apt/keyrings/packages-pgadmin-org.gpg
        sudo sh -c 'echo "deb [signed-by=/etc/apt/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
    fi

    # Terraform
    if ! has_command terraform; then
        curl -sL -o gpg https://apt.releases.hashicorp.com/gpg 
        gpg --dearmor gpg && sudo mv -f gpg.gpg /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        rm gpg
    fi

    # vscode
    if ! has_command code; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
    fi
    
    # Github CLI
    if ! has_command gh; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    fi

    # Glow - CLI Markdown render
    if ! has_command glow; then
        curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    fi 

    # 1Password
    if ! has_command op; then
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
        sudo tee /etc/apt/sources.list.d/1password.list && \
        sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
        curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
        sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
        sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
        curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
        sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
    fi
}


########## Install APT Packages ##########
install_prerequisites() {
    sudo apt update -y > /dev/null
    sudo apt install -y \
        curl \
        wget \
        gpg \
        software-properties-common > /dev/null
}

install_apt_packages() {
    local apt_packages=(vim-gtk3 tree git zsh bash-completion flameshot tilix jq yq \
              gnupg terraform apt-transport-https \
              code xdotool chrome-gnome-shell gnome-browser-connector xclip gh shellcheck ansible bat zoxide python3-pip pre-commit openconnect nmap glow python3.14-venv python3-tk pgadmin4-desktop 1password-cli)

    log "### APT Packages ###"
    sudo apt update -y > /dev/null
    sudo apt install -y "${apt_packages[@]}" > /dev/null 2>&1
    log "### Installed Packages ###"
    log "${apt_packages[@]}"
}

########## Non-package manager Installations ##########
install_non_apt_apps() {
    log -e "\n### Non-APT Packages ###"

    # Google Chrome
    if ! has_command google-chrome || $is_full_install; then
        curl -sL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i /tmp/chrome.deb > /dev/null
        log "Chrome Installed"
    else
        log "Chrome already installed"
    fi

    # Oh My Zsh
    if [[ ! -d ~/.oh-my-zsh ]] || $is_full_install; then
        rm -rf ~/.oh-my-zsh
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o install.sh
        sed -i '/exec\ zsh\ -l/d' install.sh
        bash install.sh > /dev/null 2>&1
        log "Oh My Zsh installed"
        rm install.sh
    else
        log "oh-my-zsh already installed"
    fi

    # asdf
    if ! has_command asdf || $is_full_install; then
        local asdf_latest_version
        asdf_latest_version="$(git ls-remote --tags --sort=v:refname https://github.com/asdf-vm/asdf.git | awk -F"/" '{print $3}'| tail -1)"
        rm -rf ~/.asdf
        git clone -q https://github.com/asdf-vm/asdf.git ~/.asdf --branch "$asdf_latest_version" > /dev/null 2>&1
        log "asdf Installed"
        
    else
        log "asdf already installed"

    fi

    # kubectl
    if ! has_command kubectl || $is_full_install; then
        curl -sLO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        log "Kubectl Installed"
        rm -f kubectl
    else 
        log "kubectl already installed"
    fi

    # docker
    if ! has_command docker || $is_full_install; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sed -i 's/sleep\ 20/sleep\ 1/' get-docker.sh
        sudo sh get-docker.sh > /dev/null 2>&1
        sudo usermod -aG docker "$USER"
        log "Docker Installed"
        rm -f get-docker.sh
    else
        log "Docker already installed"
    fi
    
    # AZURE-CLI
    if ! has_command az || $is_full_install; then
     	curl -fsSL 'https://azurecliprod.blob.core.windows.net/$root/deb_install.sh' | sudo bash   
        sudo az aks install-cli > /dev/null 2>&1
        log "az-cli Installed and kubelogin installed"
    else
        log "az-cli already installed"
        if ! has_command kubelogin; then
            az aks install-cli
            log "kubelogin installed"
        else
            log "kubelogin already installed"
        fi
    fi

    # Terragrunt
    if ! has_command terragrunt || $is_full_install; then
        curl -sSfL --proto '=https' --tlsv1.2 https://terragrunt.com/install | bash
        log "terragrunt installed"
    else
        log "terragrunt already installed"
    fi    

    # Terraform-docs
    if ! has_command terraform-docs || $is_full_install; then
        curl -sLo /tmp/terraform-docs.tar.gz https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-$(uname)-amd64.tar.gz
        tar -xzf /tmp/terraform-docs.tar.gz -C /tmp
        chmod +x /tmp/terraform-docs
        sudo mv /tmp/terraform-docs /usr/local/bin/terraform-docs
        echo "Terraform-docs installed"
    else
        log "terraform-docs already installed"
    fi
    
    # K9S
    if ! has_command k9s || $is_full_install; then
        local k9s_latest_version
        k9s_latest_version="$(git ls-remote --tags --sort=v:refname https://github.com/derailed/k9s.git | awk -F"/" '{print $3}'| tail -1 | sed 's/\^{}//')"
        wget -q https://github.com/derailed/k9s/releases/download/"$k9s_latest_version"/k9s_linux_amd64.deb
        sudo apt install ./k9s_linux_amd64.deb > /dev/null 2>&1
        rm k9s_linux_amd64.deb
    else
        log "K9S already installed"
    fi

    # ArgoCD CLI
    if ! has_command argocd || $is_full_install; then
        local argocd_version
        argocd_version="$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
        curl -sSL -o "/tmp/argocd-${argocd_version}" "https://github.com/argoproj/argo-cd/releases/download/${argocd_version}/argocd-linux-amd64"
        chmod +x "/tmp/argocd-${argocd_version}"
        sudo mv "/tmp/argocd-${argocd_version} /usr/local/bin/argocd"
    else
        log "ArgoCD CLI already installed"
    fi
    
    # MiniKube
    if ! has_command minikube || $is_full_install; then
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        rm minikube-linux-amd64
    else
        log "Minikube already installed"
    fi

    # Helm
    if ! has_command helm || $is_full_install; then
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    else
        log "helm already installed"
    fi

    # Claude CLI
    if ! has_command claude || $is_full_install; then
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    # Microsoft Teams
    if ! has_command teams-for-linux || $is_full_install; then
        curl -fsSL https://repo.teamsforlinux.de/install.sh | sudo bash
        sudo install -D -m 644 "$SCRIPT_DIR/configs/teams-for-linux/config.json" \
            /etc/teams-for-linux/config.json
    fi
    
    # 1Password
    if ! has_command 1password || $is_full_install; then
        curl -fsSL -o /tmp/onepassword.deb https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
        sudo apt install /tmp/onepassword.deb -y > /dev/null
        log "1Password installed"
    fi

    # Python UV
    if ! has_command uv || $is_full_install; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        log "Python UV installed"
    fi
}



########## Configure Applications ###########
configure_apps() {
    log -e "\n### Apply Apps configs ###"
    # Tilix as default
    echo "com.gexperts.Tilix.desktop" > ~/.config/ubuntu-xdg-terminals.list

    # Tilix appearance
    local tilix_profile
    tilix_profile="$(gsettings get com.gexperts.Tilix.ProfilesList default | tr -d "'")"
    dconf write /com/gexperts/Tilix/profiles/"$tilix_profile"/background-transparency-percent "20"
    dconf write /com/gexperts/Tilix/profiles/"$tilix_profile"/default-size-columns "140"
    dconf write /com/gexperts/Tilix/profiles/"$tilix_profile"/default-size-rows "40"
    dconf write /com/gexperts/Tilix/profiles/"$tilix_profile"/font "'Monospace 11'"


    # Tilix shortcuts
    dconf write /com/gexperts/Tilix/keybindings/session-close "'<Ctrl><Alt>w'"
    dconf write /com/gexperts/Tilix/unsafe-paste-alert false
    dconf write /com/gexperts/Tilix/use-tabs true
    for i in {1..9}; do
        dconf write /com/gexperts/Tilix/keybindings/win-switch-to-session-$i "'<Ctrl>$i'"
    done
    dconf write /com/gexperts/Tilix/keybindings/win-switch-to-previous-session "'<Ctrl><Shift>Tab'"
    dconf write /com/gexperts/Tilix/keybindings/win-switch-to-next-session "'<Ctrl>Tab'"
    dconf write /com/gexperts/Tilix/keybindings/terminal-close "'<Ctrl><Shift>w'"
    dconf write /com/gexperts/Tilix/keybindings/terminal-page-down "'Page_Down'"
    dconf write /com/gexperts/Tilix/keybindings/terminal-page-up "'Page_Up'"
    dconf write /com/gexperts/Tilix/keybindings/terminal-zoom-out "'<Ctrl>underscore'"
    log "Tilix Configured"

    # vim
    cp "$SCRIPT_DIR"/configs/vimrc ~/.vimrc
	if [[ ! -d ~/.vim/pack/plugins/start/vim-terraform ]]; then
		git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
		log "vim-terraform installed"
    elif [[ -d ~/.vim/pack/plugins/start/vim-terraform && $is_full_install ]]; then
		rm -rf ~/.vim/pack/plugins/start/vim-terraform
		git clone https://github.com/hashivim/vim-terraform.git ~/.vim/pack/plugins/start/vim-terraform
		log "vim-terraform updated"
	else
		log "vim-terraform already installed"
	fi
	log "Vim configured"

    # ZSH
    if [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]]; then
        git clone -q https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        log "zsh-autosuggestions Installed"
    elif [[ -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions && $is_full_install ]]; then
        rm -rf ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        git clone -q https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
        log "zsh-autosuggestions Updated"
    else
        log "zsh-autosuggestions already installed"
    fi
    
	if [[ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]]; then
        git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        log "zsh-syntax-highlighting Installed"
    elif [[ -d ~/.oh-my-zsh/plugins/zsh-syntax-highlighting && $is_full_install ]]; then
        rm -rf ~/.oh-my-zsh/plugins/zsh-syntax-highlighting
        git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        log "zsh-syntax-highlighting Updated"
    else
        log "zsh-syntax-highlighting already installed"
    fi   
	
    if [[ ! -d ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete ]]; then
        mkdir -p ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete
        kubectl completion zsh > ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete/kubectl-autocomplete.plugin.zsh
        log "kubectl-autocomplete installed"
    elif [[ -d ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete && $is_full_install ]]; then
        rm -rf ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete
        mkdir -p ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete
        kubectl completion zsh > ~/.oh-my-zsh/custom/plugins/kubectl-autocomplete/kubectl-autocomplete.plugin.zsh
        log "kubectl-autocomplete Updated"
    else
        log "kubectl-autocomplete already installed"
    fi   
    
    cp "$SCRIPT_DIR"/configs/zshrc ~/.zshrc
    log "Zsh configured"

    # Git
    git config --global user.email "benhur.araujo.silva@gmail.com"
    git config --global user.name "benhur-araujo"

    # Claude Code
    ln -sfn "$SCRIPT_DIR/configs/claude/docs" ~/.claude/docs
    ln -sfn "$SCRIPT_DIR/configs/claude/CLAUDE.md" ~/.claude/CLAUDE.md
    ln -sfn "$SCRIPT_DIR/configs/claude/statusline-command.sh" ~/.claude/statusline-command.sh
    ln -sfn "$SCRIPT_DIR/configs/claude/settings.json" ~/.claude/settings.json
}

########## Gnome Settings ##########
configure_gnome() {
    log -e "\n### Gnome Preferences ###"
    # Ubuntu Dock
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 20

    # Show battery percentage
    gsettings set org.gnome.desktop.interface show-battery-percentage true

    # Never auto-suspend
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout 0
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0

    # Allow speaker above 100%
    gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true

    # Remove trash from dock
    gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false

    # Manage Windows & Workspaces
    gsettings set org.gnome.shell.app-switcher current-workspace-only true
    gsettings set org.gnome.shell.extensions.dash-to-dock isolate-monitors true
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces 4
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Primary>7']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Primary>8']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Primary>9']"
    gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Primary>0']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Primary><Shift>7']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Primary><Shift>8']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Primary><Shift>9']"
    gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Primary><Shift>0']"

    # Custom shortcuts
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'bluetooth settings'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-control-center bluetooth'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Ctrl><Alt>b'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'flameshot'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'sh -c -- "flameshot gui"'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding 'Print'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ name 'Mute Mic'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ command 'bash -c "amixer set Capture toggle"'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/ binding '<Ctrl><Alt>m'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ name 'Sound Settings'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ command 'gnome-control-center sound'
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/ binding '<Ctrl><Alt>s'
    
    # Change default Shortcuts
    gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"
    gsettings set org.gnome.desktop.wm.keybindings switch-applications "[]"   
    gsettings set org.gnome.shell.keybindings show-screenshot-ui "[]"

    # Disable Desktop Icons NG (DING) extension
    gnome-extensions disable ding@rastersoft.com    

    log "Gnome preferences applied"
}

install_gnome_extensions() {
    log -e "\n### Gnome Extensions ###"

    local extension_urls=(
        "https://extensions.gnome.org/extension-data/clipboard-historyalexsaveau.dev.v48.shell-extension.zip"
        "https://extensions.gnome.org/extension-data/NotificationCountercoolllsk.v13.shell-extension.zip"
        "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v73.shell-extension.zip"
        "https://extensions.gnome.org/extension-data/space-barluchrioh.v37.shell-extension.zip"
    )

    for extension in "${extension_urls[@]}"; do
        wget -qO extension.zip "$extension"
        gnome-extensions install --force extension.zip > /dev/null
        rm extension.zip
    done

    local -a user_extensions
    readarray -t user_extensions < <(gnome-extensions list --user)
    for extension in "${user_extensions[@]}"; do
        gnome-extensions enable "$extension"
        log "$extension installed"
    done
}


main() {
    local mode="${1:---diff}"
    parse_args "$mode"
    install_prerequisites

    configure_system
    add_apt_sources
    install_apt_packages
    install_non_apt_apps
    configure_apps
    configure_gnome
    install_gnome_extensions
    log -e "\n##### Finished! ######"
}

main "$@"
