# CLAUDE.md

This repository is configured to use Serena for semantic code navigation and edits.

## Startup Workflow

The Serena MCP server is launched automatically by VS Code via `.vscode/mcp.json`.  
To re-index the project or run a health-check, run the helper script (it no longer starts the MCP server):

```sh
./scripts/start-serena.sh
```

This script does:

- creates `.serena/project.yml` if it is missing
- runs `serena project index . --name kstools --language r`
- runs `serena project health-check "$PWD"`

VS Code automatically spawns the MCP server via `.vscode/mcp.json` (server name `oraios-serena`).

## Use Serena First

When working in this repo, prefer Serena tools over reading entire files.

- Start with `get_symbols_overview` or `find_symbol`.
- Read only the symbol bodies you actually need.
- Use `find_referencing_symbols` before renaming or changing exported behavior.
- Prefer symbolic edits such as `replace_symbol_body`, `insert_after_symbol`, and `insert_before_symbol` when they fit the task.

## Project Setup

- Serena project name: `kstools`
- Serena config: `.serena/project.yml`
- Primary language: `r`

This repo has already been validated with:

```sh
serena project index . --name kstools --language r
serena project health-check "$PWD"
```

The health check passed with the R language server.

## Bootstrap Commands

If Serena is not active for this repo yet, run these commands from the repo root:

```sh
serena project create . --name kstools --language r
serena project index . --name kstools --language r
serena project health-check "$PWD"
```

## Activation Notes

- The canonical path for this workspace resolves to `/tank/storage/Develop/R/kstools`.
- If activation by `/home/meguty/Develop/R/kstools` fails, activate by project name `kstools` or by the canonical path.
- If the Serena CLI works but the MCP client still shows no known projects, restart the Serena MCP server or the client session and activate again.

## Local Artifacts

Keep `.serena/project.yml` in the repo. Treat these as local runtime files:

- `.serena/project.local.yml`
- `.serena/cache/`
- `.serena/logs/`

## R Requirement

Serena's R support depends on the R `languageserver` package being available.
