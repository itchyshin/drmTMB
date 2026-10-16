# Standalone confirmation of t6 predict-scale mismatches (DRModels.jl pin f71b292).
# Run: julia --project=/home/ubuntu/jlsim confirm_predict_invlinks.jl
using DRModels, DelimitedFiles
root = get(ENV, "T6_ROOT", "/workspace/sweep-oct16/t6")

function read_cell(cell)
    raw, hdr = readdlm(joinpath(root, "data", cell * ".csv"), ','; header = true)
    cols = Dict(String(h) => j for (j, h) in enumerate(vec(hdr)))
    return (
        y = Float64.(raw[:, cols["y"]]),
        x = Float64.(raw[:, cols["x"]]),
        f = string.(raw[:, cols["f"]]),
        g = string.(raw[:, cols["g"]]),
    )
end
nd = (x = [-0.5, 0.0, 0.5], f = ["a", "b", "c"])

# 1. lognormal: Julia applies exp to mu
dat = read_cell("lognormal_fe")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1)), LogNormal(); data = dat)
pp_r = predict_parameters(fit, nd; type = :response)
pp_l = predict_parameters(fit, nd; type = :link)
println("lognormal mu response=", pp_r[:mu])
println("lognormal mu link=", pp_l[:mu])
println("exp(link)=", exp.(pp_l[:mu]))

# 2. student nu: Julia returns exp(η) = ν-2, not 2+exp(η)
dat = read_cell("student_fe")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1), @formula(nu ~ 1)), Student(); data = dat)
pp_r = predict_parameters(fit, nd; type = :response)
pp_l = predict_parameters(fit, nd; type = :link)
println("student nu response=", unique(pp_r[:nu]))
println("student nu link=", unique(pp_l[:nu]))
println("exp(link)=", unique(exp.(pp_l[:nu])))
println("2+exp(link)=", unique(2 .+ exp.(pp_l[:nu])))
println("fit.scales[:nu][1]=", fit.scales[:nu][1])

# 3. skew_normal nu: Julia exp(η); drmTMB identity
dat = read_cell("skew_normal_fe")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1), @formula(nu ~ 1)), SkewNormal(); data = dat)
pp_r = predict_parameters(fit, nd; type = :response)
pp_l = predict_parameters(fit, nd; type = :link)
println("skew nu response=", unique(pp_r[:nu]))
println("skew nu link=", unique(pp_l[:nu]))
println("exp(link)=", unique(exp.(pp_l[:nu])))

# 4. ZeroOneBeta mu: Julia returns η, not logistic(η)
dat = read_cell("zero_one_beta_fe")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1), @formula(zoi ~ 1), @formula(coi ~ 1)),
          ZeroOneBeta(); data = dat)
pp_r = predict_parameters(fit, nd; type = :response)
pp_l = predict_parameters(fit, nd; type = :link)
println("zobeta mu response=", pp_r[:mu])
println("zobeta mu link=", pp_l[:mu])
println("logistic(link)=", 1 ./ (1 .+ exp.(-pp_l[:mu])))

# 5. simulate has no newdata; subset factor levels
dat = read_cell("gaussian_fe")
fit = drm(bf(@formula(y ~ x + f), @formula(sigma ~ 1)), Gaussian(); data = dat)
println("simulate methods: ", methods(simulate))
nd_sub = (x = [-0.5, 0.5], f = ["a", "c"])
try
    println("subset levels predict=", predict(fit, nd_sub))
catch e
    println("subset levels error: ", sprint(showerror, e))
end
nd_z = (x = [0.0], f = ["z"])
try
    println("unseen z predict=", predict(fit, nd_z))
catch e
    println("unseen z error: ", sprint(showerror, e))
end

println("\n----- versioninfo -----")
versioninfo()
println("DRModels SHA expected: f71b2923360e9e5d4591e0d6e15a9ef9db0356d7")
