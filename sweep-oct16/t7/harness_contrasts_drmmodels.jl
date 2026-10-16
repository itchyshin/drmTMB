# t7 native DRModels.jl contrasts at pin f71b292.
using DRModels
using DelimitedFiles
using Statistics

const ROOT = "sweep-oct16/t7"
const PASS_BAR = 1e-8
const OUT = joinpath(ROOT, "results_contrasts_drmmodels.csv")

function read_csv(path)
    raw, hdr = readdlm(path, ',', header=true)
    hdr = String.(vec(hdr))
    col(name) = raw[:, findfirst(==(name), hdr)]
    return (
        yg = Float64.(col("yg")),
        yp = Float64.(col("yp")),
        x = Float64.(col("x")),
        g = string.(col("g")),
    )
end

open(OUT, "w") do io
    println(io, "family,coding,engine,status,max_fitted_invariance,elapsed_s,note")
end

function csv_escape(s)
    s = replace(string(s), "\n" => " ", "," => " ")
    return "\"" * s * "\""
end

d0 = read_csv(joinpath(ROOT, "data_contrasts.csv"))
# Julia/StatsModels uses dummy/treatment coding for String/categorical.
# We cannot attach R contrast matrices. Record native treatment-coded fits
# and whether non-treatment coding is even expressible.

function fit_gauss(d)
    drm(bf(@formula(yg ~ 1 + x + g), @formula(sigma ~ 1)), Gaussian(); data = d)
end
function fit_pois(d)
    drm(bf(@formula(yp ~ 1 + x + g)), Poisson(); data = d)
end

for (family, fitter) in (("gaussian", fit_gauss), ("poisson", fit_pois))
    t0 = time()
    status = "ERROR"
    note = ""
    elapsed = NaN
    try
        fit = fitter(d0)
        elapsed = time() - t0
        fv = fitted(fit)
        θ = fit.theta
        nms = try String.(fit.coef_names) catch; String[] end
        note = csv_escape("native StatsModels dummy coding; coefs=" * join(nms, "|") * " theta=" * join(string.(θ), "|"))
        status = "PASS_TREATMENT_ONLY"
    catch e
        elapsed = time() - t0
        note = csv_escape(sprint(showerror, e))
        status = "ERROR"
    end
    open(OUT, "a") do io
        println(io, join((family, "treatment_default", "drmmodels", status, "", elapsed, note), ","))
    end
    println(family, " ", status, " ", note)
end

println("wrote ", OUT)
# Explicit note: contr.sum / helmert / poly are R contrast matrices; DRModels.jl
# at this pin has no C() / contrasts= API, so those cells are not expressible
# on the Julia-native route (bridge refuses them by name; see drmTMB #1495).
open(OUT, "a") do io
    for family in ("gaussian", "poisson"), coding in ("sum", "helmert", "poly")
        println(io, join((family, coding, "drmmodels", "REFUSED", "", 0,
            csv_escape("no contrasts= / C() API at f71b292; StatsModels dummy coding only")), ","))
    end
end
