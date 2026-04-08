# Clinical Workflows

This vignette shows practical combinations of `kstools` functions for
common clinical programming tasks.

## 1. Data Quality Checks and Tracking

``` r

library(kstools)

adsl <- data.frame(
  USUBJID = sprintf("01-%03d", 1:6),
  AGE = c(34, 52, -1, 40, 29, 70),
  SEX = c("M", "F", "M", NA, "F", "X"),
  stringsAsFactors = FALSE
)

rules <- list(
  list(expr = ~ AGE < 0, msg = "AGE must be non-negative"),
  list(expr = ~ is.na(SEX), msg = "SEX missing"),
  list(expr = ~ !(SEX %in% c("M", "F")) & !is.na(SEX), msg = "SEX invalid")
)

checked <- ks_check_rules(adsl, rules, mode = "all")
checked <- ks_collapse_check_msgs(checked, col = check_msgs)
checked
#>   USUBJID AGE  SEX               check_msgs
#> 1  01-001  34    M                       OK
#> 2  01-002  52    F                       OK
#> 3  01-003  -1    M AGE must be non-negative
#> 4  01-004  40 <NA>              SEX missing
#> 5  01-005  29    F                       OK
#> 6  01-006  70    X              SEX invalid
```

Track deltas against a prior snapshot:

``` r

previous <- checked
current <- checked
current$AGE[2] <- 45
current$check_msgs[2] <- "OK"

ks_compare_check_state(
  current = current,
  previous = previous,
  key_cols = "USUBJID",
  compare_cols = c("AGE", "check_msgs")
)[, c("USUBJID", "status")]
#>   USUBJID  status
#> 1  01-001        
#> 2  01-002 changed
#> 3  01-003        
#> 4  01-004        
#> 5  01-005        
#> 6  01-006
```

## 2. Incidence Rate and Proportion Comparisons

``` r

ks_eairdiff_mn(n1 = 10, n2 = 5, T1 = 100, T2 = 100)
#>      delta         lcl     ucl
#> [1,]  0.05 -0.02953395 0.13963

ks_newcombe_hs(
  x1 = 36L, n1 = 54L,
  x2 = 41L, n2 = 56L
)
#>            delta        lcl       ucl
#> [1,] -0.06547619 -0.2308967 0.1039632
```

Stratified alternatives:

``` r

ks_eairdiff_strata_mn(
  n1 = c(10, 5), n2 = c(5, 3),
  T1 = c(100, 80), T2 = c(100, 70)
)
#>       delta         lcl         ucl 
#>  0.03482143 -0.01869878  0.09902783

ks_newcombe_hs_strata(
  x1 = c(36L, 10L), n1 = c(54L, 30L),
  x2 = c(41L, 8L),  n2 = c(56L, 30L)
)
#>       delta         lcl         ucl 
#> -0.01882756 -0.15251739  0.11513790
```

## 3. Randomization Design

``` r

w <- ks_williams(
  tmts_num = 4,
  tmt_names = c("Drug1A", "Drug2B", "ActCtrl", "Placebo"),
  sample_size = 24,
  seed_num = 20260408
)

w$design
#>   SeqNo Period1 Period2 Period3 Period4
#> 1     1  Drug2B  Drug1A ActCtrl Placebo
#> 2     2 ActCtrl  Drug2B Placebo  Drug1A
#> 3     3 Placebo ActCtrl  Drug1A  Drug2B
#> 4     4  Drug1A Placebo  Drug2B ActCtrl
head(w$schedule)
#>   Sub_ID                         Sequence
#> 1      1 Drug1A--Placebo--Drug2B--ActCtrl
#> 2      2 ActCtrl--Drug2B--Placebo--Drug1A
#> 3      3 Drug2B--Drug1A--ActCtrl--Placebo
#> 4      4 Placebo--ActCtrl--Drug1A--Drug2B
#> 5      5 Drug1A--Placebo--Drug2B--ActCtrl
#> 6      6 Drug2B--Drug1A--ActCtrl--Placebo
```

## 4. Consolidated Export to XLSX

``` r

# requires openxlsx2
ks_save2xlsx_by(
  data = checked,
  file = "checks.xlsx",
  colors = c("missing" = "#FFF2CC", "invalid" = "#F8CBAD", "OK" = "#E2F0D9"),
  split_col = type,
  msg_col = check_msgs
)
```

## 5. Data Loaders

``` r

# one-shot load of multiple domains from RDS directory
ks_get_data(dm, ae, adlb, path = "data/rds")

# or bulk by file type
x <- ks_batch_load("data/rds", type = "rds")
names(x)
```

These pieces can be mixed to build reproducible data review and
reporting pipelines.
