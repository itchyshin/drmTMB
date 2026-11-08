# trace non-finite points in the objective for one seed by running the fit under a hook
using DRModels, DelimitedFiles, Printf
s = parse(Int, ARGS[2])
function readd(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
end
d = readd(joinpath(ARGS[1], @sprintf("gauss_ord_s%03d.csv", s)))
f = bf(@formula(y ~ x + (1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, coef(intercept)) ~ z0), @formula(sd(g, coef(x)) ~ z1))
try
    drm(f, Gaussian(); data = d); println("OK")
catch e
    showerror(stdout, e, catch_backtrace()); println()
end
