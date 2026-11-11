test_that("conditional Julia bridge rejects duplicated SD-v2 terms before fitting", {
  skip_if_not(identical(Sys.getenv("DRM_PRIOR_V2_LIVE"), "1"))
  skip_if_not_installed("JuliaCall")
  drm_julia_setup()
  if (exists("drm_julia_bridge_summary_record_live", mode = "function")) {
    drm_julia_bridge_summary_record_live()
  }

  # Keep the actual generated conditional entrypoint and backend parsing, but
  # replace its final fit call with a counter and sentinel. This shows where
  # the refusal occurs without relying on optimizer behavior.
  JuliaCall::julia_command('
    module SDV2DuplicateFitSpy
    using DRModels
    const Gaussian = DRModels.Gaussian
    const _bridge_data = DRModels._bridge_data
    const _bridge_options = DRModels._bridge_options
    const _bridge_prior_safe_options = DRModels._bridge_prior_safe_options
    const _bridge_prior_contract = DRModels._bridge_prior_contract
    const _bridge_formula = DRModels._bridge_formula
    const _bridge_family = DRModels._bridge_family
    const _bridge_enable_priors_v2! = DRModels._bridge_enable_priors_v2!
    const _bridge_prepare_fixed_priors = DRModels._bridge_prepare_fixed_priors
    const _bridge_tree = DRModels._bridge_tree
    const fits = Ref(0)
    _bridge_fit(args...; kwargs...) = (fits[] += 1; error("FIT_SPY_REACHED"))
    end
  ')
  src <- drm_julia_conditional_gaussian_components_source()
  src <- gsub("drmTMB_backend", "SDV2DuplicateFitSpy", src, fixed = TRUE)
  src <- gsub("drmTMB_drm_bridge_conditional_gaussian_components", "sdv2_duplicate_spy_components", src, fixed = TRUE)
  src <- gsub("drmTMB_drm_bridge_conditional_gaussian_ri", "sdv2_duplicate_spy_ri", src, fixed = TRUE)
  JuliaCall::julia_command(src)
  JuliaCall::julia_command('
    begin
    sdv2_spy_data = (y=[1.,1.4,2.3,2.8,2.1,2.6,3.2,3.4,4.3],
      x=[-1.,0.,1.,-1.,0.,1.,-1.,0.,1.], site=repeat(["a","b","c"], inner=3))
    sdv2_spy_prior = Dict("kind"=>"ranef_sd_gamma", "dpar"=>"mu", "group"=>"site",
      "coef"=>"(Intercept)", "block_kind"=>"iid_random_intercept", "shape"=>2., "rate"=>3., "measure"=>"natural_sd")
    sdv2_spy_row = merge(sdv2_spy_prior, Dict("spec_index"=>1, "class"=>"ranef_sd"))
    sdv2_spy_opts = Dict("prior_contract"=>"parameter_priors_v2", "priors_v2"=>[sdv2_spy_prior],
      "prior_expected_v2"=>[sdv2_spy_row])
    sdv2_spy_duplicate = Dict("mu"=>"y ~ x + (1|site) + (1|site)", "sigma"=>"sigma ~ 1")
    sdv2_spy_exponent = Dict("mu"=>"y ~ x + (1|site)^2", "sigma"=>"sigma ~ 1")
    sdv2_spy_single = Dict("mu"=>"y ~ x + (1|site)", "sigma"=>"sigma ~ 1")
    sdv2_spy_v1 = Dict("priors"=>[Dict("kind"=>"normal", "dpar"=>"mu", "coef"=>"x", "mean"=>0., "sd"=>2.)],
      "prior_expected"=>[Dict("dpar"=>"mu", "coef"=>"x")])
    sdv2_spy_message(formula, options) = try
      sdv2_duplicate_spy_components(formula, "gaussian", sdv2_spy_data, nothing, options)
      "accepted"
    catch err
      sprint(showerror, err)
    end
    end
  ')

  msg <- JuliaCall::julia_eval("sdv2_spy_message(sdv2_spy_duplicate, sdv2_spy_opts)")
  expect_match(msg, "duplicated random intercept")
  expect_equal(JuliaCall::julia_eval("SDV2DuplicateFitSpy.fits[]"), 0)
  msg <- JuliaCall::julia_eval("sdv2_spy_message(sdv2_spy_exponent, sdv2_spy_opts)")
  expect_match(msg, "random-effect algebra")
  expect_equal(JuliaCall::julia_eval("SDV2DuplicateFitSpy.fits[]"), 0)
  msg <- JuliaCall::julia_eval("sdv2_spy_message(sdv2_spy_single, sdv2_spy_opts)")
  expect_match(msg, "FIT_SPY_REACHED")
  expect_equal(JuliaCall::julia_eval("SDV2DuplicateFitSpy.fits[]"), 1)
  msg <- JuliaCall::julia_eval("sdv2_spy_message(sdv2_spy_duplicate, sdv2_spy_v1)")
  expect_match(msg, "FIT_SPY_REACHED")
  expect_equal(JuliaCall::julia_eval("SDV2DuplicateFitSpy.fits[]"), 2)
  msg <- JuliaCall::julia_eval("sdv2_spy_message(sdv2_spy_duplicate, Dict())")
  expect_match(msg, "FIT_SPY_REACHED")
  expect_equal(JuliaCall::julia_eval("SDV2DuplicateFitSpy.fits[]"), 3)
})
