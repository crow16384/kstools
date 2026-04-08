test_that("ks_williams validates treatment-name length", {
  expect_error(
    ks_williams(tmts_num = 3, tmt_names = c("A", "B"), sample_size = 18),
    regexp = "length"
  )
})


test_that("ks_williams returns 3-sequence design for odd number of treatments", {
  out <- ks_williams(
    tmts_num = 3,
    tmt_names = c("TestDrg", "ActCtrl", "Placebo"),
    sample_size = 18,
    seed_num = 123
  )

  expect_true(is.list(out))
  expect_equal(ncol(out$design), 4L)
  expect_equal(nrow(out$design), 6L)
  expect_equal(out$n_sequences, 6L)
  expect_equal(nrow(out$schedule), 18L)
  expect_false(out$sample_size_warning)
})


test_that("ks_williams returns 4-sequence design for even number of treatments", {
  out <- ks_williams(
    tmts_num = 4,
    tmt_names = c("Drug1A", "Drug2B", "ActCtrl", "Placebo"),
    sample_size = 24,
    seed_num = 123
  )

  expect_equal(nrow(out$design), 4L)
  expect_equal(out$n_sequences, 4L)
  expect_equal(nrow(out$schedule), 24L)
  expect_false(out$sample_size_warning)
})


test_that("ks_williams warns and truncates to full blocks when sample size mismatches", {
  expect_warning(
    out <- ks_williams(
      tmts_num = 4,
      tmt_names = c("A", "B", "C", "D"),
      sample_size = 22,
      seed_num = 1
    ),
    regexp = "not a multiple"
  )

  expect_true(out$sample_size_warning)
  expect_equal(nrow(out$schedule), 20L)
})


test_that("ks_williams auto-seed is reported", {
  out <- ks_williams(
    tmts_num = 3,
    tmt_names = c("A", "B", "C"),
    sample_size = 6
  )

  expect_true(isTRUE(out$seed_generated))
  expect_true(is.numeric(out$seed))
})
