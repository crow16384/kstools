## ============================================================
## ks_code_to_fmt() — build ksformat format from code=label column
## ============================================================

library(kstools)

if (requireNamespace("ksformat", quietly = TRUE)) {
  dm <- data.frame(
    decode = c("1=Male", "2=Female", "9=Unknown", "2=Female"),
    stringsAsFactors = FALSE
  )

  ## register with auto-generated format name
  ks_code_to_fmt(dm, decode)

  ## register with explicit name
  ks_code_to_fmt(dm, decode, name = "sex_fmt")

  ## inspect (if helper exists in your ksformat version)
  if (exists("flist", where = asNamespace("ksformat"), mode = "function")) {
    print(ksformat::flist())
  }
}
