# Simulate longitudinal data with AR(1) within-subject errors

Generates a random sample of subjects with random intercepts and slopes,
irregular observation times, and Gaussian AR(1) serially correlated
residuals. The result is an
[`groupedData`](https://rdrr.io/pkg/nlme/man/groupedData.html) object
suitable for exploratory plots or simulation studies.

## Usage

``` r
ks_simulate_ar1(
  n,
  beta0,
  beta1,
  ar.val = 0.4,
  sigma,
  tau0,
  tau1,
  tau01 = 0.3,
  m,
  seed = NULL
)
```

## Arguments

- n:

  Number of subjects (\\(\ge 1\\)).

- beta0:

  Population mean intercept (fixed effect on the log-time scale).

- beta1:

  Population mean slope (coefficient of \\(\log(\mathrm{obs})\\)).

- ar.val:

  Autoregressive coefficient \\(\phi\\) for the within-subject errors
  (must lie strictly between \\(-1\\) and \\(1\\)).

- sigma:

  Marginal standard deviation of the AR(1) error (after the scaling
  described in **Details**).

- tau0, tau1:

  Standard deviations of random intercept and random slope.

- tau01:

  Correlation between random intercept and slope (in \\(\[-1,1\]\\)).

- m:

  Maximum possible number of visits per subject (must be \\(\ge 4\\)).
  Each subject receives between 4 and `m` observations, always including
  time `obs = 1`.

- seed:

  Optional integer; if not `NULL`, passed to
  [`set.seed`](https://rdrr.io/r/base/Random.html) before random draws
  (reproducibility).

## Value

An [`groupedData`](https://rdrr.io/pkg/nlme/man/groupedData.html) object
(also inherits from `data.frame`) with columns `id`, `obs`, and `y`.

## Details

Observation counts \\(p_i\\) are uniform on \\(\\{4,\ldots,m\\}\\)
(rounded from continuous uniforms). Observation times are \\(1\\) plus a
random subset of \\(\\{2,\ldots,m\\}\\) of size \\(p_i-1\\).

Random effects \\((b\_{0i}, b\_{1i})'\\) are bivariate normal with mean
zero, SDs `tau0`, `tau1` and correlation `tau01`. Outcomes are
\$\$y\_{ij} = (\beta_0 + b\_{0i}) + (\beta_1 + b\_{1i})\log(t\_{ij}) +
\varepsilon\_{ij}\$\$ with \\(\varepsilon\_{i\cdot}\\) an AR(1) Gaussian
series. Innovations are scaled so that the marginal residual SD is
`sigma`: `arima.sim(...)` is multiplied by \\(\sigma\sqrt{1-\phi^2}\\).

## See also

[`arima.sim`](https://rdrr.io/r/stats/arima.sim.html),
[`mvrnorm`](https://rdrr.io/pkg/MASS/man/mvrnorm.html),
[`groupedData`](https://rdrr.io/pkg/nlme/man/groupedData.html)

## Examples

``` r
set.seed(1)
dt <- ks_simulate_ar1(
  n = 10, beta0 = 5, beta1 = 1, ar.val = 0.4, sigma = 2,
  tau0 = 1, tau1 = 0.5, tau01 = 0.2, m = 8, seed = 1L
)
head(dt)
#> Grouped Data: y ~ obs | id
#> <environment: 0x7bb0ae3d20>
#>   id obs        y
#> 1  1   1 5.193845
#> 2  1   2 3.111578
#> 3  1   4 5.768827
#> 4  1   6 6.680145
#> 5  1   8 6.771501
#> 6  2   1 2.254783
```
