#!/bin/bash

# Git Smart Commit - Linux Bash version of PowerShell script
# Usage: ./git-smart-commit.sh [-m "Custom message"] [-b branch] [--force]

CustomMessage=""
Branch=""
ForceCreateBranch=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--message)
            CustomMessage="$2"
            shift 2
            ;;
        -b|--branch)
            Branch="$2"
            shift 2
            ;;
        --force)
            ForceCreateBranch=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [-m 'message'] [-b branch] [--force]"
            exit 1
            ;;
    esac
done

# Check if git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Error: Not a git repository!" >&2
    exit 1
fi

# Check for changes
status=$(git status --porcelain)
if [[ -z "$status" ]]; then
    echo -e "\e[32m[OK] No changes to commit\e[0m"
    exit 0
fi

# Get changed files for human-readable message
mapfile -t changedFiles < <(git diff --name-only)
fileCount=${#changedFiles[@]}
firstFiles=()
for ((i=0; i<${#changedFiles[@]} && i<3; i++)); do
    filename=$(basename "${changedFiles[i]}" .${changedFiles[i]##*.})
    firstFiles+=("$filename")
done
moreFiles=""
if [[ $fileCount -gt 3 ]]; then
    moreFiles=" +$((fileCount-3)) more"
fi

# Generate human-readable message
if [[ -z "$CustomMessage" ]]; then
    time=$(date +"%m-%d %H:%M")
    if [[ $fileCount -eq 1 ]]; then
        CustomMessage="Update ${firstFiles[0]} [$time]"
    elif [[ $fileCount -le 3 ]]; then
        CustomMessage="Update $(IFS=', '; echo "${firstFiles[*]}") $moreFiles [$time]"
    else
        CustomMessage="Sync $fileCount files: $(IFS=', '; echo "${firstFiles[*]}") $moreFiles [$time]"
    fi
fi

echo -e "\n\e[36m[INFO] Commit message: $CustomMessage\e[0m"
echo -e "\e[37m[INFO] Files: $(printf "%s, " "${changedFiles[@]:0:5}" | sed 's/, $//')...\e[0m"

# Branch handling
currentBranch=$(git rev-parse --abbrev-ref HEAD)
targetBranch=${Branch:-$currentBranch}

if [[ "$targetBranch" != "$currentBranch" ]] && ! git ls-remote --heads origin "$targetBranch" >/dev/null 2>&1; then
    echo -n "Branch '$targetBranch' missing. Create it? (y/N): "
    read -r create
    if [[ "$create" =~ ^[Yy] ]]; then
        git checkout -b "$targetBranch"
        echo -e "\e[32m[OK] Created branch: $targetBranch\e[0m"
    else
        echo -e "\e[31m[ABORT] Cancelled\e[0m"
        exit 1
    fi
fi

# Handle unstaged changes + clean rebase
echo -e "\e[33m[SYNC] Pulling latest changes...\e[0m"

# Check for unstaged changes
if ! git diff --quiet >/dev/null 2>&1; then
    echo -e "\e[33mWarning: Unstaged changes detected. Stashing first...\e[0m"
    git stash push -m "temp-smart-commit-stash-$(date +%H%M%S)" >/dev/null 2>&1
    stashed=true
fi

# Clean fetch + rebase
git fetch origin "$targetBranch" >/dev/null 2>&1
git rebase origin/"$targetBranch" >/dev/null 2>&1

# Restore stash if needed
if [[ -n "$stashed" ]]; then
    git stash pop >/dev/null 2>&1
    echo -e "\e[32m[RESTORE] Stash popped (your unstaged changes preserved)\e[0m"
fi

echo -e "\n\e[32m[COMMIT] Pushing to $targetBranch...\e[0m"
git add .
git commit -m "$CustomMessage"

# Handle push with force option
if git push origin "$targetBranch" 2>/dev/null; then
    echo -e "\e[32m[OK] Pushed successfully!\e[0m"
else
    echo -e "\e[31m[REJECTED] Push failed - remote ahead. Force push? (y/N)\e[0m"
    read -r force
    if [[ "$force" =~ ^[Yy] ]]; then
        echo -e "\e[33m[FORCE] Using --force-with-lease...\e[0m"
        if git push origin "$targetBranch" --force-with-lease 2>/dev/null; then
            echo -e "\e[32m[OK] Force pushed successfully!\e[0m"
        else
            echo -e "\e[31m[FAILED] Force push rejected. Run 'git status' and resolve manually.\e[0m" >&2
            exit 1
        fi
    else
        echo -e "\e[31m[ABORT] Push cancelled. Run 'git push' manually if needed.\e[0m" >&2
        exit 1
    fi
fi

echo -e "\n\e[35m[DONE] Commit: $CustomMessage\e[0m"
