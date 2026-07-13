# Clinical Workflows

This vignette shows practical combinations of `kstools` functions for
common clinical programming tasks.

``` r

library(kstools)
```

## 1. Incidence Rate and Proportion Comparisons

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

## 2. Randomization Design

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

## 3. Data Loaders

``` r

# one-shot load of multiple domains from RDS directory (returns a named list)
dat <- ks_get_data(dm, ae, adlb, path = "data/rds")
dm  <- dat$dm

# case-insensitive lookup works too
dm <- ks_get_data(DM, path = "data/rds")  # matches dm.rds, DM.RDS, etc.

# or bulk by file type
x <- ks_batch_load("data/rds", type = "rds")
names(x)
```

These pieces can be mixed to build reproducible data review and
reporting pipelines.
