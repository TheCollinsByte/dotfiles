#!/bin/bash
# Interactive shell aliases. Sourced by ~/.bashrc via ~/.config/shell/.
#
# SC2139: several aliases intentionally expand $EDITOR/$HOME at definition
#         time so the alias body is fixed once the shell starts.
# SC2142: the awk bodies below use escaped \$1/\$3, which the shell does not
#         expand — these are awk field references, not shell positionals.
# shellcheck disable=SC2139,SC2142

# Aliases
alias q="exit"
alias ls='ls --color=auto'

# IntelliJ IDEA - finds the latest version automatically
# Note: Update base paths if your installations are elsewhere
if [ -d "/opt/intellij" ]; then
    alias intellij='wmname LG3D; $(printf "%s\n" /opt/intellij/idea-*/bin/idea.sh | sort -V | tail -1)'
fi

# Electrum - finds the latest version automatically
[ -d "/opt/electrum" ] && alias e='$(find /opt/electrum/Electrum-*/run_electrum 2>/dev/null | sort -V | tail -1)'

alias l='xtrlock -b'

alias scs="cd $HOME/.local/bin/statusbar/"

alias pupgrade='sudo pacman -Syu'   # Upgrade the System
alias pclean='sudo pacman -Scc'     # Clean the cache
alias yupgrade='yay -Syu'           # Fetch the database from the official repositories, update all your official packages and the packages from the AUR
alias yclean='yay -Sc --aur'        # Clean AUR Cache
alias pyclean='yay -Sc'             # Clean both the pacman and yay caches

# Cloudflare WARP
alias wup='warp-cli connect'        # VPN on
alias wdown='warp-cli disconnect'   # VPN off
alias wst='warp-cli status'         # Connection state
alias wip='curl -s https://www.cloudflare.com/cdn-cgi/trace | grep -E "^(warp|ip)="'   # Verify egress goes through WARP

# tmux aliases
alias tmux="tmux -u"
alias tns="tmux new -s"

alias py='python3'

alias df='df -h -x squashfs -x tmpfs -x devtmpfs'
alias lsmount='mount | column -t'
alias extip='curl icanhazip.com'
alias mem5='ps auxf | sort -nr -k 4 | head -5' # Top 5 process using the most memory
alias cpu5='ps auxf | sort -nr -k 3 | head -5' # Top 5 CPU hungry process


alias c='clear'
alias cat='bat --paging=never'

alias vimrc="vim ~/.vimrc"
alias nvimrc="nvim ~/.config/nvim/init.vim"
alias vim="nvim"
alias bashrc="$EDITOR ~/.bashrc"
alias alia="$EDITOR ~/.config/shell/aliases.sh"
alias enva="$EDITOR ~/.config/shell/envars.sh"

alias k="kubectl" 

alias lt='ls --human-readable --size -1 -S --classify'      # Sort by file size
alias mnt="mount | awk -F' ' '{ printf \"%s\t%s\n\",\$1,\$3; }' | column -t | grep -E ^/dev/ | sort"      # View only mounted drives
alias left='ls -t -1'   # Sort By modification time
alias hgrep='history | grep'   # Find a command in your shell history (not 'gh': that shadows the GitHub CLI)
alias count='find . -type f | wc -l'
alias cpv='rsync -ah --info=progress2'      # A Copy progress bar

# Create a Python  Virtual Environment
alias ve='python3 -m venv ./venv'
alias va='source ./venv/bin/activate'

alias tcn='gio trash'          # Move to the freedesktop trash (restorable from file managers)

# Gemini CLI
alias gemini='npx @google/gemini-cli'

# Claude Desktop
alias claude-desktop='claude-desktop --no-sandbox'

