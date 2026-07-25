# Multiple Imputation Analysis with `mianalyze()`

![](mianalyze0.png)

[`library`](https://rdrr.io/r/base/library.html)`(`[`kstools`](https://crow16384.github.io/kstools/)`)`

## Introduction

Missing data are common in clinical trials, observational studies,
registries, and real-world evidence analyses. A standard approach for
handling missing values is **multiple imputation (MI)**, where several
complete datasets are generated, each containing plausible replacements
for missing observations.

After analysing each imputed dataset, the analyst obtains:

- a parameter estimate from each imputation;
- a corresponding standard error.

The final step is to combine these results into a single inference. This
process is commonly known as **pooling** or **MI analysis** and is
described by Rubin (1987).

The
[`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
function in **kstools** implements Rubin’s pooling rules and supports
the Barnard-Rubin (1999) small-sample degrees-of-freedom adjustment,
equivalent to the `EDF=` option in SAS `PROC MIANALYZE`. The exported
alias
[`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
provides the same interface.

## Multiple Imputation Workflow

The typical workflow is:

1.  Create $`m`$ imputed datasets.
2.  Perform the same analysis on each dataset.
3.  Extract parameter estimates and standard errors.
4.  Pool the results using Rubin’s rules.

Conceptually:

%%{init: {"theme": "dark", "themeVariables": {"lineColor": "#94a3b8",
"primaryTextColor": "#f8fafc"}}}%% flowchart TD A(\[Original Dataset\])
B(\[Multiple Imputation\]) D1\[Imputed Dataset 1\<br/\>Q₁, U₁\]
D2\[Imputed Dataset 2\<br/\>Q₂, U₂\] D3\[Imputed Dataset 3\<br/\>Q₃,
U₃\] Ddots\[...\] Dm\[Imputed Dataset m\<br/\>Qₘ, Uₘ\] R{{Rubin's
Rules\<br/\>Pool Estimates and Variances}} F(\[Pooled Estimate\<br/\>SE,
CI, p-value\]) A --\> B B --\> D1 B --\> D2 B --\> D3 B --\> Ddots B
--\> Dm D1 --\> R D2 --\> R D3 --\> R Ddots --\> R Dm --\> R R --\> F
classDef source
fill:#1e40af,stroke:#93c5fd,stroke-width:2px,color:#f8fafc; classDef
process fill:#c2410c,stroke:#fdba74,stroke-width:2px,color:#f8fafc;
classDef imputed
fill:#166534,stroke:#86efac,stroke-width:2px,color:#f8fafc; classDef
pooling fill:#6d28d9,stroke:#c4b5fd,stroke-width:2px,color:#f8fafc;
classDef result
fill:#15803d,stroke:#86efac,stroke-width:3px,color:#f8fafc; class A
source; class B process; class D1,D2,D3,Dm imputed; class R pooling;
class F result; linkStyle default stroke:#94a3b8,stroke-width:1.5px

## Rubin’s Rules

Suppose $`Q_i`$ is the estimate from imputation $`i`$ and $`U_i`$ is its
variance. Let $`m`$ be the number of imputations.

### Pooled Estimate

``` math
\bar{Q} = \frac{1}{m} \sum_{i=1}^{m}Q_i
```

### Within-Imputation Variance

``` math
\bar{U} = \frac{1}{m} \sum_{i=1}^{m}U_i
```

This quantity reflects uncertainty that would exist even if no data were
missing.

### Between-Imputation Variance

``` math
B = \frac{1}{m-1}\sum_{i=1}^{m}(Q_i-\bar{Q})^2
```

Large values indicate substantial uncertainty due to missing data.

### Total Variance

``` math
T = \bar{U} + \left(1+\frac{1}{m}\right) B
```

The pooled standard error is $`SE = \sqrt{T}`$.

## Relative Increase in Variance

``` math
r = \frac{\left(1+\frac{1}{m}\right) B}{\bar{U}}
```

Values near zero indicate little impact from missing data.

## Fraction of Missing Information

For finite Rubin degrees of freedom $`v_m`$,

``` math
\hat\lambda = \frac{r + 2/(v_m + 3)}{r + 1}
```

When $`v_m`$ is treated as infinite (large-sample case), this simplifies
to $`\hat\lambda = r/(r+1)`$. The quantity is often interpreted as the
proportion of uncertainty attributable to missingness.

| $`\lambda`$       | Interpretation                 |
|-------------------|--------------------------------|
| $`< 0.05`$        | Negligible missing information |
| $`0.05`$–$`0.20`$ | Mild impact                    |
| $`0.20`$–$`0.50`$ | Moderate impact                |
| $`> 0.50`$        | Severe impact                  |

## Relative Efficiency

``` math
RE = \frac{1}{1 + \lambda/m}
```

Values close to 1 indicate that additional imputations would provide
little benefit.

## Degrees of Freedom

### Rubin (1987)

``` math
v_m = (m-1)\left(1+\frac{\bar{U}}{\left(1+m^{-1}\right)B}\right)^2
```

When $`m`$ is small and missing information is limited, $`v_m`$ can
become very large.

### Problem with Large-Sample Degrees of Freedom

Suppose a model parameter is based on only 40 residual degrees of
freedom. Rubin’s formula may yield $`v_m = 500`$, which exceeds the
information available in the complete-data analysis and can produce
confidence intervals that are unrealistically narrow.

## Barnard-Rubin Adjustment

Barnard and Rubin (1999) proposed a small-sample correction. Let $`v_0`$
be the complete-data degrees of freedom. Define

``` math
\gamma = \frac{(1 + m^{-1}) B}{T}
```

and

``` math
\hat{v}_{obs} = (1-\gamma)\, v_0\, \frac{v_0+1}{v_0+3}
```

The adjusted degrees of freedom are

``` math
v_m^* = \left(\frac{1}{v_m} + \frac{1}{\hat{v}_{obs}}\right)^{-1}
```

This is the method used by SAS `PROC MIANALYZE` when `EDF=` is
specified, and by `mianalyze(edf = ...)`.

## Basic Example

`est`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.345``, ``0.303``, ``0.298``, ``0.378``)`` ``err`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.056``, ``0.101``, ``0.099``, ``0.034``)`` ``out`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``)`` ``out`

### Variance Information (4 Imputations)

|  Between |   Within |    Total |      DF |
|---------:|---------:|---------:|--------:|
| 0.001426 | 0.006074 | 0.007856 | 58.2727 |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.293488 | 0.252131 | 0.940705 |

### Parameter Estimates (4 Imputations)

| Estimate | Std Error |      LCL |      UCL |      DF |
|---------:|----------:|---------:|---------:|--------:|
|    0.331 |  0.088634 | 0.153597 | 0.508403 | 58.2727 |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic |  PValue |
|--------:|--------:|-------:|----------:|--------:|
|   0.298 |   0.378 |      0 |  3.734455 | 0.00043 |

## Example: Manual Verification

`est`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.345``, ``0.303``, ``0.298``, ``0.378``)`` ``err`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.056``, ``0.101``, ``0.099``, ``0.034``)`` `` ``m`` ``<-`` `[`length`](https://rdrr.io/r/base/length.html)`(``est``)`` ``Qbar`` ``<-`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``est``)`` ``Vw`` ``<-`` `[`mean`](https://rdrr.io/r/base/mean.html)`(``err``^``2``)`` ``Vb`` ``<-`` `[`var`](https://rdrr.io/r/stats/cor.html)`(``est``)`` ``Vt`` ``<-`` ``Vw`` ``+`` ``(``1`` ``+`` ``1`` ``/`` ``m``)`` ``*`` ``Vb`` `` ``manual`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``Estimate ``=`` ``Qbar``, Vw ``=`` ``Vw``, Vb ``=`` ``Vb``, Vt ``=`` ``Vt``, SE ``=`` `[`sqrt`](https://rdrr.io/r/base/MathFun.html)`(``Vt``)``)`` ``pooled`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` Estimate ``=`` ``out``$``Estimate``, Vw ``=`` ``out``$``Vw``, Vb ``=`` ``out``$``Vb``,`` `` Vt ``=`` ``out``$``Vt``, SE ``=`` ``out``$``StdErr`` ``)`` `[`rbind`](https://rdrr.io/r/base/cbind.html)`(``manual ``=`` ``manual``, mianalyze ``=`` ``pooled``)`` ``#> Estimate Vw Vb Vt SE`` ``#> manual 0.331 0.0060735 0.001426 0.007856 0.08863408`` ``#> mianalyze 0.331 0.0060735 0.001426 0.007856 0.08863408`

## Example: Treatment Difference

`est`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``-``2.8``, ``-``3.2``, ``-``2.5``, ``-``3.1``, ``-``2.9``)`` ``err`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``1.10``, ``1.15``, ``1.05``, ``1.18``, ``1.12``)`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``)`

### Variance Information (5 Imputations)

| Between |  Within |   Total |       DF |
|--------:|--------:|--------:|---------:|
|   0.075 | 1.25636 | 1.34636 | 895.1532 |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.071636 | 0.068925 | 0.986402 |

### Parameter Estimates (5 Imputations)

| Estimate | Std Error |       LCL |       UCL |       DF |
|---------:|----------:|----------:|----------:|---------:|
|     -2.9 |  1.160328 | -5.177279 | -0.622721 | 895.1532 |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic |   PValue |
|--------:|--------:|-------:|----------:|---------:|
|    -3.2 |    -2.5 |      0 | -2.499294 | 0.012622 |

Interpretation:

- the pooled estimate is the average treatment difference;
- the pooled standard error combines model and imputation uncertainty;
- confidence intervals incorporate missing-data uncertainty.

## Example: Odds Ratio Analysis

Pool results on the log scale, then exponentiate.

`log_or`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.18``, ``0.21``, ``0.15``, ``0.19``, ``0.23``)`` ``se_log_or`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.09``, ``0.10``, ``0.09``, ``0.08``, ``0.11``)`` ``res`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``log_or``, ``se_log_or``)`` ``res`

### Variance Information (5 Imputations)

| Between |  Within |    Total |       DF |
|--------:|--------:|---------:|---------:|
| 0.00092 | 0.00894 | 0.010044 | 331.0818 |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.12349 | 0.115245 | 0.97747 |

### Parameter Estimates (5 Imputations)

| Estimate | Std Error |       LCL |      UCL |       DF |
|---------:|----------:|----------:|---------:|---------:|
|    0.192 |   0.10022 | -0.005148 | 0.389148 | 331.0818 |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic |   PValue |
|--------:|--------:|-------:|----------:|---------:|
|    0.15 |    0.23 |      0 |   1.91579 | 0.056253 |

` `[`exp`](https://rdrr.io/r/base/Log.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``OR ``=`` ``res``$``Estimate``, LCL ``=`` ``res``$``lcl``, UCL ``=`` ``res``$``ucl``)``)`` ``#> OR LCL UCL `` ``#> 1.2116705 0.9948654 1.4757226`

## Example: Hazard Ratio Analysis

Cox models typically return log-hazard ratios.

`log_hr`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``-``0.22``, ``-``0.17``, ``-``0.31``, ``-``0.28``, ``-``0.24``)`` ``se`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.14``, ``0.13``, ``0.15``, ``0.12``, ``0.13``)`` ``res`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``log_hr``, ``se``)`` ``res`

### Variance Information (5 Imputations)

| Between |  Within |    Total |       DF |
|--------:|--------:|---------:|---------:|
| 0.00293 | 0.01806 | 0.021576 | 150.6275 |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.194684 | 0.173856 | 0.966397 |

### Parameter Estimates (5 Imputations)

| Estimate | Std Error |       LCL |      UCL |       DF |
|---------:|----------:|----------:|---------:|---------:|
|   -0.244 |  0.146888 | -0.534226 | 0.046226 | 150.6275 |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic |   PValue |
|--------:|--------:|-------:|----------:|---------:|
|   -0.31 |   -0.17 |      0 | -1.661133 | 0.098767 |

` `[`exp`](https://rdrr.io/r/base/Log.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``HR ``=`` ``res``$``Estimate``, LCL ``=`` ``res``$``lcl``, UCL ``=`` ``res``$``ucl``)``)`` ``#> HR LCL UCL `` ``#> 0.7834876 0.5861225 1.0473115`

## Example: Small-Sample Degrees of Freedom

Assume the complete-data analysis would have $`v_0 = 40`$:

`est`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.345``, ``0.303``, ``0.298``, ``0.378``)`` ``err`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.056``, ``0.101``, ``0.099``, ``0.034``)`` `` ``br`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``, edf ``=`` ``40``)`` ``rubin`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``)`` `` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` method ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Barnard-Rubin (edf=40)"``, ``"Rubin large-sample"``)``,`` `` df ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``br``$``df``, ``rubin``$``df``)``,`` `` lcl ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``br``$``lcl``, ``rubin``$``lcl``)``,`` `` ucl ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``br``$``ucl``, ``rubin``$``ucl``)`` ``)`` ``#> method df lcl ucl`` ``#> 1 Barnard-Rubin (edf=40) 19.57893 0.1458573 0.5161427`` ``#> 2 Rubin large-sample 58.27270 0.1535973 0.5084027`

The adjusted degrees of freedom are smaller, producing slightly wider
confidence intervals.

## Comparison with SAS PROC MIANALYZE

[`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
is a univariate analogue of SAS `PROC MIANALYZE`. The formulas for
$`\bar{Q}`$, $`\bar{U}`$, $`B`$, $`T`$, $`r`$, $`\hat\lambda`$, $`RE`$,
$`v_m`$, and the Barnard-Rubin $`v_m^*`$ match those in the SAS/STAT
User’s Guide (Chapter *The MIANALYZE Procedure*).

### Option mapping

| SAS `PROC MIANALYZE` | [`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md) |
|----|----|
| Estimates + standard errors (e.g. `STDERR` / `PARMS`) | `est`, `err` |
| `ALPHA=` | `alpha` (default `0.05`) |
| `THETA0=` | `theta0` (default `0`) |
| `EDF=` (Barnard-Rubin) | `edf` (default `Inf` = no adjustment) |
| — | `v0` (deprecated alias for `edf`) |

Note: SAS documents a default of `EDF=1` with *no* adjustment when
`EDF=` is omitted. In **kstools**, omitting `edf` (or using `edf = Inf`)
likewise uses Rubin’s large-sample $`v_m`$ without Barnard-Rubin
adjustment.

### Scope

Aligned with SAS univariate MI inference:

- pooled estimate, total variance, $`t`$-based CI and test;
- variance diagnostics $`r`$, $`\hat\lambda`$, $`RE`$;
- Barnard-Rubin df via `edf`.

Not implemented (multivariate SAS features):

- Wald multivariate tests (`MULT` / `MULTIVARIATE`);
- `TEST` linear hypotheses;
- pooling from full covariance matrices alone (without per-parameter
  SEs).

### SAS Example 58.1 (means and standard errors, `EDF=30`)

The Fitness example in SAS/STAT 12.3 Example 58.1 combines univariate
means and standard errors across $`m = 5`$ imputations with `EDF=30`
(sample size $`n = 31`$). Reproducing Oxygen from the published input
table:

`oxygen`` ``<-`` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(`` `` est ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``47.0120``, ``47.2407``, ``47.4995``, ``47.1485``, ``47.0042``)``,`` `` err ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.95984``, ``0.93540``, ``1.00766``, ``0.95439``, ``0.96528``)``,`` `` edf ``=`` ``30`` ``)`` ``oxygen`

### Variance Information (5 Imputations)

| Between |   Within |    Total |       DF |
|--------:|---------:|---------:|---------:|
| 0.04147 | 0.930854 | 0.980619 | 26.29868 |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0.053461 | 0.051968 | 0.989713 |

### Parameter Estimates (5 Imputations)

| Estimate | Std Error |      LCL |      UCL |       DF |
|---------:|----------:|---------:|---------:|---------:|
| 47.18098 |  0.990262 | 45.14659 | 49.21537 | 26.29868 |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic | PValue |
|--------:|--------:|-------:|----------:|-------:|
| 47.0042 | 47.4995 |      0 |  47.64495 |      0 |

Comparison with SAS Output 58.1.2 / 58.1.3 (Oxygen). Small differences
are expected because the User’s Guide prints input means/SEs with
limited precision.

`sas_oxygen`` ``<-`` `[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`` `` quantity ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"Estimate"``, ``"StdErr"``, ``"Between"``, ``"Within"``, ``"Total"``,`` `` ``"DF"``, ``"r"``, ``"lambda"``, ``"RE"``, ``"LCL"``, ``"UCL"`` `` ``)``,`` `` sas ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``47.180993``, ``0.990266``, ``0.041478``, ``0.930853``, ``0.980626``,`` `` ``26.298``, ``0.053471``, ``0.051977``, ``0.989712``, ``45.1466``, ``49.2154`` `` ``)``,`` `` mianalyze ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``oxygen``$``Estimate``, ``oxygen``$``StdErr``, ``oxygen``$``Vb``, ``oxygen``$``Vw``, ``oxygen``$``Vt``,`` `` ``oxygen``$``df``, ``oxygen``$``r``, ``oxygen``$``lambda``, ``oxygen``$``re``, ``oxygen``$``lcl``, ``oxygen``$``ucl`` `` ``)`` ``)`` ``sas_oxygen``$``abs_diff`` ``<-`` `[`abs`](https://rdrr.io/r/base/MathFun.html)`(``sas_oxygen``$``mianalyze`` ``-`` ``sas_oxygen``$``sas``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(``sas_oxygen``, digits ``=`` ``6``)`

| quantity |       sas | mianalyze | abs_diff |
|:---------|----------:|----------:|---------:|
| Estimate | 47.180993 | 47.180980 | 0.000013 |
| StdErr   |  0.990266 |  0.990262 | 0.000004 |
| Between  |  0.041478 |  0.041470 | 0.000008 |
| Within   |  0.930853 |  0.930854 | 0.000001 |
| Total    |  0.980626 |  0.980619 | 0.000007 |
| DF       | 26.298000 | 26.298679 | 0.000679 |
| r        |  0.053471 |  0.053461 | 0.000010 |
| lambda   |  0.051977 |  0.051968 | 0.000009 |
| RE       |  0.989712 |  0.989713 | 0.000001 |
| LCL      | 45.146600 | 45.146592 | 0.000008 |
| UCL      | 49.215400 | 49.215368 | 0.000032 |

The same pattern holds for RunTime and RunPulse in that example, and for
the Getting Started / Example 58.3 regression coefficients when moments
are reconstructed from the published Between/Within variances (with and
without `EDF=28`). Automated checks live in
`tests/testthat/test-ks_mianalyze-sas.R`.

### Relative efficiency (SAS Table 58.2)

SAS tabulates $`RE = 1/(1+\lambda/m)`$. For illustration:

`re_grid`` ``<-`` `[`expand.grid`](https://rdrr.io/r/base/expand.grid.html)`(`` `` m ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``3``, ``5``, ``10``, ``20``)``,`` `` lambda ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``0.1``, ``0.2``, ``0.3``, ``0.5``, ``0.7``)`` ``)`` ``re_grid``$``RE`` ``<-`` `[`with`](https://rdrr.io/r/base/with.html)`(``re_grid``, ``1`` ``/`` ``(``1`` ``+`` ``lambda`` ``/`` ``m``)``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` `[`xtabs`](https://rdrr.io/r/stats/xtabs.html)`(``RE`` ``~`` ``m`` ``+`` ``lambda``, data ``=`` ``re_grid``)``,`` `` digits ``=`` ``4``,`` `` caption ``=`` ``"Relative efficiency (matches SAS Table 58.2)"`` ``)`

|     |    0.1 |    0.2 |    0.3 |    0.5 |    0.7 |
|:----|-------:|-------:|-------:|-------:|-------:|
| 3   | 0.9677 | 0.9375 | 0.9091 | 0.8571 | 0.8108 |
| 5   | 0.9804 | 0.9615 | 0.9434 | 0.9091 | 0.8772 |
| 10  | 0.9901 | 0.9804 | 0.9709 | 0.9524 | 0.9346 |
| 20  | 0.9950 | 0.9901 | 0.9852 | 0.9756 | 0.9662 |

Relative efficiency (matches SAS Table 58.2) {.table .caption-top}

### API correspondence

SAS:

```
proc mianalyze data=outuni edf=30;
  modeleffects Oxygen;
  stderr SOxygen;
run;
```

Equivalent R:

[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est ``=`` ``oxygen_est``, err ``=`` ``oxygen_se``, edf ``=`` ``30``)`

## Typical Clinical Trial Workflow

A common workflow with the **mice** package:

[`library`](https://rdrr.io/r/base/library.html)`(`[`mice`](https://github.com/amices/mice)`)`` `` ``imp`` ``<-`` `[`mice`](https://amices.org/mice/reference/mice.html)`(``adsl``, m ``=`` ``20``)`` `` ``fits`` ``<-`` `[`with`](https://rdrr.io/r/base/with.html)`(`` `` ``imp``,`` `` `[`lm`](https://rdrr.io/r/stats/lm.html)`(``CHG`` ``~`` ``TRT01A`` ``+`` ``BASE``)`` ``)`` `` ``est`` ``<-`` `[`sapply`](https://rdrr.io/r/base/lapply.html)`(`` `` ``fits``$``analyses``,`` `` ``function``(``x``)`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(`[`summary`](https://rdrr.io/r/base/summary.html)`(``x``)``)``[``"TRT01AActive"``, ``"Estimate"``]`` ``)`` `` ``err`` ``<-`` `[`sapply`](https://rdrr.io/r/base/lapply.html)`(`` `` ``fits``$``analyses``,`` `` ``function``(``x``)`` `[`coef`](https://rdrr.io/r/stats/coef.html)`(`[`summary`](https://rdrr.io/r/base/summary.html)`(``x``)``)``[``"TRT01AActive"``, ``"Std. Error"``]`` ``)`` `` `[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est``, ``err``)`

## Interpreting Output

### Variance Components

| Component      | Meaning                                |
|----------------|----------------------------------------|
| $`V_w`$ (`Vw`) | Within-imputation variance $`\bar{U}`$ |
| $`V_b`$ (`Vb`) | Between-imputation variance $`B`$      |
| $`V_t`$ (`Vt`) | Total variance $`T`$                   |

Large $`V_b`$ relative to $`V_w`$ indicates substantial missing-data
uncertainty.

### Missing Information

| Metric      | Meaning                         |
|-------------|---------------------------------|
| $`r`$       | Relative increase in variance   |
| $`\lambda`$ | Fraction of missing information |
| $`RE`$      | Relative efficiency             |

### Inference

| Statistic | Meaning                                        |
|-----------|------------------------------------------------|
| Estimate  | Pooled estimate $`\bar{Q}`$                    |
| StdErr    | Pooled standard error $`\sqrt{T}`$             |
| lcl / ucl | Confidence interval                            |
| $`t`$     | Test statistic for $`H_0{:}\,\theta=\theta_0`$ |
| pval      | Two-sided $`p`$-value                          |

## Special Cases

### Single Imputation

[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est ``=`` ``10``, err ``=`` ``2``)`

### Variance Information (1 Imputations)

| Between | Within | Total |  DF |
|--------:|-------:|------:|----:|
|       0 |      4 |     4 | Inf |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0 | 0 | 1 |

### Parameter Estimates (1 Imputations)

| Estimate | Std Error |      LCL |      UCL |  DF |
|---------:|----------:|---------:|---------:|----:|
|       10 |         2 | 6.080072 | 13.91993 | Inf |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic | PValue |
|--------:|--------:|-------:|----------:|-------:|
|      10 |      10 |      0 |         5 |  1e-06 |

Here $`B = 0`$, $`T = \bar{U}`$, and results reduce to ordinary
complete-data inference.

### No Between-Imputation Variability

[`mianalyze`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)`(``est ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(``5``, ``5``)``, err ``=`` `[`rep`](https://rdrr.io/r/base/rep.html)`(``1``, ``5``)``)`

### Variance Information (5 Imputations)

| Between | Within | Total |  DF |
|--------:|-------:|------:|----:|
|       0 |      1 |     1 | Inf |

### Missing Data Diagnostics

| Relative Increase in Variance | Fraction Missing Information | Relative Efficiency |
|---:|---:|---:|
| 0 | 0 | 1 |

### Parameter Estimates (5 Imputations)

| Estimate | Std Error |      LCL |      UCL |  DF |
|---------:|----------:|---------:|---------:|----:|
|        5 |         1 | 3.040036 | 6.959964 | Inf |

### Hypothesis Test

| Minimum | Maximum | Theta0 | Statistic | PValue |
|--------:|--------:|-------:|----------:|-------:|
|       5 |       5 |      0 |         5 |  1e-06 |

When all imputations produce the same estimate, $`B = 0`$ and no
additional uncertainty is attributed to missing data.

## Summary

- **[`mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)
  /
  [`ks_mianalyze()`](https://crow16384.github.io/kstools/reference/ks_mianalyze.md)**
  pool MI point estimates and standard errors with Rubin’s rules:
  $`\bar{Q}`$, $`T = \bar{U}+(1+1/m)B`$, $`t`$-based intervals and
  tests.
- **Diagnostics** $`r`$, $`\hat\lambda`$, and $`RE`$ quantify the impact
  of missingness and the efficiency of finite $`m`$.
- **`edf`** applies the Barnard-Rubin (1999) small-sample df adjustment,
  matching SAS `EDF=`.
- **Agreement with SAS** univariate `PROC MIANALYZE` was checked against
  SAS/STAT 12.3 formulas, Table 58.2, Example 58.1 (`EDF=30`), and
  Example 58.3 (`EDF=28`).
- **Pool on the analysis scale** (e.g. log-OR, log-HR), then transform
  intervals if needed.
- Prefer **`edf`** whenever complete-data residual df are modest so that
  $`v_m`$ does not exceed the information in the original sample.

## References

Barnard, J. and Rubin, D.B. (1999). Small-sample degrees of freedom with
multiple imputation. *Biometrika*, 86, 948–955.

Rubin, D.B. (1987). *Multiple Imputation for Nonresponse in Surveys*.
Wiley.

SAS Institute Inc. (2013). *SAS/STAT 12.3 User’s Guide*. Chapter 58, The
MIANALYZE Procedure. Cary, NC: SAS Institute Inc.

Van Buuren, S. (2018). *Flexible Imputation of Missing Data*. Second
Edition. Chapman & Hall/CRC.
