param (
    [string]$searchWord,
    [string]$orgOrUser,
    [string]$cloneDirectory,
    [string]$teamSlug
)

# Check if all required parameters are provided
if (-not $searchWord -or -not $orgOrUser -or -not $cloneDirectory -or -not $teamSlug) {
    Write-Error "Missing arguments. Usage: script.ps1 -searchWord <Word> -orgOrUser <Organization/User> -cloneDirectory <Directory> -teamSlug <TeamSlug>"
    exit 1
}

# Ensure the clone directory exists
if (-not (Test-Path -Path $cloneDirectory)) {
    try {
        New-Item -ItemType Directory -Path $cloneDirectory -ErrorAction Stop
    } catch {
        Write-Error "Failed to create clone directory at '$cloneDirectory'. Error: $_"
        exit 1
    }
}


# Get repositories the specified team has access to
Start-Sleep -Seconds 5
$repos = gh api --paginate -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /orgs/$orgOrUser/teams/$teamSlug/repos --jq '.[]|.full_name'

foreach ($repo in $repos) {
    try {
        Write-Output "Waiting to search $repo..."
        Start-Sleep -Seconds 5
        # Search the code for the specified word in the current repository
        $results = gh search code --repo $repo $searchWord --limit 1 --json repository | ConvertFrom-Json
        
        if ($results.repository) {
            Write-Output "Waiting to clone $repo..."
            Start-Sleep -Seconds 5
            # If results are found, clone the repository
            Write-Output "Cloning repository $repo..."
            gh repo clone $repo "$cloneDirectory\$($repo -replace '/', '-')"
            Write-Output "Cloned $repo cooling down..."
        } else {
            Write-Output "Nothing found cooling down..."
        }
        Start-Sleep -Seconds 5
    } catch {
        Write-Error "Failed to clone repository '$repo'. Error: $_"
    }
}

Write-Output "Repositories that contain the word '$searchWord' have been cloned to '$cloneDirectory'."
