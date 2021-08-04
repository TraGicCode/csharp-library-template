# Save CD
Push-Location

$repositories = Get-ChildItem -Path .\modules\*\*
ForEach($repository in $repositories)
{
    cd $repository
    gh pr merge --delete-branch --squash
}

# Move back to root of repo
Pop-Location
