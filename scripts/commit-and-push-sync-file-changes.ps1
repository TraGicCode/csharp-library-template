# Save CD
Push-Location

$repositories = Get-ChildItem -Path .\modules\*\*
ForEach($repository in $repositories)
{
    cd $repository
    git add .sync.yml
    git commit -m "Added/Updated .sync.yml outside of msync"
}

# Move back to root of repo
Pop-Location
msync update --pr --amend --force
