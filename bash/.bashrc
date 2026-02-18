# Linux: ~/.bashrc
# .bashrc

eval "$(starship init bash)"
source <(starship completions bash)

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

export GH_TOKEN=
export FONTAWESOME_TOKEN=
export FIGMA_API_KEY=
export LINEAR_API_KEY=
export CONTEXT7_API_KEY=

export ENCORE_INSTALL="$HOME/.encore"
export PATH="$ENCORE_INSTALL/bin:$PATH"

# ALIASES
alias cls='clear'
alias cd..='cd ..'
# GIT LIASES
alias ff='gpr && git pull --ff-only'
alias ga='git add'
alias gb='git branch'
alias gba='git branch --all'
alias gbb='git-switchbranch'
alias gbd='git branch -D'
alias gc='git commit'
alias gcm='git commit -m'
alias gcmnv='git commit --no-verify -m'
alias gca='git commit -a'
alias gcan='git commit --amend --no-edit'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff -w'
alias gds='git diff -w --staged'
alias gl='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(green)%an %ar %C(reset) %C(bold magenta)%d%C(reset)"'
alias gla='git log --all --graph --format=format:"%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(bold magenta)%d%C(reset)"'
alias gm='git merge'
alias gpl='git pull'
alias gp='git push'
alias gpnv='git push --no-verify'
alias gpf='git push --force-with-lease'
alias gpr='git remote prune origin'
alias gr='git rebase'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grd='git fetch origin && git rebase origin/master'
alias grs='git restore --staged'
alias gst='git rev-parse --git-dir > /dev/null 2>&1 && git status || exa'
alias gu='git reset --soft HEAD~1'
# OTHER
alias lg='lazygit'
alias ai-usage='bunx tokscale@latest' # security concerns

# Fish shell alias - use 'fish' or 'tofish' to start fish shell
if command -v fish &> /dev/null
then
    alias tofish='exec fish'
fi