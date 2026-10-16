# Comment intended for https://github.com/itchyshin/DRModels.jl/issues/1027

GitHub write 403 from this cloud task. Refs #1027.

t7: `drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + offset(off))), Poisson(); data=d)` at f71b292 **fits** as a two-mean-parameter Poisson (θ1, θ2). Shifting `off` by log(2) does not move the intercept (delta 0). No warning. drmTMB at ca3ddef refuses the same formula (Poisson has no sigma). Same swallow as this issue; the offset inside the extra dpar is what t7 measured.
