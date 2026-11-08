using DRModels, DelimitedFiles, Printf
datadir = ARGS[1]; seeds = parse.(Int, split(ARGS[2], ","))
cm, _ = readdlm(joinpath(datadir, "..", "coords.csv"), ',', Any; header = true)
coords = Dict(String(cm[k, 1]) => [Float64(cm[k, 2]), Float64(cm[k, 3])] for k in 1:size(cm, 1))
function readd(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
end
f = bf(@formula(y ~ x + spatial(1 + x | g)), @formula(sd(g, spatial, coef(intercept)) ~ z0), @formula(sd(g, spatial, coef(x)) ~ z1))
starts = Dict("default" => nothing,
  "a" => th -> (th[3] = log(1.0); th[5] = log(0.5); th),
  "b" => th -> (th[3] = log(0.15); th[5] = log(0.1); th),
  "c" => th -> (th[3] = log(1.0); th[5] = log(0.1); th),
  "d" => th -> (th[3] = log(0.15); th[5] = log(0.5); th),
  "e" => th -> (th[3] = log(0.7); th[5] = log(0.7); th))
for s in seeds
    d = readd(joinpath(datadir, @sprintf("poisson_spatial_s%03d.csv", s)))
    for k in split(get(ENV, "STARTS", "default,a,b,c,d,e"), ",")
        DRModels._START_OVERRIDE[] = starts[String(k)]
        try
            fit = drm(f, Poisson(); data = d, coords = coords)
            @printf("seed %d start %-8s ll=%.6f conv=%s theta=%s\n", s, k, loglikelihood(fit), fit.converged, round.(fit.theta, digits = 3))
        catch e
            println("seed $s start $k ERROR ", sprint(showerror, e)[1:min(end,100)])
        end
    end
end
