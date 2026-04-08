## ============================================================
## ks_del_tmp() — remove temporary objects from .GlobalEnv
## ============================================================

library(kstools)

assign("t.adsl", data.frame(id = 1:2), envir = .GlobalEnv)
assign("o.flags", c(TRUE, FALSE), envir = .GlobalEnv)
assign("keep_me", 123, envir = .GlobalEnv)

ls(pattern = "^(t\\.|o\\.|keep_me)", envir = .GlobalEnv)

## Remove both t.* and o.*
ks_del_tmp(o = TRUE)
ls(pattern = "^(t\\.|o\\.|keep_me)", envir = .GlobalEnv)

## Recreate and remove only t.*
assign("t.tmp", 1, envir = .GlobalEnv)
assign("o.tmp", 2, envir = .GlobalEnv)
ks_del_tmp(o = FALSE)
ls(pattern = "^(t\\.|o\\.)", envir = .GlobalEnv)
