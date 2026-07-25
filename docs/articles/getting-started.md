# Getting Started

`kstools` provides practical helpers for clinical and data-science
workflows: descriptive summaries, pooled estimators from multiple
imputations, ROC comparison, SDTM/SUPP operations, and data-loading
tools.

## Installation

`# local source install from package root`` `[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"."``, repos ``=`` ``NULL``, type ``=`` ``"source"``)`` `` ``# from GitHub`` ``remotes``::`[`install_github`](https://remotes.r-lib.org/reference/install_github.html)`(``"crow16384/kstools"``)`

## Descriptive Summary

[`library`](https://rdrr.io/r/base/library.html)`(`[`kstools`](https://crow16384.github.io/kstools/)`)`` `` `[`set.seed`](https://rdrr.io/r/base/Random.html)`(``42``)`` ``adlb`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` trt ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"Drug A"``, ``"Placebo"``)``, each ``=`` ``50``)``,`` `` visit ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"Week 4"``, ``"Week 12"``)``, each ``=`` ``25``, times ``=`` ``2``)``,`` `` aval ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``50``, ``28``, ``8``)``, `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``50``, ``32``, ``9``)``)`` ``)`` `` `[`ks_summary`](https://crow16384.github.io/kstools/reference/ks_summary.md)`(``adlb``, ``aval``, ``trt``, ``visit``)`` ``#> ``# A tibble: 4 × 12`` ``#> trt visit n mean sd median q1 q3 min max cv NUMDEC`` ``#> ``<chr>`` ``<chr>`` ``<int>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<dbl>`` ``<int>`` ``#> ``1`` Drug A Week 12 25 25.9 7.58 25.1 21.7 31.7 8.69 39.6 29.2 4`` ``#> ``2`` Drug A Week 4 25 29.5 10.5 27.5 25.7 38.4 6.75 46.3 35.4 4`` ``#> ``3`` Placebo Week 12 25 32.5 8.05 32.8 24.3 37.9 18.9 45.6 24.7 4`` ``#> ``4`` Placebo Week 4 25 33.3 8.74 34.6 28.7 38.1 5.06 46.2 26.3 4`

## Pooled Estimate Across Imputations

`est`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.345``, ``0.303``, ``0.298``, ``0.378``)`` ``err`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.056``, ``0.101``, ``0.099``, ``0.034``)`` `` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``)`

## Variance Information (4 Imputations)

|  Between |   Within |    Total |      DF |
|---------:|---------:|---------:|--------:|
| 0.001426 | 0.006074 | 0.007856 | 58.2727 |

## Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.293488 | 0.252131 | 0.940705 |

## Parameter Estimates (4 Imputations)

| Estimate | Std Error |      LCL |      UCL |      DF |
|---------:|----------:|---------:|---------:|--------:|
|    0.331 |  0.088634 | 0.153597 | 0.508403 | 58.2727 |

## Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic |  PValue |
|--------:|--------:|-------:|----------:|--------:|
|   0.298 |   0.378 |      0 |  3.734455 | 0.00043 |

## Compare ROC Areas

[`set.seed`](https://rdrr.io/r/base/Random.html)`(``123``)`` ``n`` ``<-`` ``120`` ``y`` ``<-`` `[`rbinom`](https://rdrr.io/r/stats/Binomial.html)`(``n``, ``1``, ``0.45``)`` ``df`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` y ``=`` ``y``,`` `` x1 ``=`` ``y`` ``+`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``n``, sd ``=`` ``0.8``)``,`` `` x2 ``=`` ``0.7`` ``*`` ``y`` ``+`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``n``, sd ``=`` ``0.9``)``,`` `` x3 ``=`` ``0.5`` ``*`` ``y`` ``+`` `[`rnorm`](https://rdrr.io/r/stats/Normal.html)`(``n``, sd ``=`` ``1.0``)`` ``)`` `` ``roc_out`` ``<-`` `[`ks_roc`](https://crow16384.github.io/kstools/reference/ks_roc.md)`(``df``, var ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"x1"``, ``"x2"``, ``"x3"``)``, response ``=`` ``"y"``)`` ``roc_out``$``areas`` ``#> predictor roc_area std_error lcl ucl`` ``#> 1 x1 0.9043210 0.02660878 0.8521687 0.9564732`` ``#> 2 x2 0.6787318 0.04894766 0.5827961 0.7746674`` ``#> 3 x3 0.5953984 0.05244706 0.4926041 0.6981928`` ``roc_out``$``contrasts`` ``#> contrast estimate std_error lcl ucl chi_square p_value`` ``#> 1 Row1 0.22558923 0.05958660 0.1088016 0.3423768 14.33308 1.531501e-04`` ``#> 2 Row2 0.30892256 0.05739691 0.1964267 0.4214184 28.96825 7.357444e-08`` ``#> 3 Row3 0.08333333 0.07003717 -0.0539370 0.2206037 1.41573 2.341076e-01`

## SDTM Supplemental Merge

`dm`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` STUDYID ``=`` ``"S1"``,`` `` USUBJID ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"01"``, ``"02"``, ``"03"``)``,`` `` AGE ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``34L``, ``52L``, ``47L``)``,`` `` stringsAsFactors ``=`` ``FALSE`` ``)`` `` ``suppdm`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` STUDYID ``=`` ``"S1"``,`` `` USUBJID ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"01"``, ``"02"``, ``"03"``)``,`` `` IDVAR ``=`` ``""``,`` `` IDVARVAL ``=`` ``""``,`` `` QNAM ``=`` ``"RACE2"``,`` `` QLABEL ``=`` ``"Race (detail)"``,`` `` QVAL ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Asian"``, ``"White"``, ``"Asian"``)``,`` `` stringsAsFactors ``=`` ``FALSE`` ``)`` `` `[`ks_supp_merge`](https://crow16384.github.io/kstools/reference/ks_supp_merge.md)`(``dm``, ``suppdm``)`` ``#> STUDYID USUBJID AGE RACE2`` ``#> 1 S1 01 34 Asian`` ``#> 2 S1 02 52 White`` ``#> 3 S1 03 47 Asian`

## Next Steps

- See the `mianalyze` vignette for Rubin’s rules, Barnard-Rubin `edf`,
  and SAS `PROC MIANALYZE` comparisons.
- See the `clinical-workflows` vignette for end-to-end examples.
- Explore `inst/examples` for runnable scripts by function.
