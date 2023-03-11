<# Remove-Alias gc -Force
Remove-Alias gco -Force
Remove-Alias ga -Force
Remove-Alias gb -Force
Remove-Alias gba -Force
Remove-Alias gbd -Force
Remove-Alias gcp -Force
Remove-Alias gd -Force
Remove-Alias gds -Force
Remove-Alias grs -Force
Remove-Alias gst -Force
Remove-Alias gu -Force
Remove-Alias gpr -Force
Remove-Alias ff -Force
Remove-Alias grd -Force
Remove-Alias gbb -Force
Remove-Alias gl -Force
Remove-Alias gla -Force
Remove-Alias grc -Force
Remove-Alias gra -Force
Remove-Alias gcan -Force
Remove-Alias gpf -Force #>

# GIT ALIASES
function gc{git commit}
function gco{git checkout}
function ga{git add}
function gb{git branch}
function gba{git branch --all}
function gbd{git branch -D}
function gcp{git cherry-pick}
function gd{git diff -w}
function gds{git diff -w --staged}
function grs{git restore --staged}
function gst{git rev-parse --git-dir > /dev/null 2>&1 && git status || exa}
function gu{git reset --soft HEAD~1}
function gpr{git remote prune origin}
function ff{gpr && git pull --ff-only}
function grd{git fetch origin && git rebase origin/master}
function gbb{git-switchbranch}
function gl{git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(green)%an %ar %C(reset) %C(bold magenta)%d%C(reset)'}
function gla{git log --all --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(bold magenta)%d%C(reset)'}
function grc{git rebase --continue}
function gra{git rebase --abort}
function gcan{gc --amend --no-edit}
function gpf{git push --force-with-lease}

Invoke-Expression (&starship init powershell)