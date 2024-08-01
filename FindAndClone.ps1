# Define the search word, organization, team, and clone directory
$searchWord = ""  # Replace with the word you want to search for
$orgOrUser = ""   # Replace with the organization or user you want to search within
$cloneDirectory = ""  # Replace with the path to the directory where you want to clone the repositories
$teamSlug = ""      # Replace with the team's slug


# Ensure the clone directory exists
if (-not (Test-Path -Path $cloneDirectory)) {
    try {
        New-Item -ItemType Directory -Path $cloneDirectory -ErrorAction Stop
    } catch {
        Write-Error "Failed to create clone directory at '$cloneDirectory'. Error: $_"
        exit 1
    }
}

Start-Sleep -Seconds 5
# Get repositories the specified team has access to
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
            gh repo clone $repo "$cloneDirectory\$($repo -replace '/','-')"
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
