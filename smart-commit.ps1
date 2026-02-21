param(
    [string]$CustomMessage = "",
    [string]$Branch = "",
    [switch]$ForceCreateBranch
)

if (-not (git rev-parse --git-dir 2>$null)) { 
    Write-Error "Not a git repository!"; exit 1 
}

$status = git status --porcelain
if ($status.Count -eq 0) { 
    Write-Host "[OK] No changes to commit" -ForegroundColor Green; exit 0 
}

# Get actual file names for human-readable message
$changedFiles = git diff --name-only
$fileCount = $changedFiles.Count
$firstFiles = $changedFiles | Select-Object -First 3 | ForEach-Object { (Split-Path $_ -Leaf).Split('.')[0] }
$moreFiles = if ($fileCount -gt 3) { " +$($fileCount-3) more" } else { "" }

# Generate HUMAN-READABLE message
if (-not $CustomMessage) {
    $time = Get-Date -Format "MM-dd HH:mm"
    
    if ($fileCount -eq 1) {
        $CustomMessage = "Update $firstFiles [$time]"
    } elseif ($fileCount -le 3) {
        $CustomMessage = "Update $($firstFiles -join ', ') $moreFiles [$time]"
    } else {
        $CustomMessage = "Sync $fileCount files: $($firstFiles -join ', ') $moreFiles [$time]"
    }
}

Write-Host "`n[INFO] Commit message: $CustomMessage" -ForegroundColor Cyan
Write-Host "[INFO] Files: $($changedFiles -join ', ' | Select -First 80)..." -ForegroundColor White

# Branch handling
$currentBranch = git rev-parse --abbrev-ref HEAD
$targetBranch = if ($Branch) { $Branch } else { $currentBranch }

if ($targetBranch -ne $currentBranch -and -not (git ls-remote --heads origin $targetBranch 2>$null)) {
    $create = Read-Host "Branch '$targetBranch' missing. Create it? (y/N)"
    if ($create -match '^y') {
        git checkout -b $targetBranch
        Write-Host "[OK] Created branch: $targetBranch" -ForegroundColor Green
    } else {
        Write-Host "[ABORT] Cancelled" -ForegroundColor Red; exit 1
    }
}

# Safe pull (stash → pull → pop)
Write-Host "[SYNC] Pulling latest changes..." -ForegroundColor Yellow
git stash push -m "temp-stash-$(Get-Date -Format 'HHmmss')" -q
git pull origin $targetBranch --rebase -q
git stash pop -q

Write-Host "`n[COMMIT] Pushing to $targetBranch..." -ForegroundColor Green
git add .
git commit -m "$CustomMessage"

try {
    git push origin $targetBranch
    Write-Host "[OK] Pushed successfully!" -ForegroundColor Green
} catch {
    Write-Host "[RETRY] Force push..." -ForegroundColor Yellow
    git push origin $targetBranch --force-with-lease
}

Write-Host "`n[DONE] Commit: $CustomMessage" -ForegroundColor Magenta
