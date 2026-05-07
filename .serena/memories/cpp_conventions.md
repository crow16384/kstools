# C++ conventions for kstools

## Toolchain
- Standard: C++23 (`CXX_STD = CXX23` in `src/Makevars`)
- Compiler on dev machine: Apple clang 21 (arm64 macOS)
- `clangd` at `/usr/bin/clangd`; no `clang-tidy` installed

## clangd configuration
- `.clangd` at repo root with:
  - `-std=gnu++23`, `-DNDEBUG`, `-Isrc`
  - R include: `-I/usr/local/R/4.6.0/lib/R/include`
  - Rcpp include: `-I/Users/meguty/Library/R/arm64/4.6/library/Rcpp/include`
  - `UnusedIncludes: Strict`, `MissingIncludes: Strict`

## Source layout (under `src/`)
```
src/
  core/text.{hpp,cpp}   – string utilities (cxpt namespace)
  core/types.hpp         – XptFile, XptVariable, CellValue, NumericValue structs
  xpt/parser.{hpp,cpp}  – XPORT V5/V8/V9 parser (cxpt namespace)
  xpt/writer.{hpp,cpp}  – XPORT V5/V8 writer  (cxpt namespace)
  xpt_epoch.hpp          – SAS↔R epoch conversion + format detection (kstools namespace)
  rcpp_xpt.cpp           – Rcpp interface: .rcpp_read_xpt / .rcpp_write_xpt
  Makevars / Makevars.win
```

## Include conventions
- All relative includes use `src/` as root: `#include "core/text.hpp"`, `#include "xpt/parser.hpp"`
- `Makevars` passes `-I.` (= `-Isrc` during R build)
- All source files use `#pragma once`
- Include order: own header → std headers (alphabetical) → third-party

## Code quality rules (clangd-clean)
- C-string lookup tables inside `inline` functions: `static constexpr const char * const name[]`
- No unused `#include` — clangd `UnusedIncludes: Strict` is active
- Use `const bool`, `const auto` for immutable locals
- Avoid `std::remove(path)` for file deletion (ambiguous with `<algorithm>`); use `(void)::remove(path.c_str())`
- Constructor syntax for string variables: `std::string s(CHAR(...))` not `std::string s = std::string(CHAR(...))`
- All internal helper functions must be used or removed (no dead code in anonymous namespaces)
- `snprintf` needs `<cstdio>` explicitly; `memcmp`/`memcpy`/`memset` need `<cstring>`

## Epoch / date handling
- SAS epoch: 1960-01-01; R epoch: 1970-01-01; offset = 3653 days / 315,619,200 s
- Format detection in `xpt_epoch.hpp` → `isSasDateFormat`, `isSasDatetimeFormat`, `isSasTimeFormat`
- Conversion: `sasDateToR = sas - 3653.0`, `rDateToSas = r + 3653.0`

## Build
- Subdir sources explicitly listed in `SOURCES` variable (R doesn't auto-compile subdirs)
- `OBJECTS = $(SOURCES:.cpp=.o)`
- Clean: `find src -name '*.o' -delete`
- Rebuild: `Rscript -e 'pkgbuild::compile_dll(quiet=FALSE)'`
- After changing Rcpp exports: `Rscript -e 'Rcpp::compileAttributes()'`
