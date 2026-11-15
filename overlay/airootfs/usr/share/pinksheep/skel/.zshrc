# ╭──────────────────────────────────────────────────────────╮
# │  Zsh PinkSheep                                            │
# │  Tes ajouts perso : ~/.zshrc.perso (jamais écrasé)        │
# ╰──────────────────────────────────────────────────────────╯

# Historique
HISTFILE=~/.zsh_history
HISTSIZE=20000
SAVEHIST=20000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS
setopt AUTO_CD INTERACTIVE_COMMENTS

# Complétion (Tab) avec menu et sans tenir compte des majuscules
autoload -Uz compinit && compinit -d ~/.cache/zcompdump
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Touches : Ctrl+flèches pour sauter les mots, Suppr, Début/Fin
bindkey -e
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~'   delete-char
bindkey '^[[H'    beginning-of-line
bindkey '^[[F'    end-of-line

# Plugins : suggestions grisées (→ pour accepter) et coloration des commandes
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Ctrl+R : recherche floue dans l'historique, Ctrl+T : chercher un fichier
command -v fzf >/dev/null && source <(fzf --zsh)

# « z dossier » pour sauter vers un dossier déjà visité
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Raccourcis de commandes
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --group-directories-first --git'
    alias la='eza -la --icons --group-directories-first --git'
    alias arbre='eza --tree --icons --level=2'
fi
command -v bat >/dev/null && alias cat='bat --paging=never --style=plain'
alias maj='sudo pacman -Syu'              # mettre à jour tout le système
alias installer='sudo pacman -S'
alias chercher='pacman -Ss'
alias v='nvim'
alias musique='rmpc'
alias yt='pinksheep-yt'

# « y » : Yazi qui te laisse dans le dossier où tu l'as quitté
y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

export EDITOR=nvim
export VISUAL=nvim
export PATH="$HOME/.local/bin:$PATH"

# Invite de commande : Starship dans le terminal graphique,
# invite simple dans la console texte (qui n'affiche pas les icônes)
if [[ "$TERM" == "linux" ]]; then
    PROMPT='%F{magenta}%n@%m%f %F{cyan}%~%f %# '
elif command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

# Petit résumé du système à l'ouverture du terminal
[[ -o interactive && -z "$PINKSHEEP_PAS_DE_FASTFETCH" && "$TERM" == "xterm-kitty" ]] && command -v fastfetch >/dev/null && fastfetch

[[ -r ~/.zshrc.perso ]] && source ~/.zshrc.perso
