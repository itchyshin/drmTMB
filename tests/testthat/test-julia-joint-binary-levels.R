test_that('joint Julia numeric binary levels use the fitted encoding', {
  encode <- function(x, levels) drmTMB:::drm_julia_joint_binary_data(data.frame(x = x), 'x', levels)$x
  expect_equal(encode(c(1, 2, NA_real_), c('1', '2')), c(0, 1, NA_real_))
  expect_equal(encode(1, c('1', '2')), 0)
  expect_equal(encode(c(2, 3), c('2', '3')), c(0, 1))
  expect_error(encode(0, c('1', '2')), 'binary|level')
  expect_equal(encode(factor(c('2','1'), levels=c('2','1')), c('1','2')), c(1,0))
  expect_equal(encode(c(0,1,NA_real_), c('absent','present')), c(0,1,NA_real_))
  expect_equal(encode(c(FALSE,TRUE,NA), c('FALSE','TRUE')), c(0,1,NA_real_))
  expect_error(encode(c(0,Inf), c('0','1')), 'finite')
  expect_error(encode('other', c('absent','present')), 'level')
})

test_that('numeric-looking distinct binary labels are not silently collapsed', {
  encode <- function(x) drmTMB:::drm_julia_joint_binary_data(data.frame(x=x), 'x', c('01','1'))$x
  expect_error(encode(1), 'ambiguous|numeric|distinct')
  expect_equal(encode(c('01','1')), c(0,1))
  expect_equal(encode(factor(c('1','01'),levels=c('1','01'))),c(1,0))
})
