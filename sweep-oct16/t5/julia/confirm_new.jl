# sweep-oct16 t5 -- standalone confirmation of extra missing/weight behaviours.
# Each drm() is wrapped in FIT_TIMEOUT (default 120s).
# Usage: julia --project=<DRModels.jl> confirm_new.jl <datadir>
using DRModels, Printf
const datadir = ARGS[1]
const FIT_TIMEOUT = parse(Float64, get(ENV, "FIT_TIMEOUT", "120"))

function with_hard_timeout(f, secs)
    ch = Channel{Any}(1)
    task = @async begin
        try
            put!(ch, (:ok, f()))
        catch e
            put!(ch, (:err, e))
        end
    end
    status = timedwait(() -> istaskdone(task), secs)
    if status == :timed_out
        try
            schedule(task, InterruptException(); error = true)
        catch
        end
        error("TIMEOUT after $(round(Int, secs))s")
    end
    kind, val = take!(ch)
    kind === :ok ? val : throw(val)
end

function read_cell(path)
    lines = readlines(path)
    hdr = split(lines[1], ',')
    cols = Dict(h => String[] for h in hdr)
    for l in lines[2:end]
        for (h, v) in zip(hdr, split(l, ','))
            push!(cols[h], v)
        end
    end
    num(v) = v == "NA" ? missing : parse(Float64, v)
    (y = num.(cols["y"]), x = num.(cols["x"]), g = String.(cols["g"]),
     w_int = parse.(Int, cols["w_int"]))
end

function report(tag, thunk)
    t0 = time()
    try
        fit = with_hard_timeout(thunk, FIT_TIMEOUT)
        mu = coef(fit, :mu)
        @printf("%s OK nobs=%d ncoef_mu=%d loglik=%.10g conv=%s secs=%.1f\n",
                tag, nobs(fit), length(mu), loglik(fit),
                string(is_converged(fit)), time() - t0)
    catch e
        @printf("%s ERROR %s :: %s secs=%.1f\n", tag, typeof(e),
                replace(first(split(sprint(showerror, e), '\n')), '\n' => ' '),
                time() - t0)
    end
end

# 1. KeyError on missing x (gaussian_y00_x05)
d = read_cell(joinpath(datadir, "gaussian_y00_x05.csv"))
report("KeyError_missing_x", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                                       data = (y = d.y, x = d.x, g = d.g)))

# 2. weights kwarg
d0 = read_cell(joinpath(datadir, "gaussian_y00_x00.csv"))
keep = .!ismissing.(d0.y) .& .!ismissing.(d0.x)
cc = (y = Float64.(d0.y[keep]), x = Float64.(d0.x[keep]), g = d0.g[keep], w = Float64.(d0.w_int[keep]))
report("weights_kwarg", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                                  data = (y = cc.y, x = cc.x, g = cc.g), weights = cc.w))

# 3. Union{Missing,Float64} on complete x
U(v) = Vector{Union{Missing,eltype(v)}}(v)
report("union_eltype_complete_x", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                                            data = (y = cc.y, x = U(cc.x), g = cc.g)))
report("concrete_eltype_complete_x", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                                               data = (y = cc.y, x = cc.x, g = cc.g)))

# 4. missing in grouping factor g (10 rows)
gg = Vector{Union{Missing,String}}(cc.g)
gg[1:8:80] .= missing
report("g_missing", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                              data = (y = cc.y, x = cc.x, g = gg)))
k = setdiff(eachindex(cc.y), 1:8:80)
report("g_dropped", () -> drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian();
                              data = (y = cc.y[k], x = cc.x[k], g = cc.g[k])))

# 5. NaN-coded x on Poisson (should error or drop; currently may return -Inf)
p = read_cell(joinpath(datadir, "poisson_y00_x05.csv"))
nanv = v -> Float64[ismissing(a) ? NaN : a for a in v]
report("poisson_nan_x", () -> drm(bf(@formula(y ~ x + (1 | g))), Poisson();
                                  data = (y = nanv(p.y), x = nanv(p.x), g = p.g),
                                  marginal = :Laplace))
keepp = .!ismissing.(p.y) .& .!ismissing.(p.x)
report("poisson_cc_laplace", () -> drm(bf(@formula(y ~ x + (1 | g))), Poisson();
                                       data = (y = Float64.(p.y[keepp]), x = Float64.(p.x[keepp]), g = p.g[keepp]),
                                       marginal = :Laplace))
println("done")
