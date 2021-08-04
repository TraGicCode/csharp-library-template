# Save CD
Push-Location

$repositories = Get-ChildItem -Path .\modules\*\*
ForEach($repository in $repositories)
{
    cd $repository
    gh pr status
}

# Move back to root of repo
Pop-Location
