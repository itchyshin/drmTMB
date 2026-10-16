# sweep-oct16 / t4: DRModels.jl fitter. One row per dataset -> results/fits_DRModels.csv
# Usage: julia --project=<DRModels.jl checkout> t4_fit_DRModels.jl [data_dir] [out_csv]
using DRModels, Logging, Test, LinearAlgebra, Printf, InteractiveUtils
import DRModels: DrmFit

const DDIR = length(ARGS) >= 1 ? ARGS[1] : "sweep-oct16/t4/data"
const OUT  = length(ARGS) >= 2 ? ARGS[2] : "sweep-oct16/t4/results/fits_DRModels.csv"

# minimal reader for R write.csv output (quoted header, unquoted numeric/strings)
function read_rcsv(path)
    ls = readlines(path)
    hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [String[] for _ in hdr]
    for l in ls[2:end]
        isempty(l) && continue
        for (j, v) in enumerate(split(l, ',')); push!(cols[j], strip(v, '"')); end
    end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
num(v) = parse.(Float64, v)

function t4_call(cell, d)
    y = num(d[:y]); x = num(d[:x])
    c = replace(cell, r"_n[0-9]+(_lowmean)?$" => "")
    if c == "gauss"
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
    elseif c == "pois"
        drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x))
    elseif c in ("bin_complete", "bin_quasi")
        drm(bf(@formula(y ~ 1 + x)), Binomial(); data = (; y, x))
    elseif c == "nb2_poisdata"
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), NegBinomial2(); data = (; y, x))
    elseif c == "beta_phi1e4"
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Beta(); data = (; y, x))
    elseif c == "student_gaussdata"
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1), @formula(nu ~ 1)), Student(); data = (; y, x))
    elseif c == "re_sd1e-4"
        g = string.("g", d[:g])
        drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data = (; y, x, g))
    elseif c in ("collin_sigma_exact", "collin_sigma_near")
        z = num(d[:z])
        drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x + z)), Gaussian(); data = (; y, x, z))
    else
        error("unknown cell $cell")
    end
end

clean(s) = replace(replace(string(s), '\n' => ' '), '"' => '\'')
fmt(v) = v isa AbstractFloat ? @sprintf("%.10g", v) : string(v)

function probe(thunk)
    logger = Test.TestLogger(min_level = Logging.Warn)
    fit = nothing; err = ""
    t = @elapsed try
        fit = with_logger(thunk, logger)
    catch e
        err = clean(sprint(showerror, e))
    end
    warns = unique([first(clean(r.message), 240) * (isempty(r.kwargs) ? "" : " " * clean(Dict(pairs(r.kwargs)))) for r in logger.logs])
    row = Dict{String,Any}("fitted" => fit isa DrmFit, "error" => err, "secs" => t,
                           "warnings" => join(warns, " || "), "n_warn" => length(warns))
    fit isa DrmFit || return row
    names = String[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames); append!(names, string.(p, ":", nms)); end
    se = try stderror(fit) catch; fill(NaN, length(fit.theta)) end
    cf = coef(fit)
    resd = any(p -> first(p) in (:resd, :recov), fit.blocks) ? (try re_sd(fit) catch; nothing end) : nothing
    clog = Test.TestLogger(min_level = Logging.Warn)
    chk = try with_logger(() -> check_drm(fit), clog) catch e; nothing end
    chkw = unique([first(clean(r.message), 160) for r in clog.logs])
    fe = [!startswith(n, "resd") for n in names]   # SE counts over fixed effects only (R's vcov excludes RE SD)
    sefe = se[fe]
    merge!(row, Dict{String,Any}(
        "converged_raw" => fit.converged, "converged" => is_converged(fit),
        "logLik" => loglik(fit), "niter" => (try niterations(fit) catch; missing end),
        "marginal" => string(fit.marginal), "estim_method" => string(fit.estim_method),
        "coef" => join([n * "=" * fmt(v) for (n, v) in zip(names, cf)], ";"),
        "se" => join([n * "=" * @sprintf("%.6g", v) for (n, v) in zip(names, se)], ";"),
        "n_se" => length(sefe), "n_se_nonfinite" => count(!isfinite, sefe),
        "max_se" => (any(isfinite, sefe) ? maximum(sefe[isfinite.(sefe)]) : NaN),
        "vcov_all_finite" => all(isfinite, fit.vcov),
        "re_sd" => resd === nothing ? NaN : first(values(resd)),
        "re_sd_se" => (r = findfirst(startswith("resd"), names); r === nothing ? NaN : se[r]),
        "check_ok" => chk === nothing ? missing : chk.ok,
        "check_max_abs_grad" => chk === nothing ? missing : chk.max_abs_grad,
        "check_vcov_posdef" => chk === nothing ? missing : chk.vcov_posdef,
        "check_min_eigval" => chk === nothing ? missing : chk.min_eigval,
        "check_variance_boundary" => chk === nothing ? "" : clean(chk.variance_boundary),
        "check_warnings" => join(chkw, " || ")))
    row
end

const COLS = ["k", "cell", "rep", "nominal_seed", "r_seed", "file", "n", "fitted", "error", "secs",
              "converged_raw", "converged", "logLik", "niter", "marginal", "estim_method", "coef", "se",
              "n_se", "n_se_nonfinite", "max_se", "vcov_all_finite", "re_sd", "re_sd_se", "check_ok",
              "check_max_abs_grad", "check_vcov_posdef", "check_min_eigval", "check_variance_boundary",
              "check_warnings", "warnings", "n_warn"]
csvq(v) = v === missing || v === nothing ? "NA" : (v isa AbstractString ? "\"" * replace(v, '"' => "'") * "\"" : fmt(v))

function main()
    idx = read_rcsv(joinpath(DDIR, "index.csv"))
    nrow = length(idx[:file])
    mkpath(dirname(OUT))
    open(OUT, "w") do io
        println(io, join(["\"$c\"" for c in COLS], ","))
        for i in 1:nrow
            cell = idx[:cell][i]; f = idx[:file][i]
            d = read_rcsv(joinpath(DDIR, f))
            row = probe(() -> t4_call(cell, d))
            row["k"] = parse(Int, idx[:k][i]); row["cell"] = cell; row["rep"] = parse(Int, idx[:rep][i])
            row["nominal_seed"] = idx[:nominal_seed][i]; row["r_seed"] = idx[:r_seed][i]
            row["file"] = f; row["n"] = parse(Int, idx[:n][i])
            println(io, join([csvq(get(row, c, missing)) for c in COLS], ","))
            flush(io)
            i % 50 == 0 && println(stderr, "$(i) of $(nrow)")
        end
    end
    open(replace(OUT, ".csv" => "_versioninfo.txt"), "w") do io
        versioninfo(io; verbose = false)
        println(io, "DRModels ", pkgversion(DRModels), " at ", pathof(DRModels))
        println(io, "DRModels git HEAD: ", strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
        println(io, "Threads: ", Threads.nthreads(), "  BLAS threads: ", BLAS.get_num_threads())
    end
end
main()
