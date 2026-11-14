# Julia: Poisson spatial q2, multiseed seed 9 (flat slope-SD boundary), fitted from several start vectors.
# No Julia source file is modified. The fitter's initial theta0 is hard-coded, so this script re-evaluates a copy of
# `_fit_poisson_animal_intercept_slope_laplace` (read from src/poisson.jl, one inserted line: overwrite theta0 from a global)
# into the DRModels module at run time. usage: DRMJL=<worktree> julia --project=<test env> julia_probe.jl
using DRModels, DelimitedFiles, Printf
const O = @__DIR__; const MS = joinpath(O, "..", "..", "multiseed")
src = read(joinpath(ENV["DRMJL"], "src/poisson.jl"), String)
i0 = first(findfirst("function _fit_poisson_animal_intercept_slope_laplace(fam, y, Xmu, Zgs, gidx, Q,", src))
i1 = first(findfirst("# Independent relmat intercept-and-slope q2 block", src))
fn = src[i0:i1-1]
anchor = "    last_b = zeros(2 * size(Q, 1))\n"
@assert occursin(anchor, fn)
fn = replace(fn, anchor => "    _PROBE_THETA0[] === nothing || (theta0 .= _PROBE_THETA0[])\n" * anchor; count = 1)
Core.eval(DRModels, :(const _PROBE_THETA0 = Ref{Any}(nothing)))
Core.eval(DRModels, Meta.parse(strip(fn)))
function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; Dict(h[j] => m[:, j] for j in eachindex(h))
end
c = readcsv(joinpath(MS, "data", "poisson_spatial_s09.csv"))
d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
cm = readcsv(joinpath(MS, "coords.csv"))
coords = Dict(String(cm["id"][k]) => [Float64(cm["easting"][k]), Float64(cm["northing"][k])] for k in eachindex(cm["id"]))
f = bf(@formula(y ~ x + spatial(1 + x | g)), @formula(sd(g, spatial, coef(intercept)) ~ z0), @formula(sd(g, spatial, coef(x)) ~ z1))
st = readcsv(joinpath(O, "starts.csv"))
gz = unique(zip(d.g, d.z1)); z1u = unique(d.z1)
rows = String[]
function run(label, th0)
    DRModels._PROBE_THETA0[] = th0
    t = @elapsed fit = drm(f, Poisson(); data = d, coords)
    th = fit.theta; sdmax = maximum(exp.(th[5] .+ th[6] .* z1u)); sdmin = minimum(exp.(th[5] .+ th[6] .* z1u))
    g = try DRModels.loglikelihood(fit) catch; NaN end
    push!(rows, join([label, repr(g), fit.converged, join(repr.(th), ";"), sdmin, sdmax, t], ","))
    @printf("%s ll=%.9f conv=%s theta=%s slopeSD[%.2e, %.2e] t=%.1fs\n", label, g, fit.converged, round.(th; digits = 3), sdmin, sdmax, t)
end
run("default", nothing)
for k in eachindex(st["start"])
    run(String(st["start"][k]), Float64[st[n][k] for n in ("b0", "b1", "a0_int", "a0_z0", "a1_int", "a1_z1")])
end
open(joinpath(O, "julia_starts.csv"), "w") do io
    println(io, "start,ll,converged,theta,slope_sd_min,slope_sd_max,seconds"); foreach(r -> println(io, r), rows)
end
