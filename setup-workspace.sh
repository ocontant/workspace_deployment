#!/bin/bash
# Workspace Setup Script for Ubuntu
# Recreates shell configuration, tools, and development environment

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   log_error "This script should not be run as root"
   exit 1
fi

log_info "Starting workspace setup for Ubuntu..."

# Update system packages
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log_info "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    unzip \
    zip \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    fish \
    starship \
    exa \
    bat \
    fd-find \
    ripgrep \
    fzf \
    htop \
    tree \
    jq \
    terraform \
    tofu \
    tilix \
    google-chrome-stable \
    firefox \
    poppler-utils \
    pdftk \
    qpdf \
    ghostscript

log_success "Essential packages installed"

# Add Google Chrome repository and install if not already available
log_info "Setting up Google Chrome repository..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable || log_warning "Chrome may already be installed"

# Install Pulumi
log_info "Installing Pulumi..."
curl -fsSL https://get.pulumi.com | sh
export PATH="$HOME/.pulumi/bin:$PATH"

log_success "Browsers and Pulumi installed"

# Install pyenv
log_info "Installing pyenv..."
curl https://pyenv.run | bash

# Add pyenv to PATH for current session
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

log_success "pyenv installed"

# Install NVM and Node.js
log_info "Installing NVM and Node.js..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Source NVM for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install specific Node version for Claude Code
nvm install v24.4.1
nvm use v24.4.1

log_success "NVM and Node.js v24.4.1 installed"

# Install Claude Code
log_info "Installing Claude Code..."
npm install -g @anthropic-ai/claude-code

log_success "Claude Code installed"

# Set Fish as default shell
log_info "Setting Fish as default shell..."
sudo chsh -s $(which fish) $USER

log_success "Fish shell set as default"

# Install Fisher (Fish package manager)
log_info "Installing Fisher for Fish shell..."
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

# Install Fish plugins
log_info "Installing Fish plugins..."
fish -c "fisher install jorgebucaran/nvm.fish"
fish -c "fisher install PatrickF1/fzf.fish"
fish -c "fisher install jethrokuan/z"
fish -c "fisher install gazorby/fish-abbreviation-tips"
fish -c "fisher install laughedelic/pisces"
fish -c "fisher install nickeb96/puffer-fish"
fish -c "fisher install IlanCosman/tide@v6"
fish -c "fisher install reitzig/sdkman-for-fish"

log_success "Fish plugins installed"

# Create directories
log_info "Creating necessary directories..."
mkdir -p ~/.config/fish/functions
mkdir -p ~/.venvs
mkdir -p ~/bin
mkdir -p ~/.local/bin

# Configure Bash
log_info "Configuring Bash..."
cat > ~/.bashrc << 'EOF'
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# Window size check
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Colored prompt
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# Terminal title
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
esac

# Enable color support of ls and add aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Common aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Load bash aliases if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Enable programmable completion
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Starship prompt
eval "$(starship init bash)"

# Tool completions
complete -C /usr/bin/terraform terraform
complete -C /usr/bin/tofu tofu

# Pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Chrome wrapper for WSL transparency bug fix
alias chrome="google-chrome --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox"

# Tilix integration for WSL
if command -v tilix >/dev/null && [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    alias tilix-here="tilix --working-directory=\$(pwd)"
fi
EOF

log_success "Bash configuration created"

# Configure Fish
log_info "Configuring Fish shell..."
cat > ~/.config/fish/config.fish << 'EOF'
if status is-interactive
  # Starship prompt
  starship init fish | source

  # Environment variables
  set -gx EDITOR nvim
  set -gx BROWSER firefox
  set -gx PAGER less
  set -gx ANSIBLE_HOST_KEY_CHECKING False
  set -gx GPG_TTY (tty)
  set -gx GNUPGHOME ~/.gnupg
  
  if status is-interactive
      set -gx GPG_TTY (tty)
      set -gx GNUPGHOME ~/.gnupg

      # Start GPG agent if not running
      if not pgrep -x gpg-agent >/dev/null
          gpg-agent --daemon --enable-ssh-support >/dev/null 2>&1
      end

      # Update GPG agent TTY
      gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  end

  # Add common paths
  fish_add_path /usr/local/bin
  fish_add_path ~/.local/bin
  fish_add_path ~/.cargo/bin
  fish_add_path ~/.pulumi/bin
  fish_add_path ~/bin
  
  # Aliases
  alias ll 'ls -la'
  alias la 'ls -A'
  alias l 'ls -CF'
  alias ..='cd ..'
  alias ...='cd ../..'
  alias ....='cd ../../..'

  # Git aliases
  alias g git
  alias ga 'git add'
  alias gc 'git commit'
  alias gco 'git checkout'
  alias gp 'git push'
  alias gl 'git pull'
  alias gs 'git status'
  alias gd 'git diff'
  alias glog='git log --oneline'

  # IaC Tool Aliases
  alias tf='terraform'
  alias tg='terragrunt'
  alias k='kubectl'
  alias d='docker'
  alias dc='docker-compose'
  alias v='vagrant'
  alias p='packer'

  status --is-interactive; and pyenv init - | source

  # Modern replacements
  if command -v exa >/dev/null
    alias ls exa
    alias tree 'exa --tree'
  end

  if command -v bat >/dev/null
    alias cat bat
  end

  if command -v fd >/dev/null
    alias find fd
  end

  if command -v rg >/dev/null
    alias grep rg
  end

  # Browser aliases with WSL support
  alias chrome="google-chrome --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox"
  alias firefox-safe="firefox --safe-mode"
  
  # Tilix integration for WSL
  if command -v tilix >/dev/null; and test -n "$WSL_DISTRO_NAME"
      alias tilix-here="tilix --working-directory=(pwd)"
      alias th="tilix-here"
  end

  # Custom keybindings
  bind \cH backward-kill-word  # Ctrl+H to delete word backward
  bind \e\[3\;5~ kill-word     # Ctrl+Delete to delete word forward
end
EOF

# Create Fish functions
log_info "Creating Fish functions..."

# Claude function - matches your current setup exactly
cat > ~/.config/fish/functions/claude.fish << 'EOF'
function claude
  nvm use v24.4.1
  ~/.local/share/nvm/v24.4.1/bin/claude $argv
end
EOF

# mkcd function
cat > ~/.config/fish/functions/mkcd.fish << 'EOF'
function mkcd
  mkdir -p $argv && cd $argv
end
EOF

# extract function
cat > ~/.config/fish/functions/extract.fish << 'EOF'
function extract
  switch $argv[1]
    case '*.tar.bz2'
        tar xjf $argv[1]
    case '*.tar.gz'
        tar xzf $argv[1]
    case '*.bz2'
        bunzip2 $argv[1]
    case '*.rar'
        unrar x $argv[1]
    case '*.gz'
        gunzip $argv[1]
    case '*.tar'
        tar xf $argv[1]
    case '*.tbz2'
        tar xjf $argv[1]
    case '*.tgz'
        tar xzf $argv[1]
    case '*.zip'
        unzip $argv[1]
    case '*.Z'
        uncompress $argv[1]
    case '*.7z'
        7z x $argv[1]
    case '*'
        echo "Unknown archive format"
  end
end
EOF

# backup function
cat > ~/.config/fish/functions/backup.fish << 'EOF'
function backup
  set timestamp (date +%Y%m%d_%H%M%S)
  cp -r $argv[1] "$argv[1]_backup_$timestamp"
  echo "Backup created: $argv[1]_backup_$timestamp"
end
EOF

# serve function
cat > ~/.config/fish/functions/py_serve.fish << 'EOF'
function serve
  set port 8000
  if test (count $argv) -gt 0
      set port $argv[1]
  end
  python3 -m http.server $port
end
EOF

# weather function
cat > ~/.config/fish/functions/weather.fish << 'EOF'
function weather
  set location (string join '+' $argv)
  if test -z "$location"
      curl -s "wttr.in/?format=3"
  else
      curl -s "wttr.in/$location?format=3"
  end
end
EOF

# venv function
cat > ~/.config/fish/functions/venv.fish << 'EOF'
function venv --description "Activate Python virtual environment"
  if test -z "$argv"
      echo "Usage: venv <environment_name>"
      return 1
  end
  
  set venv_path "$HOME/.venvs/$argv[1]"
  if not test -d $venv_path
      echo "Creating virtual environment: $argv[1]"
      python3 -m venv $venv_path
  end
  
  source $venv_path/bin/activate.fish
end
EOF

# venv-create function
cat > ~/.config/fish/functions/venv-create.fish << 'EOF'
function venv-create --description "Create a new Python virtual environment"
  if test -z "$argv"
      echo "Usage: venv-create <environment_name>"
      return 1
  end
  
  set venv_path "$HOME/.venvs/$argv[1]"
  if test -d $venv_path
      echo "Virtual environment '$argv[1]' already exists"
      return 1
  end
  
  python3 -m venv $venv_path
  echo "Virtual environment '$argv[1]' created at $venv_path"
end
EOF

# venv-list function
cat > ~/.config/fish/functions/venv-list.fish << 'EOF'
function venv-list --description "List all Python virtual environments"
  if test -d "$HOME/.venvs"
      ls -1 "$HOME/.venvs"
  else
      echo "No virtual environments directory found"
  end
end
EOF

# venv-remove function
cat > ~/.config/fish/functions/venv-remove.fish << 'EOF'
function venv-remove --description "Remove a Python virtual environment"
  if test -z "$argv"
      echo "Usage: venv-remove <environment_name>"
      return 1
  end
  
  set venv_path "$HOME/.venvs/$argv[1]"
  if not test -d $venv_path
      echo "Virtual environment '$argv[1]' does not exist"
      return 1
  end
  
  rm -rf $venv_path
  echo "Virtual environment '$argv[1]' removed"
end
EOF

# Azure MCP function
cat > ~/.config/fish/functions/add-azure-mcp.fish << 'EOF'
function add-azure-mcp --description "Add all Azure MCP servers to Claude Code configuration"
    echo "Adding Azure MCP servers to Claude Code..."

    # Azure Best Practices Read Only
    claude mcp add-json "azure-best-practices-read-only" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "bestpractices"], "type": "stdio"}'

    # Azure CLI Read Only
    claude mcp add-json "azure-cli-read-only" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "extension"], "type": "stdio"}'

    # Azure Monitor Read Only
    claude mcp add-json "azure-monitor-read-only" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "monitor", "--read-only"], "type": "stdio"}'

    # Azure Terraform Best Practices
    claude mcp add-json "azure-terraform-best-practices" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "azureterraformbestpractices"], "type": "stdio"}'

    # Azure Bicep
    claude mcp add-json "azure-bicep" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "bicepschema"], "type": "stdio"}'

    # Azure App Config
    claude mcp add-json "azure-app-config" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "appconfig"], "type": "stdio"}'

    # Azure Foundry
    claude mcp add-json "azure-foundry" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "foundry"], "type": "stdio"}'

    # Azure Key Vault
    claude mcp add-json "azure-key-vault" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "keyvault"], "type": "stdio"}'

    # Azure PostgreSQL
    claude mcp add-json "azure-postgresql" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "postgres"], "type": "stdio"}'

    # Azure Redis Cache
    claude mcp add-json "azure-redis-cache" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "redis"], "type": "stdio"}'

    # Azure Resource Group
    claude mcp add-json "azure-resource-group" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "group"], "type": "stdio"}'

    # Azure RBAC
    claude mcp add-json "azure-rbac" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "role"], "type": "stdio"}'

    # Azure Service Bus
    claude mcp add-json "azure-service-bus" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "servicebus"], "type": "stdio"}'

    # Azure SQL Database
    claude mcp add-json "azure-sql-database" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "sql"], "type": "stdio"}'

    # Azure Storage
    claude mcp add-json "azure-storage" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "storage"], "type": "stdio"}'

    # Azure Subscription
    claude mcp add-json "azure-subscription" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "subscription"], "type": "stdio"}'

    # Azure AKS
    claude mcp add-json "azure-aks" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "aks"], "type": "stdio"}'

    # Azure Kusto
    claude mcp add-json "azure-kusto" '{"command": "npx", "args": ["-y", "@azure/mcp@latest", "server", "start", "--namespace", "kusto"], "type": "stdio"}'

    echo "All Azure MCP servers have been added to Claude Code configuration."
end
EOF

log_success "Fish functions created"

# Configure Starship prompt
log_info "Configuring Starship prompt..."
mkdir -p ~/.config
cat > ~/.config/starship.toml << 'EOF'
format = """
[░▒▓](#a3aed2)\
[  ](bg:#a3aed2 fg:#090c0c)\
[](bg:#769ff0 fg:#a3aed2)\
$directory\
[](fg:#769ff0 bg:#394260)\
$git_branch\
$git_status\
[](fg:#394260 bg:#212736)\
$nodejs\
$rust\
$golang\
$php\
$python\
[](fg:#212736 bg:#1d2230)\
$time\
[ ](fg:#1d2230)\
$line_break$character"""

[directory]
style = "fg:#e3e5e5 bg:#769ff0"
format = "[ $path ]($style)"
truncation_length = 3
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "

[git_branch]
symbol = ""
style = "bg:#394260"
format = '[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'

[git_status]
style = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'

[nodejs]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[rust]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[golang]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[php]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[python]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[time]
disabled = false
time_format = "%R" # Hour:Minute Format
style = "bg:#1d2230"
format = '[[  $time ](fg:#a0a9cb bg:#1d2230)]($style)'

[line_break]
disabled = false

[character]
disabled = false
success_symbol = '[](bold fg:green)'
error_symbol = '[](bold fg:red)'
vimcmd_symbol = '[](bold fg:cyan)'
vimcmd_replace_one_symbol = '[](bold fg:purple)'
vimcmd_replace_symbol = '[](bold fg:purple)'
vimcmd_visual_symbol = '[](bold fg:yellow)'
EOF

log_success "Starship prompt configured"

# Create useful aliases
log_info "Creating additional aliases..."
cat > ~/.bash_aliases << 'EOF'
# System aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Git aliases
alias g='git'
alias ga='git add'
alias gc='git commit'
alias gco='git checkout'
alias gp='git push'
alias gl='git pull'
alias gs='git status'
alias gd='git diff'
alias glog='git log --oneline'

# Infrastructure as Code
alias tf='terraform'
alias tg='terragrunt'
alias k='kubectl'
alias d='docker'
alias dc='docker-compose'
alias v='vagrant'
alias p='packer'

# Browser aliases
alias chrome='google-chrome --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage --no-sandbox'
alias firefox-safe='firefox --safe-mode'

# Tilix shortcuts for WSL
if command -v tilix >/dev/null && [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    alias tilix-here='tilix --working-directory=$(pwd)'
    alias th='tilix-here'
fi

# Modern tools (if available)
command -v exa >/dev/null && alias ls='exa' && alias tree='exa --tree'
command -v bat >/dev/null && alias cat='bat'
command -v fd >/dev/null && alias find='fd'
command -v rg >/dev/null && alias grep='rg'
EOF

log_success "Aliases created"

# Final setup steps
log_info "Running final setup steps..."

# Update fish completions
fish -c "fish_update_completions"

# Configure tide prompt
log_info "Configuring Tide prompt for Fish..."
fish -c "tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --lean_prompt_height='Two lines' --prompt_connection=Disconnected --prompt_spacing=Compact --icons='Many icons' --transient=No"

log_success "Workspace setup completed!"

echo ""
log_info "Setting up Tilix for WSL integration..."
if [[ -n "${WSL_DISTRO_NAME:-}" ]]; then
    # Create Tilix Windows launcher script for WSL
    cat > ~/bin/tilix-windows << 'EOF'
#!/bin/bash
# Launch Tilix from WSL via Windows executable
if command -v tilix.exe >/dev/null 2>&1; then
    tilix.exe "$@"
elif [[ -f "/mnt/c/Program Files/Tilix/tilix.exe" ]]; then
    "/mnt/c/Program Files/Tilix/tilix.exe" "$@"
else
    echo "Tilix not found in Windows. Please install Tilix on Windows."
    echo "Download from: https://github.com/gnunn1/tilix/releases"
fi
EOF
    chmod +x ~/bin/tilix-windows
    log_success "Tilix WSL integration configured"
else
    log_info "Not running in WSL, skipping Windows-specific Tilix setup"
fi

echo ""
log_info "Configuring PDF support..."
# Add PDF aliases for common operations
cat >> ~/.bash_aliases << 'EOF'

# PDF utilities
alias pdf-merge='pdftk *.pdf cat output merged.pdf'
alias pdf-info='pdfinfo'
alias pdf-text='pdftotext'
alias pdf-compress='gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile='
EOF

# Add PDF functions to Fish
cat >> ~/.config/fish/functions/pdf-merge.fish << 'EOF'
function pdf-merge --description "Merge PDF files"
    if test (count $argv) -lt 2
        echo "Usage: pdf-merge output.pdf input1.pdf input2.pdf ..."
        return 1
    end
    
    set output $argv[1]
    set inputs $argv[2..-1]
    
    pdftk $inputs cat output $output
    echo "Merged PDFs into $output"
end
EOF

cat >> ~/.config/fish/functions/pdf-compress.fish << 'EOF'
function pdf-compress --description "Compress PDF file"
    if test (count $argv) -ne 2
        echo "Usage: pdf-compress input.pdf output.pdf"
        return 1
    end
    
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=$argv[2] $argv[1]
    echo "Compressed $argv[1] to $argv[2]"
end
EOF

log_success "PDF support configured"

echo ""
log_info "Next steps:"
echo "1. Log out and log back in (or run 'exec fish') to start using Fish shell"
echo "2. Run 'claude --help' to verify Claude Code installation"
echo "3. Run 'add-azure-mcp' to set up Azure MCP tools"
echo "4. For WSL: Install Tilix on Windows and use 'tilix-windows' command"
echo "5. Test PDF tools with 'pdf-merge', 'pdf-compress', or 'pdftotext'"
echo "6. Use 'chrome' for Chrome with transparency bug fixes"
echo "7. Customize your configuration files as needed"
echo ""
log_success "Your workspace is ready!"