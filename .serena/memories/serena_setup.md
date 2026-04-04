# Serena Setup

- Project name: `kstools`
- Primary language: `r`
- Canonical project root resolves to `/tank/storage/Develop/R/kstools`
- Repo config is stored in `.serena/project.yml`
- For this repo, `serena project index . --name kstools --language r` succeeds and indexes the R sources
- `serena project health-check "$PWD"` passes and confirms the R `languageserver` is working
- `serena project index` can auto-create `.serena/project.yml`, so `project create` is optional for an existing repo
- Serena activation supports either a registered project name or a project path; if path aliasing causes trouble, use `kstools` or the canonical `/tank/storage/...` path
- Onboarding is memory-driven; if no Serena memories exist for a project, Serena treats onboarding as not yet performed
- This VS Code session showed a mismatch where the Serena CLI recognized the project but the MCP project list stayed empty until client/server restart
