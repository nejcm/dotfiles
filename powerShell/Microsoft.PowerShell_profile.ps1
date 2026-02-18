# GIT ALIASES
function ff   {gpr && git pull --ff-only}
function ga   {git add $args}
function gb   {git branch $args}
function gba  {git branch --all $args}
function gbb  {git-switchbranch $args}
function gbd  {git branch -D $args}
function gc   {git commit $args}
function gcm  {git commit -m $args}
function gcmnv {git commit -m $args --no-verify}
function gca  {git commit -a $args}
function gcan {gc --amend --no-edit $args}
function gco  {git checkout $args}
function gcp  {git cherry-pick $args}
function gd   {git diff -w $args}
function gds  {git diff -w --staged $args}
function gl   {git log --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(green)%an %ar %C(reset) %C(bold magenta)%d%C(reset)'}
function gla  {git log --all --graph --format=format:'%C(bold blue)%h%C(reset) - %C(white)%s%C(reset) %C(bold magenta)%d%C(reset)'}
function gpl  {git pull $args}
function gp   {git push $args}
function gpnv {git push --no-verify $args}
function gpf  {git push --force-with-lease $args}
function gpr  {git remote prune origin}
function gra  {git rebase --abort $args}
function grc  {git rebase --continue $args}
function grd  {git fetch origin && git rebase origin/master}
function grs  {git restore --staged $args}
function gst  {git rev-parse --git-dir > /dev/null 2>&1 && git status || exa $args}
function gu   {git reset --soft HEAD~1}

function cua  {choco upgrade all -y}
function ups  {winget install --id Microsoft.PowerShell --source winget}

function ff-all {& "C:\Scripts\ff-all.ps1" @Args}

Remove-Alias gal -Force
Remove-Alias gc -Force
Remove-Alias gcm -Force
Remove-Alias gi -Force
Remove-Alias gl -Force
Remove-Alias gm -Force
Remove-Alias gmo -Force
Remove-Alias gp -Force
Remove-Alias gps -Force
Remove-Alias gpv -Force
Remove-Alias gu -Force
Remove-Alias gv -Force

Invoke-Expression (&starship init powershell)