# A10 pre-run: NATIVE DRM.jl on the committed biv-q4-phylo-reml fixture.
# 1 warm-up (discarded) + 3 timed reps in ONE Julia session (warm workflow), single core.
using DRM, LinearAlgebra
BLAS.set_num_threads(1)
out_dir = ENV["PRERUN_OUT"]; mkpath(out_dir)
fixture = expanduser("~/parity_joint/DRM.jl/test/parity/q4-reml/biv-q4-phylo-reml")
lines = filter(!isempty, readlines(joinpath(fixture, "data.csv")))
unq(s) = strip(s, '"')
cols = Symbol.(unq.(split(lines[1], ',')))
rows = [unq.(split(l, ',')) for l in lines[2:end]]
numeric = Set((:y1, :y2, :x))
dat = NamedTuple(map(enumerate(cols)) do (j, name)
    col = [r[j] for r in rows]
    name in numeric ? name => parse.(Float64, col) : name => String.(col)
end)
# minimal JSON writer (no non-stdlib deps so the pinned DRM.jl project is untouched)
jsonv(x::AbstractString) = "\"" * escape_string(x) * "\""
jsonv(x::Bool) = string(x)
jsonv(x::Integer) = string(x)
jsonv(x::AbstractFloat) = isfinite(x) ? repr(x) : "null"
jsonv(x::AbstractDict) = "{" * join(["\"$k\": " * jsonv(v) for (k, v) in x], ", ") * "}"
jsonv(x::AbstractVector) = "[" * join(jsonv.(x), ", ") * "]"
tree = read(joinpath(fixture, "tree.newick"), String)
form = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
          mu2    = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
          sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12  = @formula(rho12 ~ 1))
cpu_now() = ccall(:clock, Clong, ()) / 1e6   # process CPU seconds (Linux CLOCKS_PER_SEC = 1e6)
function coef_named(fit)
    θ = coef(fit); namemap = Dict(p => ns for (p, ns) in fit.coefnames)
    out = Dict{String,Float64}()
    for (param, r) in fit.blocks
        param === :phylocov && continue; haskey(namemap, param) || continue
        for (nm, est) in zip(namemap[param], θ[r]); out["$(param)_$(nm)"] = est; end
    end
    out
end
function one(rep)
    GC.gc()
    c0 = cpu_now(); t0 = time()
    fit = drm(form, Gaussian(); data = dat, tree = tree, method = :REML, q4_vcov = false)
    wall = time() - t0; cpu = cpu_now() - c0
    Dict("engine" => "DRM.jl-native", "rep" => rep, "wall_s" => wall, "cpu_s" => cpu,
         "converged" => is_converged(fit), "loglik" => loglik(fit),
         "reml_loglik" => reml_loglik(fit), "coef" => coef_named(fit))
end
warm = one(0)   # warm-up: JIT compile of the whole route; DISCARDED from the timing summary
res = [one(i) for i in 1:3]
for r in vcat([warm], res)
    write(joinpath(out_dir, "jl-rep$(r["rep"]).json"), jsonv(r))
end
sha = strip(read(`git -C $(expanduser("~/parity_joint/DRM.jl")) rev-parse HEAD`, String))
env = Dict("julia_version" => string(VERSION), "DRM_jl_sha" => sha,
           "JULIA_NUM_THREADS" => Threads.nthreads(), "BLAS_threads" => BLAS.get_num_threads(),
           "host" => gethostname())
write(joinpath(out_dir, "jl-env.json"), jsonv(env))
println("JL: warmup wall=", round(warm["wall_s"], digits=3), " | timed wall=", join(round.([r["wall_s"] for r in res], digits=3), ","),
        " | cpu=", join(round.([r["cpu_s"] for r in res], digits=3), ","),
        " | loglik=", join([string(r["loglik"]) for r in res], ","), " | conv=", join([r["converged"] for r in res], ","))
