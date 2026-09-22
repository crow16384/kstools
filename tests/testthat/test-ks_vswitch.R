test_that("basic vectorized lookup", {
  expect_equal(ks_vswitch(c("a", "b", "a", NA, "zz"), a = 10L, b = 20L),
               c(10L, 20L, 10L, NA_integer_, NA_integer_))
})

test_that(".na and .default overrides", {
  expect_equal(ks_vswitch(c("a", "b", NA, "zz"), a = 10L, b = 20L,
                          .na = 0L, .default = -1L),
               c(10L, 20L, 0L, -1L))
})

test_that("factor and numeric keys", {
  expect_equal(ks_vswitch(factor(c("x", "y")), x = 1.5, y = 2.5), c(1.5, 2.5))
  expect_equal(ks_vswitch(c(1, 2), `1` = "one", `2` = "two"), c("one", "two"))
})

test_that("errors on empty or unnamed dots", {
  expect_error(ks_vswitch("a"), "named value")
  expect_error(ks_vswitch("a", 10L), "must be named")
})
