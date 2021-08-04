# Save CD
Push-Location

$repositories = Get-ChildItem -Path .\modules\*\*
ForEach($repository in $repositories)
{
    cd $repository
    gh pr diff
}

# Move back to root of repo
Pop-Location
