## Regression test for whitespace validation in treatment names.
## The earlier regex was double-escaped ("\\\\s") which only matched a
## literal "\s"; this test guards the fix to "\\s" (any whitespace).

test_that("ks_williams rejects treatment names containing whitespace", {
  expect_error(
    ks_williams(
      tmts_num    = 3,
      tmt_names   = c("A", "B C", "D"),
      sample_size = 6,
      seed_num    = 1
    ),
    "non-empty word"
  )
  expect_error(
    ks_williams(
      tmts_num    = 2,
      tmt_names   = c("A", "B\tC"),
      sample_size = 4,
      seed_num    = 1
    ),
    "non-empty word"
  )
})
