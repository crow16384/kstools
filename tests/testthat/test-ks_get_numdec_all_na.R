## Regression test: all-NA group returns NA_integer_ (not -Inf double)

test_that("ks_get_numdec returns NA_integer_ for all-NA groups", {
  d <- data.frame(
    g = c("A", "A", "B", "B"),
    val = c(NA_real_, NA_real_, 1.23, 4.5)
  )
  res <- ks_get_numdec(d, "val", "g")
  nd_A <- unique(res$NUMDEC[res$g == "A"])
  nd_B <- unique(res$NUMDEC[res$g == "B"])
  expect_true(is.na(nd_A))
  expect_type(res$NUMDEC, "integer")
  expect_equal(nd_B, 2L)
  expect_false(any(is.infinite(res$NUMDEC)))
})
