#!/usr/bin/env bash
# Restore the Claude Code token-saving stack. Idempotent: skips anything present.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/claude-home"
export PATH="$HOME/.local/bin:$PATH"

say() { printf '== %s\n' "$*"; }

command -v curl >/dev/null 2>&1 || { echo "ERROR: curl not found. Install it and re-run." >&2; exit 1; }
[ -d "$SRC" ] || { echo "ERROR: $SRC missing." >&2; exit 1; }

if ! command -v claude >/dev/null 2>&1; then
  say "installing claude"
  curl -fsSL https://claude.ai/install.sh | bash
  hash -r
fi
if ! command -v uv >/dev/null 2>&1; then
  say "installing uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
  hash -r
fi
for t in claude uv; do
  command -v "$t" >/dev/null 2>&1 || { echo "ERROR: '$t' still not found after install." >&2; exit 1; }
done

say "files -> ~/.claude (cp -n, never overwrite)"
mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/commands
cp -n "$SRC/CLAUDE.md" "$SRC/RTK.md" ~/.claude/
cp -rn "$SRC/agents/." ~/.claude/agents/
cp -rn "$SRC/commands/." ~/.claude/commands/
cp -rn "$SRC/skills/." ~/.claude/skills/

plugin_installed() { claude plugin list 2>/dev/null | grep -q "$1"; }
market_present()   { claude plugin marketplace list 2>/dev/null | grep -q "$1"; }

say "plugins (user scope)"
market_present caveman     || claude plugin marketplace add JuliusBrussee/caveman
plugin_installed 'caveman@caveman' || claude plugin install caveman@caveman
market_present i-have-adhd || claude plugin marketplace add ayghri/i-have-adhd
plugin_installed 'i-have-adhd@i-have-adhd' || claude plugin install i-have-adhd@i-have-adhd
market_present karpathy-skills || claude plugin marketplace add multica-ai/andrej-karpathy-skills
plugin_installed 'andrej-karpathy-skills@karpathy-skills' || claude plugin install andrej-karpathy-skills@karpathy-skills
touch ~/.claude/.i-have-adhd-always

say "rtk (oss edition)"
if ! command -v rtk >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | RTK_EDITION=oss sh
fi
if grep -q 'rtk hook claude' ~/.claude/settings.json 2>/dev/null; then
  echo "rtk hook already in settings.json"
else
  rtk init -g --auto-patch
fi

say "serena"
command -v serena >/dev/null 2>&1 || uv tool install -p 3.13 serena-agent
if claude mcp get serena >/dev/null 2>&1; then
  echo "serena MCP already registered"
else
  claude mcp add --scope user serena -- serena start-mcp-server --context claude-code --project-from-cwd
fi

say "~/.bashrc auto-restore guard"
if ! grep -q '# >>> token-stack auto-restore >>>' ~/.bashrc 2>/dev/null; then
  cat >> ~/.bashrc <<BLOCK
# >>> token-stack auto-restore >>>
if [ -x "$HERE/install.sh" ] && { [ ! -f "\$HOME/.claude/CLAUDE.md" ] || ! PATH="\$HOME/.local/bin:\$PATH" command -v rtk >/dev/null 2>&1 || ! PATH="\$HOME/.local/bin:\$PATH" command -v serena >/dev/null 2>&1; }; then
  ( "$HERE/install.sh" >> "\$HOME/.token-stack-restore.log" 2>&1 & ) >/dev/null 2>&1
fi
# <<< token-stack auto-restore <<<
BLOCK
  echo "guard added"
else
  echo "guard already present"
fi

if ! grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.bashrc 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo "PATH export added"
else
  echo "PATH export already present"
fi

say "done"
