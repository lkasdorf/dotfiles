# Alias for vpn

    alias vpn1='sudo wg-quick up wgnb'
    alias vpn0='sudo wg-quick down wgnb'


# My personal notes, call TODO.md
#    alias tn='cd ~/DRIVE/SynologyDrive/notes && nvim ~/DRIVE/SynologyDrive/notes/TODO.md'
    alias todo='cd ~/Documents/notes/myNotes && nvim ~/Documents/notes/myNotes/TODO.md'

# Open the notes Directory
    alias notes='cd ~/DRIVE/SynologyDrive/notes'

    alias ..='cd ..'
    alias upgrade='sudo nala upgrade'
    alias c='clear'

    alias h='cd ~ && clear'
    alias vim='nvim'
    alias v='nvim'

# some more ls aliases
#alias ll='exa -alF --color=always --group-directories-first'
#alias la='ls -A'
#alias l='exa -l --color=always --group-directories-first'
#alias ls='exa'
#alias tree='exa --tree'

#ls
alias ls='eza -al --color=always --group-directories-first' # my preferred listing
alias la='eza -a --color=always --group-directories-first' # all files and dirs
alias ll='eza -l --color=always --group-directories-first' # long format
alias lt='eza -aT --color=always --group-directories-first' # tree listing
alias l.='eza -a | egrep "^\."'

## get rid of command not found ##
alias cd..='cd ..'

## a quick way to get out of current directory ##
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias .4='cd ../../../../'
alias .5='cd ../../../../..'

## alias for apt

alias apt='sudo apt'
alias nala='sudo nala'

## alias for updatedb

#alias updatedball='sudo updatedb && updatedb -l 0 -o $HOME/var/mlocate.db -U $HOME'

## adding flags
alias cp='cp -i'	# confirm before overwriting something
alias df='df -h'	# human-readable sizes
alias free='free -m'	# show sizes in MB
alias mv='mv -i'

## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

## get top process eating cpu
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

## git
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias status='git status'
alias tag='git tag'
alias newtag='git tag -a'

## shutdown or reboot
alias ssn='sudo shutdown now'
alias sr='sudo reboot'

# get error messages from journalctl
alias jctl="journalctl -p 3 -xb"

# termbin
alias tb="nc termbin.com 9999"

#the terminal rickroll
alias rr='curl -s -L https://raw.githubusercontent.com/keroserene/rickrollrc/master/roll.sh | bash'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Nordvpn

alias nvpn='nordvpn'

alias nvpnde='nordvpn connect Germany'
alias nvpnus='nordvpn connect United_States'
alias nvpnuk='nordvpn connect United_Kingdom'
alias nvpnp2p='nordvpn connect P2P'
alias nvpnd2='nordvpn connect Double_VPN'
alias nvpnsa='nordvpn connect South_Africa'
alias nvpntor='nordvpn connect Onion_Over_VPN'
alias nvpntr='nordvpn connect Turkey'

alias nvpnoff='nordvpn disconnect'

# Misc

alias myip='curl ipinfo.io/ip'
alias wifipass='nmcli device wifi show-password'
alias week='date +%V'
alias x='exit'

alias mv='mv -i'
alias rm='rm -i'

alias st='speedtest-cli'
alias wt='curl wttr.in'


alias config='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias comnotes='git add -A && git commit -m "notes" && git push'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias ytbest='yt-dlp -4 -o "~/YTDL/%(title)s by %(uploader)s on %(upload_date)s" -f "bv+ba/b"'
alias yt='yt-dlp -4 -o "~/YTDL/%(title)s by %(uploader)s on %(upload_date)s" -f -'

# Translate
alias tl='trans'

# bat
alias cat='bat'
