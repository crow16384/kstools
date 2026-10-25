# Build a randomized Williams cross-over design and schedule

R analogue of the SAS `WILLIAMS` macro. The function constructs a
Williams design from a randomized cyclic Latin square and generates a
block-randomized subject schedule.

## Usage

``` r
ks_williams(tmts_num, tmt_names, sample_size, out_rtf = NULL, seed_num = NULL)
```

## Arguments

- tmts_num:

  Integer number of treatments.

- tmt_names:

  Character vector of treatment labels (length must equal `tmts_num`).

- sample_size:

  Integer target number of subjects.

- out_rtf:

  Optional output file path. If provided, a simple RTF report with
  design and randomization schedule tables is written.

- seed_num:

  Optional integer seed. If `NULL`, current system time is used.

## Value

A list with:

- design:

  Data frame of Williams sequences by period.

- schedule:

  Data frame of randomized subject assignments.

- seed:

  Seed used.

- seed_generated:

  Logical; `TRUE` when seed was auto-generated.

- n_sequences:

  Number of unique sequences.

- block_num:

  Number of full randomization blocks used.

- sample_size_warning:

  Logical; `TRUE` when `sample_size` is not a multiple of `n_sequences`.
