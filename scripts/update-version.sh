#!/usr/bin/env bash
# Update the package version in EVERY place it is stamped (kstools).
# Adapted from norn's scripts/update-version.sh, itself adapted from Satis
# (owner ruling 2026-10-31 / 2026-11-02: package versions are changed ONLY
# through this repo script, never by hand-sed).
#
# Usage:
#   ./scripts/update-version.sh <new-version>   # bump + stamp all carriers
#   ./scripts/update-version.sh                 # idempotent re-stamp at the
#                                               # version already in DESCRIPTION
# Accepted versions: X.Y.Z (release) and X.Y.Z.NNNN-style dev suffixes.
set -e

cd "$(dirname "$0")/.."

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

if [[ ! -f DESCRIPTION ]]; then
    echo -e "${RED}Error: run from the package root (DESCRIPTION not found).${NC}" >&2
    exit 1
fi

OLD_VERSION=$(grep "^Version:" DESCRIPTION | sed 's/Version: *//' | tr -d '[:space:]')

NEW_VERSION="${1:-}"
if [[ -z "$NEW_VERSION" ]]; then
    NEW_VERSION="$OLD_VERSION"   # idempotent re-stamp mode
fi
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.]+)?$ ]]; then
    echo -e "${RED}Error: bad version '$NEW_VERSION' (expected X.Y.Z or X.Y.Z.NNNN).${NC}" >&2
    exit 1
fi
TODAY=$(date +%F)

# --- 1. DESCRIPTION (single source of truth) ---------------------------------
if [[ "$NEW_VERSION" != "$OLD_VERSION" ]]; then
    sed -i '' "s/^Version: .*/Version: $NEW_VERSION/" DESCRIPTION
    echo -e "${GREEN}DESCRIPTION: $OLD_VERSION -> $NEW_VERSION${NC}"
else
    echo -e "${GREEN}DESCRIPTION already at $NEW_VERSION (re-stamp mode)${NC}"
fi

# --- 2. NEWS.md: promote/preserve the top section -----------------------------
# Rules inherited from Satis/norn: heading must read "# kstools <version>"; a
# blank line must separate previous content from a NEW heading (pkgdown
# silently swallows a heading glued to a paragraph — whole releases vanish
# from the changelog); a "<dev>" section gets promoted.
if [[ -f NEWS.md ]]; then
    if grep -q "^# kstools <dev>" NEWS.md; then
        perl -pi -e "s/^# kstools <dev>/# kstools $NEW_VERSION/" NEWS.md
        echo -e "${GREEN}NEWS.md: <dev> section promoted to '# kstools $NEW_VERSION'${NC}"
    elif ! grep -q "^# kstools $NEW_VERSION" NEWS.md; then
        TMP=$(mktemp)
        { echo "# kstools $NEW_VERSION"; echo; echo "- Development milestone."; echo;
          cat NEWS.md; } > "$TMP"
        mv "$TMP" NEWS.md
        echo -e "${YELLOW}NEWS.md: prepended stub section for $NEW_VERSION (EDIT the bullets!)${NC}"
    else
        echo -e "${GREEN}NEWS.md already carries '# kstools $NEW_VERSION'${NC}"
    fi
else
    printf '# kstools %s\n\n- Development milestone.\n' "$NEW_VERSION" > NEWS.md
    echo -e "${YELLOW}NEWS.md created with a stub section (EDIT the bullets!)${NC}"
fi

# --- 3. README carriers -------------------------------------------------------
# 3a. version badge (owned by scripts/update_readme_version.R, marker block).
if [[ -x scripts/update_readme_version.R || -f scripts/update_readme_version.R ]]; then
    Rscript scripts/update_readme_version.R || true
fi
# 3b. plain header stamp (only if that line style exists).
if grep -q "^> \*\*Version:\*\*" README.md 2>/dev/null; then
    perl -pi -e "s/^> \\*\\*Version:\\*\\*.*\$/> **Version:** $NEW_VERSION/" README.md
    echo -e "${GREEN}README.md header stamped to $NEW_VERSION${NC}"
fi

# --- 4. audit: stale old-version references anywhere else ---------------------
# Final grep for the PREVIOUS version: every surviving hit must be
# legitimately historical (changelog section titles). Fail loudly otherwise.
if [[ "$NEW_VERSION" != "$OLD_VERSION" ]]; then
    HITS=$(grep -rIn --exclude-dir=.git --exclude-dir=docs --exclude-dir=renv \
               --exclude-dir=*.Rcheck "$OLD_VERSION" . 2>/dev/null || true)
    # NEWS.md history sections legitimately keep old version numbers
    HITS=$(echo "$HITS" | grep -v '^NEWS\.md:' || true)
    if [[ -n "$HITS" ]]; then
        echo -e "${YELLOW}Stale references to $OLD_VERSION outside NEWS.md — REVIEW:${NC}"
        echo "$HITS"
        echo -e "${RED}Aborting: version is NOT fully synced. Fix carriers, re-run.${NC}" >&2
        exit 1
    fi
    echo -e "${GREEN}Audit clean: no stale '$OLD_VERSION' carriers outside NEWS history.${NC}"
fi

echo -e "${GREEN}Version sync done: $NEW_VERSION${NC}"
