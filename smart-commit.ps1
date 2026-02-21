param(
    [string]$CustomMessage = "",
    [string]$Branch = "",
    [switch]$ForceCreateBranch
)

# Check git
if (-not (git rev-parse --git-dir 2>$null)) { 
    Write-Error "Not a git repository!"; exit 1 
}

# Get changes analysis
$status = git status --porcelain
if ($status.Count -eq 0) { 
    Write-Host "✅ No changes to commit" -ForegroundColor Green; exit 0 
}

$stat = git diff --stat
$files = (git diff --name-only | Measure-Object).Count
$lines = ($stat | Select-String '\||changed' | ForEach-Object { 
    if ($_ -match '(\d+) insertions?\(\+\), (\d+) deletions?\(-\)') { 
        "+$($matches[1])i/-$($matches[2])d" 
    }
})

# Auto-generate message if none provided
if (-not $CustomMessage) {
    $time = Get-Date -Format "MM-dd HH:mm"
    $type = if ($files -le 2) { "fix" } elseif ($files -gt 10) { "feat" } else { "chore" }
    $CustomMessage = "$type: $($files)f $lines [$time]"
}

Write-Host "`n📊 Analysis: $files files changed $lines`n💬 Message: $CustomMessage" -ForegroundColor Cyan

# Branch handling
$currentBranch = git rev-parse --abbrev-ref HEAD
$targetBranch = if ($Branch) { $Branch } else { $currentBranch }

# Check if branch exists
if ($targetBranch -ne $currentBranch -and -not (git ls-remote --heads origin $targetBranch 2>$null)) {
    $create = Read-Host "Branch '$targetBranch' doesn't exist on origin. Create it? (y/N)"
    if ($create -match '^y') {
        git checkout -b $targetBranch
        Write-Host "✅ Created local branch: $targetBranch" -ForegroundColor Green
    } else {
        Write-Host "❌ Aborted" -ForegroundColor Red; exit 1
    }
}

# Safe pull (stash local changes if any, reapply after)
git add .
git stash push -m "auto-stash-$(Get-Date -Format 'HHmmss')" -q
git pull origin $targetBranch --rebase -q
git stash pop -q

Write-Host "`n🚀 Committing & pushing to $targetBranch..." -ForegroundColor Green
git add .
git commit -m "$CustomMessage"

# Push
try {
    git push origin $targetBranch
    Write-Host "✅ Pushed to $targetBranch!" -ForegroundColor Green
} catch {
    Write-Host "🔄 Push failed, retrying with force..." -ForegroundColor Yellow
    git push origin $targetBranch --force-with-lease
}

Write-Host "`n🎉 Complete! Commit: $CustomMessage" -ForegroundColor Magenta
