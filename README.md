# ⚡ Claude Code Status Line

A lightweight, dependency-free status line script for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that gives you session visibility at a glance.

## 🖥️ Example

**Windows (Git Bash):**
```
user@hostname MINGW64 D:\MyProject (main) [Opus 4.6 (1M context)] ctx:7% 5h:12% 7d:20% s:1bc51710
```

**macOS / Linux:**
```
user@hostname macOS ~/projects/myapp (main) [Sonnet 4.6] ctx:33% 5h:10% 7d:19% s:a4f2c891
```

## 🧩 Segments

| Segment | Color | Description |
|---|---|---|
| `user@hostname` | 🟢 Green | Current user and hostname |
| `MINGW64` / `macOS` / `Linux` | 🟣 Purple | Environment label (adapts per platform) |
| `D:\MyProject` | 🟡 Yellow | Current working directory |
| `(main)` | 🔵 Cyan | Git branch (only inside a git repo) |
| `[Opus 4.6 (1M context)]` | 🩶 Dimmed | Active model |
| `ctx:7%` | 🩶 Dimmed | Context window usage |
| `5h:12%` | 🩶 Dimmed | 5-hour rate limit usage |
| `7d:20%` | 🩶 Dimmed | 7-day rate limit usage |
| `s:1bc51710` | 🩶 Dimmed | Session ID (first 8 characters) |

## 🚀 Setup

### 1. Copy the script

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
```

### 2. Add to Claude Code settings

Add the following to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

If the file already exists, merge the `statusLine` key into your existing settings.

### 3. Restart Claude Code

The status line will appear at the bottom of your Claude Code interface on the next launch.

## ⚙️ How It Works

Claude Code passes a JSON payload to the status line command via stdin on each refresh. The script parses this JSON using **bash regex** (`[[ =~ ]]`) — no external tools like `jq`, `sed`, or `grep` are needed.

The JSON payload includes fields like:

```json
{
  "session_id": "1bc51710-2850-45b0-bf5c-1ebef589312e",
  "model": { "display_name": "Opus 4.6 (1M context)" },
  "workspace": { "current_dir": "D:\\Work\\Migration" },
  "context_window": { "remaining_percentage": 93 },
  "rate_limits": {
    "five_hour": { "used_percentage": 12 },
    "seven_day": { "used_percentage": 20 }
  }
}
```

## 📊 Performance

The script is optimized to minimize process spawns, which matters most on Windows where fork overhead is higher.

| Metric | Value |
|---|---|
| Typical process spawns | 2-3 (cat + git) |
| Worst-case process spawns | 7 (cat + 2 git + 2 hostname + uname + whoami) |
| Execution time (Windows) | ~95ms |
| External dependencies | None |

**Why so few processes?**

- 🔧 JSON parsing uses bash builtins (`[[ =~ ]]`) instead of `jq` / `sed` / `grep`
- 📦 Identity (`USER`, `HOSTNAME`, `MSYSTEM`) is read from environment variables, not commands
- 🎨 Color codes are stored in shell variables, not computed per segment
- 🧱 Segment strings are built inline without subshells

## 🌍 Platform Support

| Platform | Environment Label | Status |
|---|---|---|
| Windows (Git Bash) | `MINGW64` / `UCRT64` etc. | ✅ Supported |
| macOS | `macOS` | ✅ Supported |
| Linux | `Linux` | ✅ Supported |
| Docker containers | `Linux` | ✅ Supported (requires bash) |
| Cygwin | `Cygwin` | ✅ Supported |
| WSL | `Linux` | ✅ Supported |

The environment label adapts automatically. On Windows it uses `$MSYSTEM`, on other platforms it detects the OS via `uname -s`.

## ♿ Accessibility

- Respects the [`NO_COLOR`](https://no-color.org) convention — set `NO_COLOR=1` to disable all colors
- Colors are also disabled when `TERM=dumb`
- When colors are off, all segments still render as plain text

## 📝 Notes

- On startup, only user@host, environment, cwd, git branch, and model appear. The percentages and session ID show up after the first prompt.
- The status line may take a few seconds to appear on launch depending on system performance and Claude Code's startup time. This is Claude Code's initialization, not the script.
- Git branch only appears when the current directory is inside a git repository.
- Session ID is a unique identifier per Claude Code conversation. It helps distinguish between multiple concurrent sessions.
- Context percentage is rounded to the nearest integer. Use `/context` inside Claude Code for exact token counts.

## 📋 Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Bash 4+ (included with Git for Windows, macOS, and most Linux distributions)

## 📄 License

[MIT](LICENSE)
