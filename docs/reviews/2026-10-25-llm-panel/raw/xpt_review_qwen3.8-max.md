<!-- model=qwen3.8-max attempt=2 thinking=False elapsed=85s usage={"prompt_tokens": 22801, "total_tokens": 27233, "completion_tokens": 4432, "prompt_tokens_details": {"cached_tokens": 0, "text_tokens": 22801}} -->
## Findings

[SEV: Critical] [ID: X001] Out-of-bounds read in decodeNumericChunk due to missing bounds check
- Location: src/rcpp_xpt.cpp:53-55
```cpp
    for (std::size_t r = rowBegin; r < rowEnd; ++r) {
        const std::uint8_t *p = base + r * rowLen + off;
        double v = 0.0;
```
- Failure scenario: A hostile or malformed XPT file specifies a variable `byteOffset` + `storageWidth` that exceeds the declared `rowLen`, or `rowLen` is smaller than expected. The pointer `p` will point beyond the current row's boundary into adjacent memory or past the end of the mmap'd region. `decodeNumericFast` then reads up to 8 bytes from `p`, causing an out-of-bounds read that can crash the R session or leak memory contents into numeric values.
- Fix: Before the loop, validate that `off + width <= rowLen`. If not, throw `std::runtime_error`. Additionally, validate that `(nrow - 1) * rowLen + off + width <= mf.size() - fileBaseOffset` before threading begins.

[SEV: Critical] [ID: X002] Arithmetic overflow in row pointer computation with hostile nrow/rowLen
- Location: src/rcpp_xpt.cpp:97-98
```cpp
        const std::uint8_t *base = mf.data() + fileBaseOffset;
...
            const std::size_t rowsPerThread = (nrow + actualThreads - 1) / actualThreads;
```
and src/rcpp_xpt.cpp:54:
```cpp
        const std::uint8_t *p = base + r * rowLen + off;
```
- Failure scenario: The parser computes `rowCount = totalBytes / rowLen` but does not verify that `rowCount * rowLen` fits within the mapped file size when used as a byte offset multiplier in the reader. With a crafted file where `rowLen` is small (e.g., 1) and the data section is large, `nrow` can be enormous. While `rowCount` itself won't exceed `totalBytes`, if `fileBaseOffset + nrow * rowLen` overflows `std::size_t` (on 32-bit platforms) or exceeds `mf.size()`, the thread worker computes `base + r * rowLen + off` pointing outside the mmap region. On 64-bit this is less likely to wrap but still reads unmapped pages if `dataEnd` was not strictly enforced against `mf.size()`.
- Fix: In `parseSchema`, assert `schema.dataOffset + schema.rowCount * schema.rowLen <= size`. In `buildColumns`, assert `fileBaseOffset + nrow * rowLen <= mf.size()` before launching threads.

[SEV: Critical] [ID: X003] IBM float encoder silently writes zero for NaN, Infinity, and -0.0
- Location: src/xpt/writer.hpp:143-146
```cpp
    if (v == 0.0 || !(v == v) || v == std::numeric_limits<double>::infinity() ||
        v == -std::numeric_limits<double>::infinity()) {
        return;
    }
```
- Failure scenario: When writing a column containing `NaN` or `Inf` (which can arise from R computations), the encoder returns immediately after zeroing the output buffer. The written XPT file contains `0x0000000000000000` (IEEE zero) instead of the SAS missing value indicator `0x2E` followed by zeros. Upon round-trip reading, these values are decoded as `0.0` rather than `NA_real_`, silently corrupting clinical trial data. Furthermore, `-0.0` matches `v == 0.0` and is also written as all-zero bytes, losing the sign bit.
- Fix: Handle `NaN` and `Inf` by explicitly writing the SAS missing byte pattern (`out[0] = 0x2E; return;`). Handle `-0.0` separately if IEEE negative zero must be preserved, or document that it maps to positive zero.

[SEV: Critical] [ID: X004] UTF-8 byte length used as SAS character storage width causes truncation/corruption
- Location: src/rcpp_xpt.cpp:310-315
```cpp
                    SEXP s = STRING_ELT(col, r);
                    if (s != NA_STRING) {
                        std::size_t L = std::strlen(CHAR(s));
                        if (L > w) w = static_cast<std::uint16_t>(std::min<std::size_t>(L, 32767));
                    }
```
and src/rcpp_xpt.cpp:378-380:
```cpp
                    const char *cstr = CHAR(s);
                    std::size_t L = std::strlen(cstr);
                    std::size_t n = std::min<std::size_t>(L, var.storageWidth);
```
- Failure scenario: SDTM datasets frequently contain UTF-8 strings (e.g., non-ASCII adverse event terms). `std::strlen` returns the byte count, which correctly sizes the storage width. However, `storageWidth` is stored as `std::uint16_t` capped at 32767. If a UTF-8 string exceeds 32767 bytes, it is silently truncated. More critically, during write, `memcpy(slot, cstr, n)` copies `n` bytes, but if the string was previously truncated or if `var.storageWidth` was computed from a shorter string, multi-byte UTF-8 characters at the boundary are split, producing invalid UTF-8 sequences that corrupt downstream CDISC validation.
- Fix: Validate that no UTF-8 character is split at the `storageWidth` boundary. If `L > 32767`, raise an R error rather than silently truncating. Consider using `Rf_length(STRING_ELT(...))` or explicit byte-length checks that respect UTF-8 boundaries.

[SEV: High] [ID: X005] Integer overflow in rowLen accumulation allows bypassing XPT v5 constraints
- Location: src/xpt/parser.cpp:332-335
```cpp
    std::size_t rowLen = 0;
    for (auto &v : schema.variables) {
        v.byteOffset = rowLen;
        rowLen += v.storageWidth;
    }
```
- Failure scenario: A malicious file declares 65535 variables each with `storageWidth = 32767`. The sum `rowLen` exceeds 2 GB. On systems where `std::size_t` is 64-bit this doesn't wrap, but `rowLen` becomes astronomically large while `totalBytes / rowLen` yields `rowCount = 0`, masking the issue. However, if `varCount` is moderate (e.g., 2000 vars × 32767 = ~65MB rowLen) and the file is truncated, subsequent `base + r * rowLen + off` calculations in the reader may point far beyond the mmap. Additionally, XPT v5 has an 800-byte record constraint; no validation exists that `rowLen` conforms to transport format limits.
- Fix: Add overflow checking to `rowLen += v.storageWidth` (e.g., `if (rowLen > SIZE_MAX - v.storageWidth) error`). Enforce XPT v5 maximum row length constraints or at least cap `rowLen` against remaining file size.

[SEV: High] [ID: X006] Uninitialized row buffer leaks stale data for NA strings and factors
- Location: src/rcpp_xpt.cpp:370-374 and 385-388
```cpp
            } else if (colTypes[i] == 2) {
                SEXP s = STRING_ELT(colSexps[i], r);
                if (s == NA_STRING) {
                    
                } else {
```
```cpp
            } else {  
                int idx = INTEGER(colSexps[i])[r];
                if (idx == NA_INTEGER) {
                    
                } else {
```
- Failure scenario: When writing string or factor columns, `rowBuf` is initialized to `0x20` (spaces) by `commitRow`'s memset. However, if a previous row wrote a long string into a slot and the current row has `NA_STRING` or `NA_INTEGER` for that column, the empty `if` branch skips writing entirely. The buffer retains the space-filled state correctly only because `commitRow` memsets the entire row to `0x20`. But if `rowLen_` is computed incorrectly or if partial writes occur, stale data from prior operations could persist. More importantly, for NA values the XPT spec requires blank-padded strings, which happens to work here, but the intent is undocumented and fragile—if `commitRow`'s memset is ever removed or changed, NAs will silently contain garbage bytes from previous rows.
- Fix: Explicitly `memset(slot, 0x20, var.storageWidth)` in the NA branches rather than relying on implicit behavior from `commitRow`.

[SEV: High] [ID: X007] Trailing blank row heuristic silently discards valid all-space observations
- Location: src/xpt/parser.cpp:260-268
```cpp
    schema.trailingBlankRows = countTrailingBlankRows(data, schema.dataOffset, schema.dataEnd, rowLen);
...
        schema.rowCount = fullRows - schema.trailingBlankRows;
        schema.dataEnd = schema.dataOffset + schema.rowCount * rowLen;
```
- Failure scenario: XPT files pad the final 80-byte record with spaces. The parser counts trailing rows consisting entirely of `0x20` bytes and subtracts them from `rowCount`. If a legitimate clinical observation has all character fields blank-padded and all numeric fields stored as SAS missing (`.` = `0x2E`, not `0x20`), it won't match. However, if numeric missing values are encoded as all-zero bytes (which some producers do, and which `decodeNumericFast` interprets as `0.0`), or if a row genuinely consists of all spaces (e.g., a placeholder row), it will be silently deleted from the returned data frame. This violates the requirement to never silently return wrong values.
- Fix: Only strip padding bytes up to the next 80-byte record boundary, not entire rows. Compute expected data bytes from the OBS header if available, or limit blank-row stripping to at most `(80 - (dataOffset % 80)) % 80` bytes.

[SEV: Medium] [ID: X008] PROTECT/UNPROTECT gap risks GC corruption during column allocation
- Location: src/rcpp_xpt.cpp:107-111
```cpp
    for (std::size_t i : numIdx) {
        SEXP s = PROTECT(Rf_allocVector(REALSXP, static_cast<R_xlen_t>(nrow)));
        numericColSexps[i] = s;
        cols[static_cast<R_xlen_t>(i)] = s;
        UNPROTECT(1);  
    }
```
- Failure scenario: After `UNPROTECT(1)`, the newly allocated REALSXP `s` is stored in `numericColSexps[i]` (a `std::vector<SEXP>`) and `cols` (an Rcpp `List`). Rcpp Lists are protected, so `cols[i] = s` should shield `s` from garbage collection. However, if `cols[static_cast<R_xlen_t>(i)] = s` triggers any R allocation internally (e.g., bounds checking, coercion) before the assignment completes, `s` is unprotected and could be collected. In a multi-million-row clinical dataset under memory pressure, this leads to use-after-free and silent data corruption or segfaults.
- Fix: Accumulate all allocations under a single PROTECT stack or use `Rcpp::Shield<SEXP>` / defer UNPROTECT until after the loop completes.

[SEV: Medium] [ID: X009] Row names integer overflow for datasets exceeding INT_MAX rows
- Location: src/rcpp_xpt.cpp:231
```cpp
    cols.attr("row.names") = IntegerVector::create(NA_INTEGER, -static_cast<int>(nrow));
```
- Failure scenario: If `nrow` exceeds `INT_MAX` (2,147,483,647), `static_cast<int>(nrow)` invokes undefined behavior (signed integer overflow). Even approaching this limit, the compact row-names representation `-nrow` requires `nrow` to fit in a signed 32-bit int. While unlikely in typical SDTM submissions, adversarial or pooled datasets could trigger this, resulting in corrupted row names or R-level crashes.
- Fix: Check `if (nrow > INT_MAX)` and fall back to the explicit `IntegerVector` row names representation, or raise an error since R data frames cannot exceed `INT_MAX` rows with standard indexing.

[SEV: Medium] [ID: X010] POSIXct class set without tzone attribute consistency check
- Location: src/rcpp_xpt.cpp:207-210
```cpp
                CharacterVector klass = CharacterVector::create("POSIXct", "POSIXt");
                Rf_setAttrib(col, R_ClassSymbol, klass);
                Rf_setAttrib(col, Rf_install("tzone"), Rf_mkString("UTC"));
```
- Failure scenario: The code unconditionally sets `tzone` to `"UTC"` for datetime columns. If the input data frame already had a different timezone attribute (e.g., from a prior conversion), it is silently overwritten. For CDISC SDTM, datetimes should be UTC, but if a user passes a POSIXct column with local time values expecting them to be preserved, the written XPT will contain shifted times. The epoch conversion `sasDatetimeToR` uses a fixed offset (`kSasRDatetimeOffset = 315619200.0`) which assumes UTC; DST transitions in local time would produce incorrect SAS datetime values on write.
- Fix: Document the UTC assumption clearly. Optionally warn if an existing `tzone` attribute differs from `"UTC"` before conversion.

[SEV: Low] [ID: X011] Duplicate variable names silently accepted
- Location: src/rcpp_xpt.cpp:101-103
```cpp
    for (std::size_t i = 0; i < ncol; ++i) {
        names[static_cast<R_xlen_t>(i)] = schema.variables[i].name;
```
- Failure scenario: XPT v5/v8 NAMESTR records do not enforce unique variable names. If a partner sends a file with duplicate column names, the parser creates an R data frame with duplicate names. R permits this but many downstream SDTM validation tools and `merge`/`join` operations behave unpredictably or silently select the wrong column, leading to misattributed clinical data.
- Fix: After parsing all variable names, check for duplicates and emit a warning via `schema.warnings` or raise an error if strict mode is enabled.

[SEV: Low] [ID: X012] Writer finish() exception swallowed in destructor leaves incomplete file
- Location: src/xpt/writer.cpp:213-218
```cpp
XptWriter::~XptWriter() {
    try {
        finish();
    } catch (...) {
        
        
    }
```
- Failure scenario: If `rcpp_write_xpt` throws an R error (via `Rcpp::stop`) before calling `writer.finish()`, the destructor catches the exception from `finish()` silently. The output file remains open and is closed without the required 80-byte record padding. The resulting truncated XPT file may be partially readable by lenient parsers but will fail CDISC validation. The silent swallow means the user gets no indication that the file is corrupt.
- Fix: Track whether `finish()` was called explicitly. If the destructor must call it and it fails, log a warning via `REprintf` before swallowing, or ensure `rcpp_write_xpt` always calls `finish()` in a scope guard that propagates errors before destruction.

## Confirmed-correct (do not fix)

- **IBM float decoder math** (`src/xpt/parser.hpp:119-122`): The `ldexp(v, 4 * exp16 - 56)` formulation correctly converts the 56-bit IBM hex fraction to IEEE 754 double precision. Exponent bias of 64 is properly handled. Denormals (exp16 = -64) naturally underflow to zero via ldexp, which matches SAS behavior.
- **SAS/R epoch offsets** (`src/xpt_epoch.hpp:14-15`): `kSasRDateOffset = 3653.0` correctly accounts for the difference between SAS epoch (1960-01-01) and R Date epoch (1970-01-01), including the two leap years (1960, 1964, 1968) in that span. `kSasRDatetimeOffset = 315619200.0` = 3653 × 86400 is consistent.
- **Cursor bounds checking** (`src/xpt/parser.cpp:44-82`): All `readRecord`, `readBlock`, `readU16Be`, and `alignToRecordBoundary` methods properly check `remaining()` before advancing the cursor, preventing OOB reads during schema parsing.
- **MappedFile RAII** (`src/xpt/mmap_file.hpp`): Proper move semantics, `O_CLOEXEC` usage, `munmap`/`close` in destructor, and exception safety in `open()` with fd cleanup on failure.
- **Factor width from levels** (`src/rcpp_xpt.cpp:318-322`): Correctly iterates over `R_LevelsSymbol` rather than data values to determine `storageWidth` for factor columns, ensuring the XPT field is wide enough for all possible level strings.
- **Zero-row data frame handling** (`src/rcpp_xpt.cpp:93`): The `if (nrow > 0 && !numIdx.empty())` guard correctly skips thread pool creation and data decoding for empty datasets while still building the schema/column structure.
- **Multi-member scan alignment** (`src/xpt/parser.cpp:382`): Scanning at 80-byte aligned offsets (`pos += recLen`) correctly matches XPT record structure and avoids false positives from data-section content.

## Baseline

- **Compiler/Platform**: Requires C++20 (`std::span` include in parser.cpp, though unused in visible code; `std::string_view` throughout). POSIX-only mmap implementation (`sys/mman.h`, `fcntl.h`) — not portable to Windows without adaptation layer.
- **Threading model**: Uses `std::thread` directly with manual chunking. No thread pool reuse. Atomic failure flag with relaxed memory ordering is sufficient for the join-synchronize pattern used.
- **Error propagation**: Parser uses `bool` return + `std::string& error` out-parameter pattern. Rcpp entry points convert these to `Rcpp::stop()`. Thread workers catch `std::exception` and store messages for post-join reporting.
- **XPT version support**: Handles both v5 (LIBRARY/MEMBER/NAMESTR/OBS) and v8 (LIBV8/MEMBV8/NAMSTV8/LABELV8/LABELV9/OBSV8) transport formats. Version detection is header-driven.
- **Buffer management**: Writer uses 64KB output buffer with manual flush logic. Row buffer is pre-allocated and space-filled between commits. No dynamic reallocation during row writing.
- **Format canonicalization**: Appends trailing `.` to SAS format strings lacking one, matching SAS display conventions for metadata attributes.