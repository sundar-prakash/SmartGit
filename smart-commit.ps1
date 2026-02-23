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

# FIXED SYNC: Handle unstaged changes + clean rebase
Write-Host "[SYNC] Pulling latest changes..." -ForegroundColor Yellow

# Check for unstaged changes before rebase
$unstaged = git diff --quiet 2>$null; $unstagedExit = $LASTEXITCODE
if (-not $unstagedExit) {
    Write-Warning "Unstaged changes detected. Stashing first..."
    git stash push -m "temp-smart-commit-stash-$(Get-Date -Format 'HHmmss')" -q
    $stashed = $true
}

# Clean fetch + rebase
git fetch origin $targetBranch -q
git rebase origin/$targetBranch -q

# Restore stash if needed
if ($stashed) {
    git stash pop -q
    Write-Host "[RESTORE] Stash popped (your unstaged changes preserved)" -ForegroundColor Green
}

Write-Host "`n[COMMIT] Pushing to $targetBranch..." -ForegroundColor Green
git add .
git commit -m "$CustomMessage"

# FIXED PUSH: Ask permission before force
$pushResult = git push origin $targetBranch 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[REJECTED] Push failed - remote ahead. Force push? (y/N)" -ForegroundColor Red
    $force = Read-Host
    if ($force -match '^y') {
        Write-Host "[FORCE] Using --force-with-lease..." -ForegroundColor Yellow
        git push origin $targetBranch --force-with-lease 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[FAILED] Force push rejected. Run 'git status' and resolve manually."
            exit 1
        }
        Write-Host "[OK] Force pushed successfully!" -ForegroundColor Green
    } else {
        Write-Error "[ABORT] Push cancelled. Run 'git push' manually if needed."
        exit 1
    }
} else {
    Write-Host "[OK] Pushed successfully!" -ForegroundColor Green
}

Write-Host "`n[DONE] Commit: $CustomMessage" -ForegroundColor Magenta
