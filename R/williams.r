#' Build a randomized Williams cross-over design and schedule
#'
#' R analogue of the SAS \code{WILLIAMS} macro. The function constructs a
#' Williams design from a randomized cyclic Latin square and generates a
#' block-randomized subject schedule.
#'
#' @param tmts_num Integer number of treatments.
#' @param tmt_names Character vector of treatment labels (length must equal
#'   \code{tmts_num}).
#' @param sample_size Integer target number of subjects.
#' @param out_rtf Optional output file path. If provided, a simple RTF report
#'   with design and randomization schedule tables is written.
#' @param seed_num Optional integer seed. If \code{NULL}, current system time
#'   is used.
#'
#' @return A list with:
#' \describe{
#'   \item{design}{Data frame of Williams sequences by period.}
#'   \item{schedule}{Data frame of randomized subject assignments.}
#'   \item{seed}{Seed used.}
#'   \item{seed_generated}{Logical; \code{TRUE} when seed was auto-generated.}
#'   \item{n_sequences}{Number of unique sequences.}
#'   \item{block_num}{Number of full randomization blocks used.}
#'   \item{sample_size_warning}{Logical; \code{TRUE} when
#'     \code{sample_size} is not a multiple of \code{n_sequences}.}
#' }
#' @name ks_williams
#' @importFrom cli cli_abort cli_warn
#' @export
ks_williams <- function(tmts_num,
                        tmt_names,
                        sample_size,
                        out_rtf = NULL,
                        seed_num = NULL) {

  if (!is.numeric(tmts_num) || length(tmts_num) != 1L || is.na(tmts_num) || tmts_num < 2)
    cli::cli_abort("{.arg tmts_num} must be a single integer >= 2.")
  tmts_num <- as.integer(tmts_num)

  if (!is.character(tmt_names) || length(tmt_names) != tmts_num)
    cli::cli_abort("{.arg tmt_names} must be a character vector of length {.val tmts_num}.")
  if (anyNA(tmt_names) || any(trimws(tmt_names) == "") || any(grepl("\\s", tmt_names))) {
    cli::cli_abort("Each treatment name must be one non-empty word (no spaces).")
  }
  if (anyDuplicated(tmt_names))
    cli::cli_abort("{.arg tmt_names} must be unique.")

  if (!is.numeric(sample_size) || length(sample_size) != 1L || is.na(sample_size) || sample_size < 1)
    cli::cli_abort("{.arg sample_size} must be a single integer >= 1.")
  sample_size <- as.integer(sample_size)

  if (!is.null(out_rtf) && (!is.character(out_rtf) || length(out_rtf) != 1L || is.na(out_rtf) || !nzchar(out_rtf)))
    cli::cli_abort("{.arg out_rtf} must be NULL or a single non-empty file path.")

  seed_generated <- is.null(seed_num) || (length(seed_num) == 1L && is.na(seed_num))
  if (seed_generated) {
    seed_num <- as.integer(floor(as.numeric(Sys.time())))
  } else {
    if (!is.numeric(seed_num) || length(seed_num) != 1L || is.na(seed_num))
      cli::cli_abort("{.arg seed_num} must be NULL or a single numeric seed.")
    seed_num <- as.integer(seed_num)
  }

  old_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (is.null(old_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(".Random.seed", envir = .GlobalEnv)
      }
    } else {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    }
  }, add = TRUE)

  set.seed(seed_num)

  base <- sample.int(tmts_num)
  sq <- t(vapply(seq_len(tmts_num), function(shift) {
    base[((seq_len(tmts_num) + shift - 2L) %% tmts_num) + 1L]
  }, FUN.VALUE = integer(tmts_num)))
  colnames(sq) <- paste0("Period", seq_len(tmts_num))

  sq_mirror <- sq[, tmts_num:1, drop = FALSE]

  interlaced <- matrix(NA_integer_, nrow = tmts_num, ncol = 2L * tmts_num)
  interlaced[, seq(1L, 2L * tmts_num - 1L, by = 2L)] <- sq
  interlaced[, seq(2L, 2L * tmts_num, by = 2L)] <- sq_mirror

  if (tmts_num %% 2L == 0L) {
    design_num <- interlaced[, seq_len(tmts_num), drop = FALSE]
  } else {
    design_a <- interlaced[, seq_len(tmts_num), drop = FALSE]
    design_b <- interlaced[, tmts_num + seq_len(tmts_num), drop = FALSE]
    design_num <- rbind(design_a, design_b)
  }

  design <- as.data.frame(design_num, stringsAsFactors = FALSE)
  names(design) <- paste0("Period", seq_len(tmts_num))
  design <- cbind(SeqNo = seq_len(nrow(design)), design)

  period_cols <- paste0("Period", seq_len(tmts_num))
  for (nm in period_cols) {
    design[[nm]] <- tmt_names[design[[nm]]]
  }

  design$Sequence <- apply(design[, period_cols, drop = FALSE], 1L, paste, collapse = "--")

  seq_labels <- design$Sequence
  n_sequences <- length(seq_labels)
  block_num <- sample_size %/% n_sequences

  if (block_num == 0L) {
    schedule <- data.frame(
      Sub_ID = integer(0L),
      Sequence = character(0L),
      stringsAsFactors = FALSE
    )
  } else {
    assignments <- unlist(lapply(seq_len(block_num), function(i) sample(seq_labels, size = n_sequences, replace = FALSE)), use.names = FALSE)
    schedule <- data.frame(
      Sub_ID = seq_along(assignments),
      Sequence = assignments,
      stringsAsFactors = FALSE
    )
  }

  sample_size_warning <- (sample_size %% n_sequences) != 0L
  if (sample_size_warning) {
    cli::cli_warn(c(
      "Sample size ({sample_size}) is not a multiple of the number of sequences ({n_sequences}).",
      "i" = "Generated schedule contains {.val {nrow(schedule)}} subjects (full blocks only)."
    ))
  }

  out <- list(
    design = design[, c("SeqNo", period_cols), drop = FALSE],
    schedule = schedule,
    seed = seed_num,
    seed_generated = seed_generated,
    n_sequences = n_sequences,
    block_num = block_num,
    sample_size_warning = sample_size_warning
  )

  if (!is.null(out_rtf)) {
    .ks_write_williams_rtf(out = out, tmts_num = tmts_num, out_rtf = out_rtf)
  }

  out
}


.ks_write_williams_rtf <- function(out, tmts_num, out_rtf) {
  esc <- function(x) {
    x <- gsub("\\\\", "\\\\\\\\", x, fixed = TRUE)
    x <- gsub("\\{", "\\\\{", x)
    gsub("\\}", "\\\\}", x)
  }

  design <- out$design
  sched <- out$schedule

  design_header <- c("SeqNo", paste0("Period", seq_len(tmts_num)))
  design_rows <- apply(design, 1L, function(r) paste(r, collapse = "\\tab "))

  if (nrow(sched) > 0L) {
    sched_rows <- apply(sched, 1L, function(r) paste(r, collapse = "\\tab "))
  } else {
    sched_rows <- "(no full randomization blocks for requested sample size)"
  }

  lines <- c(
    "{\\rtf1\\ansi",
    "\\b A Williams Design for the Cross-over Trial\\b0\\par",
    paste0("The number of treatments in this trial = ", tmts_num, ".\\par"),
    paste0("The random seed number = ", out$seed, ".\\par"),
    if (out$seed_generated) "Seed number is generated automatically.\\par" else "The seed number is specified by the user.\\par",
    "\\par",
    "\\b Williams Design\\b0\\par",
    paste(esc(design_header), collapse = "\\tab "), "\\par",
    paste0(esc(design_rows), "\\par"),
    "\\par",
    "\\b Randomization Schedule\\b0\\par",
    "Sub_ID\\tab Sequence\\par",
    paste0(esc(sched_rows), "\\par"),
    "}"
  )

  writeLines(lines, con = out_rtf, useBytes = TRUE)
}
