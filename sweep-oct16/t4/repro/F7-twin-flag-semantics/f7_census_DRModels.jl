# F7-twin-flag-semantics (DRModels.jl side): refit cells 1-14 of the t4 grid and record what
# is_converged() is made of at the pin, plus what drmTMB's "degenerate" rule (R/check.R:307-367
# at ca3ddefa) would say if it were applied to the SAME Julia fit. Independent of the lane harness.
#   cd sweep-oct16/t4/repro/F7-twin-flag-semantics && JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia \
#     /home/user/jlenv/bin/julia --project=/home/user/DRModels.jl f7_census_DRModels.jl > f7_census_DRModels.out 2>&1
using DRModels, LinearAlgebra, Printf, Logging, Test, Statistics, InteractiveUtils
versioninfo()
println("DRModels ", pkgversion(DRModels), " at ", pathof(DRModels), "\ngit HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [Float64[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], parse(Float64, strip(v, '"'))); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
const DDIR = joinpath(@__DIR__, "..", "..", "data")   # cells not committed regenerate with ../../t4_gen_data.R
const CELLS = ["gauss_n8", "gauss_n12", "gauss_n20", "pois_n8", "pois_n12", "pois_n20", "bin_complete",
               "bin_quasi", "nb2_poisdata", "beta_phi1e4", "student_gaussdata", "re_sd1e-4",
               "collin_sigma_exact", "collin_sigma_near"]
function fit_cell(cell, d)
    y = d[:y]; x = d[:x]; c = replace(cell, r"_n[0-9]+$" => "")
    c == "gauss" && return drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
    c == "pois" && return drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x))
    c in ("bin_complete", "bin_quasi") && return drm(bf(@formula(y ~ 1 + x)), Binomial(); data = (; y, x))
    c == "nb2_poisdata" && return drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = (; y, x))
    c == "beta_phi1e4" && return drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Beta(); data = (; y, x))
    c == "student_gaussdata" && return drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1), @formula(nu ~ 1)), Student(); data = (; y, x))
    c == "re_sd1e-4" && return drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                                  data = (; y, x, g = string.("g", Int.(d[:g]))))
    z = d[:z]
    return drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; y, x, z))
end
# drmTMB's degenerate predicates (R/check.R at ca3ddefa), applied to the Julia fit:
#  pdHess-like: full covariance finite and positive definite; finite SEs over the fixed effects;
#  inflated SE (check.R:1321-1352): SE >= 50 and >= 1000 x median of the SEs below 50 (min SE if none).
function r_rule(fit)
    V = fit.vcov
    names = String[]; for ((p, _), (_, nms)) in zip(fit.blocks, fit.coefnames); append!(names, string.(p, ":", nms)); end
    fe = [!startswith(n, "resd") for n in names]
    pd = all(isfinite, V) && isposdef(Symmetric(V))
    v = diag(V)[fe]; se = [isfinite(a) && a >= 0 ? sqrt(a) : NaN for a in v]
    se_finite = all(isfinite, se)
    fs = filter(isfinite, se)
    infl = false
    if !isempty(fs)
        ref = filter(<(50), fs); med = isempty(ref) ? minimum(fs) : median(ref)
        infl = any(s -> isfinite(s) && s >= 50 && s >= 1000 * med, se)
    end
    (; pd, se_finite, infl)
end
out = open(joinpath(@__DIR__, "f7_census_DRModels.csv"), "w")
println(out, "cell,rep,error,converged_raw,nondegenerate,is_converged,check_ok,vcov_posdef,fit_warning,r_pd,r_se_finite,r_inflated,loglik")
nerr = 0
for cell in CELLS, r in 1:50
    f = joinpath(DDIR, @sprintf("%s_r%02d.csv", cell, r))
    isfile(f) || error("missing $f: regenerate with Rscript ../../t4_gen_data.R ../../data")
    d = read_rcsv(f)
    lg = Test.TestLogger(min_level = Logging.Warn)
    fit = try with_logger(() -> fit_cell(cell, d), lg) catch e; e end
    if !(fit isa DRModels.DrmFit)
        global nerr += 1; println(out, cell, ",", r, ",\"", replace(sprint(showerror, fit), r"[\n\",]" => " "), "\",,,,,,,,,,"); continue
    end
    chk = with_logger(() -> check_drm(fit), NullLogger())
    rr = r_rule(fit)
    println(out, join(Any[cell, r, "", fit.converged, DRModels._nondegenerate_fit(fit), is_converged(fit), chk.ok,
                          chk.vcov_posdef, !isempty(lg.logs), rr.pd, rr.se_finite, rr.infl, @sprintf("%.10g", fit.loglik)], ","))
end
close(out)
println("fits: ", 50 * length(CELLS), "  errors: ", nerr, "  -> f7_census_DRModels.csv")
