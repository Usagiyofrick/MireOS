# Sungan fish aliases

alias c='clear'
alias cat='batcat'

alias ll='ls -lah'
alias la='ls -A'
alias l='ls -CF'

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'

alias ..='cd ..'
alias ...='cd ../..'

alias v='micro'
alias e='micro'

alias ports='ss -tulpn'
alias ipbr='ip -br addr'
alias routes='ip route'

alias j='journalctl'
alias jc='journalctl -xe'

alias dfh='df -h'
alias duh='du -h'
alias freeh='free -h'

alias update='sudo apt update && sudo apt upgrade'
alias ai='sudo apt install'
alias search='apt search'

alias reload='hyprctl reload'
alias hclients='hyprctl clients'
alias hmon='hyprctl monitors'
alias hws='hyprctl workspaces'
