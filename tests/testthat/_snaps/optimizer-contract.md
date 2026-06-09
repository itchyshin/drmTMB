# default optimizer errors retry larger nlminb presets

    Code
      result <- drmTMB:::drm_optimize_with_preset_retry(obj, drm_control(),
      optimizer = optimizer)
    Condition
      Warning:
      `drmTMB()` retried `stats::nlminb()` after an optimizer error.
      i The selected optimizer preset is "careful".
      i Inspect `fit$optimizer_attempts` before interpreting the fit.

# custom optimizer controls do not enter the preset retry ladder

    Code
      drmTMB:::drm_optimize_with_preset_retry(obj, drm_control(optimizer = list(
        eval.max = 10L)), optimizer = optimizer)
    Condition
      Error in `optimizer()`:
      ! NA/NaN gradient evaluation

# preset retry reports failure after all larger presets fail

    Code
      drmTMB:::drm_optimize_with_preset_retry(obj, drm_control(), optimizer = optimizer)
    Condition
      Error in `drmTMB:::drm_optimize_with_preset_retry()`:
      ! `drmTMB()` failed in all `stats::nlminb()` optimizer preset attempts.
      i Attempted presets: "default", "careful", and "robust".
      i Inspect model structure, starting values, and data scale before increasing optimizer complexity.
      Caused by error in `optimizer()`:
      ! NA/NaN gradient evaluation

