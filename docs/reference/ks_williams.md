# Build a randomized Williams cross-over design and schedule

R analogue of the SAS \codeWILLIAMS macro. The function constructs a
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

  Character vector of treatment labels (length must equal
  \codetmts_num).

- sample_size:

  Integer target number of subjects.

- out_rtf:

  Optional output file path. If provided, a simple RTF report with
  design and randomization schedule tables is written.

- seed_num:

  Optional integer seed. If \codeNULL, current system time is used.

## Value

A list with: \describe \itemdesignData frame of Williams sequences by
period. \itemscheduleData frame of randomized subject assignments.
\itemseedSeed used. \itemseed_generatedLogical; \codeTRUE when seed was
auto-generated. \itemn_sequencesNumber of unique sequences.
\itemblock_numNumber of full randomization blocks used.
\itemsample_size_warningLogical; \codeTRUE when \codesample_size is not
a multiple of \coden_sequences.
