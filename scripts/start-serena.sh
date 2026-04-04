#!/usr/bin/env sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CANONICAL_ROOT=$(realpath "$PROJECT_ROOT")
PROJECT_NAME=kstools

if ! command -v serena >/dev/null 2>&1; then
  echo "Error: 'serena' is not installed or not on PATH." >&2
  exit 1
fi

if ! command -v R >/dev/null 2>&1; then
  echo "Error: 'R' is not installed or not on PATH." >&2
  exit 1
fi

if [ ! -f "$PROJECT_ROOT/.serena/project.yml" ]; then
  serena project create "$PROJECT_ROOT" --name "$PROJECT_NAME" --language r
fi

serena project index "$PROJECT_ROOT" --name "$PROJECT_NAME" --language r
serena project health-check "$PROJECT_ROOT"

echo "Serena project indexed and health-checked. VS Code launches the MCP server via .vscode/mcp.json."
