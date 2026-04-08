2026-04-08 repair:
- Activated project `kstools` at `/Users/meguty/Develop/R/kstools`.
- `.serena/project.yml` updated ignored_paths to avoid health-check false failures on non-symbol files:
  - vignettes/*.Rmd
  - tests/**
- Verified with `serena project health-check "$PWD"`: PASS.

Recovery sequence:
1) ./scripts/start-serena.sh
2) serena project health-check "$PWD"
3) activate project by name `kstools` if MCP starts with no active project.
