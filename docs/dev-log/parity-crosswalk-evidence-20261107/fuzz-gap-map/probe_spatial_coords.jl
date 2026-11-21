# Does the Beta / NB2 / Binomial plain spatial(1 | g) route accept `coords`, as its own refusal message says?
using DRModels, DelimitedFiles, LinearAlgebra
const DD = get(ENV, "FUZZ_DATA", "data")
function load(fam)
    m, h = readdlm(joinpath(DD, "data_$(fam)_spatial.csv"), ',', Any; header = true); h = String.(vec(h))
    col(n) = m[:, findfirst(==(n), h)]
    (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")), g = String.(col("g")))
end
cc = readdlm(joinpath(DD, "coords.csv"), ',', Any; skipstart = 1)
ids = String.(cc[:, 1]); xy = Float64.(cc[:, 2:3]); dct = Dict(ids[i] => xy[i, :] for i in eachindex(ids))
D = [norm(xy[i, :] - xy[j, :]) for i in axes(xy, 1), j in axes(xy, 1)]
Kexp = exp.(-D ./ sort(vec(D))[div(length(D), 2)]) + 1e-6I
mk(s) = eval(Meta.parse("@formula(" * s * ")"))
function t(label, F, fam; kw...)
    d = load(fam)
    f = fam == "binomial" ? bf(mk("y ~ x1 + x2 + x3 + spatial(1 | g)")) : bf(mk("y ~ x1 + x2 + x3 + spatial(1 | g)"), mk("sigma ~ 1"))
    r = try fit = drm(f, F; data = d, kw...); "FITS ll=$(round(loglikelihood(fit); digits = 4))"
    catch e; first(replace(sprint(showerror, e), '\n' => ' '), 200) * " [" * string(typeof(e)) * "]" end
    println(rpad(label, 40), r)
end
for (fam, F) in (("beta", Beta()), ("nb2", NegBinomial2()), ("binomial", Binomial(:logit)), ("poisson", Poisson()), ("gamma", DRModels.Gamma()))
    t("$fam coords=Dict", F, fam; coords = dct)
    t("$fam coords=Matrix(G x 2)", F, fam; coords = xy)
    t("$fam K=precomputed exp kernel", F, fam; K = Kexp)
end
