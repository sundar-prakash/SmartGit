# SmartGit - AI-Powered Git Commit Assistant





**SmartGit** is a PowerShell script that automatically analyzes your git changes, generates intelligent semantic commit messages, and safely pushes to any branch (auto-creating if needed). Perfect for developers who hate writing commit messages!

## ✨ Features

- **AI Analysis** - Counts files/lines changed and generates semantic messages (`fix:`, `feat:`, `chore:`)
- **Safe Push** - Stashes local changes, pulls latest, reapplies, then pushes (zero conflicts)
- **Branch Magic** - Push to any branch, auto-creates if missing (with confirmation)
- **Customizable** - Override with custom messages/branches or use auto-generated
- **Visual Feedback** - Color-coded progress with change statistics

## 📦 Installation

1. **Download** `smart-commit.ps1` from [Releases](https://github.com/sundar-prakash/smartgit-commit/releases)
2. **Place anywhere** in your PATH (or run directly from project folder)
3. **Run** in any git repository: `.\smart-commit.ps1`

## 🚀 Quick Start

```powershell
# Auto-analyze & commit to current branch
.\smart-commit.ps1

# Custom message
.\smart-commit.ps1 -CustomMessage "feat: add login page"

# Push to specific branch (creates if missing)
.\smart-commit.ps1 -Branch "develop"

# Full power
.\smart-commit.ps1 -CustomMessage "fix: navbar responsive" -Branch "hotfix/ui"
```

## 🎯 Example Output

```
📊 Analysis: 3 files changed +45i/-12d
💬 Message: fix: navbar & styles (3f +45i/-12d) [02-21 18:19]

🚀 Committing & pushing to main...
✅ Pushed to main!

🎉 Complete! Commit: fix: navbar & styles (3f +45i/-12d) [02-21 18:19]
```

## 🛡️ Safe Operations

```
Your changes → STASH → git pull → POP stash → COMMIT → PUSH
```
**Never loses work** - always stashes local changes before pulling remote updates.

## ⚙️ Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `-CustomMessage` | `string` | Your commit message | Auto-generated |
| `-Branch` | `string` | Target branch name | Current branch |
| `-ForceCreateBranch` | `switch` | Auto-create branches | Prompt user |

## 🤝 Contributing

1. Fork the repo
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `.\smart-commit.ps1 -CustomMessage "feat: add amazing feature"`
4. Push & create PR!

## 📄 License

MIT License - see [LICENSE](LICENSE) © 2026

## 🙏 Thanks

Built for developers tired of boring commit messages. Star ⭐ if it saves your time!

***

```bash
# One-liner to add to your repo
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/yourusername/smartgit-commit/main/smart-commit.ps1" -OutFile "smart-commit.ps1"
```
