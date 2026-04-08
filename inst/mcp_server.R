# kstools MCP server
#
# Exposes key kstools statistical functions as MCP tools so that AI assistants
# (Copilot, Claude, etc.) can call them directly during an interactive session.
#
# Usage:
#   Rscript inst/mcp_server.R          # stdio transport (Claude Desktop / VS Code)
#   Rscript inst/mcp_server.R --http   # HTTP transport on port 3131
#
# Requirements:
#   pak::pkg_install("devOpifex/mcpr")

library(mcpr)
library(kstools)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

fmt <- function(x) paste(utils::capture.output(print(x)), collapse = "\n")

as_num <- function(x) as.numeric(unlist(x))
as_int <- function(x) as.integer(unlist(x))

# ---------------------------------------------------------------------------
# Tool: ks_mianalyze
# ---------------------------------------------------------------------------

tool_mianalyze <- new_tool(
  name = "ks_mianalyze",
  description = paste(
    "Pool point estimates and standard errors across multiple imputations",
    "using Rubin's rules (analogous to SAS PROC MIANALYZE).",
    "Returns the pooled estimate, pooled SE, confidence interval, degrees of",
    "freedom, fraction of missing information, relative efficiency, and",
    "two-sided p-value against theta0."
  ),
  input_schema = schema(
    properties = properties(
      est    = property_array("est",    "Numeric vector of point estimates, one per imputation.", required = TRUE),
      err    = property_array("err",    "Numeric vector of standard errors, one per imputation.", required = TRUE),
      alpha  = property_number("alpha",  "Significance level for CI (default 0.05).",              required = FALSE),
      theta0 = property_number("theta0", "Null value for H0: theta = theta0 (default 0).",          required = FALSE),
      v0     = property_number("v0",
        "Optional complete-data degrees of freedom for Barnard-Rubin small-sample df adjustment.",
        required = FALSE
      )
    )
  ),
  handler = function(params) {
    tryCatch({
      est    <- as_num(params$est)
      err    <- as_num(params$err)
      alpha  <- if (!is.null(params$alpha))  as.numeric(params$alpha)  else 0.05
      theta0 <- if (!is.null(params$theta0)) as.numeric(params$theta0) else 0

      res <- if (!is.null(params$v0)) {
        ks_mianalyze(est, err, alpha = alpha, theta0 = theta0, v0 = as.numeric(params$v0))
      } else {
        ks_mianalyze(est, err, alpha = alpha, theta0 = theta0)
      }
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_newcombe_hs
# ---------------------------------------------------------------------------

tool_newcombe_hs <- new_tool(
  name = "ks_newcombe_hs",
  description = paste(
    "Newcombe Hybrid Score confidence interval for the difference of two proportions.",
    "Provide event counts (x1, x2) and group totals (n1, n2).",
    "Vectorised: pass arrays of equal length for multiple rows."
  ),
  input_schema = schema(
    properties = properties(
      x1    = property_array("x1",    "Event count(s) in group 1.",      required = TRUE),
      n1    = property_array("n1",    "Group total(s) in group 1.",       required = TRUE),
      x2    = property_array("x2",    "Event count(s) in group 2.",      required = TRUE),
      n2    = property_array("n2",    "Group total(s) in group 2.",       required = TRUE),
      alpha = property_number("alpha", "Significance level (default 0.05).", required = FALSE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_newcombe_hs(
        as_num(params$x1), as_num(params$n1),
        as_num(params$x2), as_num(params$n2),
        alpha = if (!is.null(params$alpha)) as.numeric(params$alpha) else 0.05
      )
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_newcombe_hs_strata
# ---------------------------------------------------------------------------

tool_newcombe_hs_strata <- new_tool(
  name = "ks_newcombe_hs_strata",
  description = paste(
    "Stratified Newcombe Hybrid Score CI for a proportion difference.",
    "Provide stratum-level event counts and totals; returns a single pooled CI."
  ),
  input_schema = schema(
    properties = properties(
      x1    = property_array("x1",    "Event count per stratum in group 1.", required = TRUE),
      n1    = property_array("n1",    "Total per stratum in group 1.",       required = TRUE),
      x2    = property_array("x2",    "Event count per stratum in group 2.", required = TRUE),
      n2    = property_array("n2",    "Total per stratum in group 2.",       required = TRUE),
      alpha = property_number("alpha", "Significance level (default 0.05).",  required = FALSE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_newcombe_hs_strata(
        as_num(params$x1), as_num(params$n1),
        as_num(params$x2), as_num(params$n2),
        alpha = if (!is.null(params$alpha)) as.numeric(params$alpha) else 0.05
      )
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_eairdiff_mn
# ---------------------------------------------------------------------------

tool_eairdiff_mn <- new_tool(
  name = "ks_eairdiff_mn",
  description = paste(
    "Miettinen-Nurminen score confidence interval for the difference of two",
    "incidence rates (events per person-time). Provide event counts n1/n2 and",
    "person-times T1/T2. Vectorised."
  ),
  input_schema = schema(
    properties = properties(
      n1    = property_array("n1",    "Event count(s) in group 1.",    required = TRUE),
      n2    = property_array("n2",    "Event count(s) in group 2.",    required = TRUE),
      T1    = property_array("T1",    "Person-time(s) in group 1.",   required = TRUE),
      T2    = property_array("T2",    "Person-time(s) in group 2.",   required = TRUE),
      alpha = property_number("alpha", "Significance level (default 0.05).", required = FALSE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_eairdiff_mn(
        as_num(params$n1), as_num(params$n2),
        as_num(params$T1), as_num(params$T2),
        alpha = if (!is.null(params$alpha)) as.numeric(params$alpha) else 0.05
      )
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_median_ci
# ---------------------------------------------------------------------------

tool_median_ci <- new_tool(
  name = "ks_median_ci",
  description = paste(
    "Compute the sample median with a confidence interval.",
    "Method 'boot' (default): bootstrap resampling.",
    "Method 'olive': exact order-statistic interval.",
    "Method 'z': large-sample normal approximation."
  ),
  input_schema = schema(
    properties = properties(
      x      = property_array("x",      "Numeric vector of observations.",               required = TRUE),
      method = property_enum("method",   "CI method.",
                             values = c("boot", "olive", "z"), required = FALSE),
      alpha  = property_number("alpha",  "Significance level (default 0.05).",             required = FALSE),
      R      = property_integer("R",     "Bootstrap replicates for method='boot' (default 10000).", required = FALSE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_median_ci(
        as_num(params$x),
        method = if (!is.null(params$method)) params$method else "boot",
        alpha  = if (!is.null(params$alpha))  as.numeric(params$alpha) else 0.05,
        R      = if (!is.null(params$R))      as_int(params$R) else 10000L
      )
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_geom_mean
# ---------------------------------------------------------------------------

tool_geom_mean <- new_tool(
  name = "ks_geom_mean",
  description = paste(
    "Compute the geometric mean with a bootstrap confidence interval.",
    "All values in x should be positive (or zero when zero_propagate=true)."
  ),
  input_schema = schema(
    properties = properties(
      x              = property_array("x",             "Numeric vector of positive values.", required = TRUE),
      na_rm          = property_boolean("na_rm",        "Remove NAs before computing (default TRUE).",              required = FALSE),
      zero_propagate = property_boolean("zero_propagate",
        "Return 0 when any x = 0, rather than -Inf (default FALSE).", required = FALSE),
      alpha          = property_number("alpha",          "Significance level (default 0.05).", required = FALSE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_geom_mean(
        as_num(params$x),
        na.rm          = if (!is.null(params$na_rm))          as.logical(params$na_rm)          else TRUE,
        zero.propagate = if (!is.null(params$zero_propagate)) as.logical(params$zero_propagate) else FALSE,
        alpha          = if (!is.null(params$alpha))          as.numeric(params$alpha)          else 0.05
      )
      response_text(fmt(res))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Tool: ks_n_pct
# ---------------------------------------------------------------------------

tool_n_pct <- new_tool(
  name = "ks_n_pct",
  description = paste(
    "Format n (%) for clinical reporting.",
    "Pass scalar n and total for a single cell, or two arrays of equal length",
    "for multiple cells at once."
  ),
  input_schema = schema(
    properties = properties(
      n      = property_array("n",      "Count(s) of events.",    required = TRUE),
      totals = property_array("totals", "Denominator(s).",         required = TRUE)
    )
  ),
  handler = function(params) {
    tryCatch({
      res <- ks_n_pct(as_num(params$n), as_num(params$totals))
      response_text(paste(res, collapse = "\n"))
    }, error = function(e) response_text(paste("Error:", conditionMessage(e))))
  }
)

# ---------------------------------------------------------------------------
# Server
# ---------------------------------------------------------------------------

mcp <- new_server(
  name        = "kstools",
  description = paste(
    "Clinical and data science utilities from the kstools R package.",
    "Provides: Rubin MI pooling, Newcombe proportion CIs (plain and stratified),",
    "Miettinen-Nurminen incidence-rate difference CI, median CI, geometric mean,",
    "and clinical n (%) formatter."
  ),
  version = as.character(utils::packageVersion("kstools"))
)

mcp <- add_capability(mcp, tool_mianalyze)
mcp <- add_capability(mcp, tool_newcombe_hs)
mcp <- add_capability(mcp, tool_newcombe_hs_strata)
mcp <- add_capability(mcp, tool_eairdiff_mn)
mcp <- add_capability(mcp, tool_median_ci)
mcp <- add_capability(mcp, tool_geom_mean)
mcp <- add_capability(mcp, tool_n_pct)

# ---------------------------------------------------------------------------
# Transport
# ---------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
if ("--http" %in% args) {
  port <- 3131L
  cat(sprintf("Starting kstools MCP server on http://localhost:%d\n", port))
  serve_http(mcp, port = port)
} else {
  serve_io(mcp)
}
