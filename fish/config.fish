if status is-interactive
    # Commands to run in interactive sessions can go here
end

starship init fish | source

export GH_TOKEN=
export FONTAWESOME_TOKEN=

# ALIASES
alias cls='clear'
# GIT LIASES
alias ff='gpr && git pull --ff-only'
alias ga='git add'
alias gb='git branch'
alias gba='git branch --all'
alias gbb='git-switchbranch'
alias gbd='git branch -D'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit -a'
alias gcan='git commit --amend --no-edit'
alias gco='git checkout'
alias gcp='git cherry-pick'
alias gd='git diff -w'
alias gds='git diff -w --staged'
alias gl='git log --graph --format=format:"%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(green)%an %ar %C(reset) %C(bold magenta)%d%C(reset)"'
alias gla='git log --all --graph --format=format:"%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(bold magenta)%d%C(reset)"'
alias gpl='git pull'
alias gp='git push'
alias gpnv='git push --no-verify'
alias gpf='git push --force-with-lease'
alias gpr='git remote prune origin'
alias gra='git rebase --abort'
alias grc='git rebase --continue'
alias grd='git fetch origin && git rebase origin/master'
alias grs='git restore --staged'
alias gst='git rev-parse --git-dir > /dev/null 2>&1 && git status || exa'
alias gu='git reset --soft HEAD~1'
