# Fit every t2 dataset with DRModels.jl and record estimates, Wald intervals and
# convergence diagnostics, in the same long format as t2_fit_drmTMB.R.
#
# Usage: julia --project=<env with DRModels dev'd> t2_fit_DRModels.jl \
#            <datadir> <outdir> <cell> [rep_from rep_to]
# The datasets are the R-generated CSVs (t2_gen_data.R), so both engines fit
# byte-identical data.

using DRModels, DelimitedFiles, Printf, LinearAlgebra, Statistics

const TRUTH = Dict("mu_intercept" => 1.0, "mu_x" => 0.5,
                   "sigma_intercept" => -0.5, "sigma_z" => 0.4, "sd_g" => 0.5)

function read_cell(path)
    raw, hdr = readdlm(path, ','; header = true)
    cols = Dict(String(h) => j for (j, h) in enumerate(vec(hdr)))
    getc(n) = Float64.(raw[:, cols[n]])
    return (rep = Int.(getc("rep")), y = getc("y"), x = getc("x"), z = getc("z"),
            g = Int.(getc("g")))
end

# DRModels coefficient (param block, coef name) -> t2 parameter name.
function map_param(p::Symbol, nm::AbstractString)
    p === :mu && nm == "(Intercept)" && return "mu_intercept"
    p === :mu && nm == "x" && return "mu_x"
    p === :sigma && nm == "(Intercept)" && return "sigma_intercept"
    p === :sigma && nm == "z" && return "sigma_z"
    p in (:resd, :resd_mu, :re_sd) && return "sd_g"
    return ""
end

csvq(s) = "\"" * replace(string(s), "\"" => "'", "\n" => " ") * "\""

function main(args)
    datadir, outdir, cell = args[1], args[2], args[3]
    G = endswith(cell, "_none") ? 0 : parse(Int, match(r"_G(\d+)$", cell).captures[1])
    n = parse(Int, match(r"^n(\d+)_", cell).captures[1])
    re = endswith(cell, "_none") ? "none" : "G$G"
    rfrom = length(args) >= 4 ? parse(Int, args[4]) : 1
    rto = length(args) >= 5 ? parse(Int, args[5]) : 500
    mkpath(outdir)
    D = read_cell(joinpath(datadir, cell * ".csv"))
    f = G > 0 ? bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ z)) :
                bf(@formula(y ~ x), @formula(sigma ~ z))
    out = joinpath(outdir, @sprintf("DRModels_%s_%03d-%03d.csv", cell, rfrom, rto))
    open(out, "w") do io
        println(io, "engine,cell,n,re,G,rep,time_s,param,true,est,est_link,se_link,lower,upper,",
                "conf_status,converged,conv_status,raw_converged,iterations,loglik,warnings")
        for r in rfrom:rto
            idx = findall(==(r), D.rep)
            dat = (y = D.y[idx], x = D.x[idx], z = D.z[idx],
                   g = string.(D.g[idx]))          # grouping factor as strings
            warnbuf = IOBuffer()
            t0 = time()
            fit = try
                Base.CoreLogging.with_logger(Base.CoreLogging.SimpleLogger(warnbuf)) do
                    drm(f, Gaussian(); data = dat)
                end
            catch e
                e
            end
            el = time() - t0
            warns = replace(String(take!(warnbuf)), "\n" => " ")
            if fit isa Exception
                msg = sprint(showerror, fit)
                println(io, join(["DRModels", cell, n, re, G, r, el, "", "", "", "", "", "",
                                  "", "", false, "error", false, -1, "", csvq(msg * " " * warns)], ","))
                continue
            end
            conv = is_converged(fit)
            se = try
                stderror(fit)
            catch
                fill(NaN, length(fit.theta))
            end
            ci = try
                confint(fit; method = :wald)
            catch e
                nothing
            end
            for ((p, rng), (_, nms)) in zip(fit.blocks, fit.coefnames)
                for (j, k) in enumerate(rng)
                    name = map_param(p, nms[j])
                    name == "" && continue
                    est_link = fit.theta[k]
                    est = name == "sd_g" ? exp(est_link) : est_link
                    lo, hi, cs = NaN, NaN, "wald_error"
                    if ci !== nothing
                        row = findfirst(rw -> rw.param === p && rw.coef == nms[j], ci)
                        if row !== nothing
                            lo, hi = ci[row].lower, ci[row].upper
                            # DRModels reports the RE SD interval on log sigma_b;
                            # back-transform so both engines are on the SD scale.
                            if name == "sd_g"
                                lo, hi = exp(lo), exp(hi)
                            end
                            cs = "wald"
                        end
                    end
                    println(io, join(Any["DRModels", cell, n, re, G, r, el, name, TRUTH[name],
                                         est, est_link, se[k], lo, hi, cs, conv,
                                         conv ? "converged" : "not_converged", fit.converged,
                                         fit.iterations, fit.loglik, csvq(warns)], ","))
                end
            end
            flush(io)
        end
    end
    println("wrote ", out)
end

main(ARGS)
