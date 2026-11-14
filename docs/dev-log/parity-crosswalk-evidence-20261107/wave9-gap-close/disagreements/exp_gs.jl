using DRModels, DelimitedFiles, LinearAlgebra, Statistics
DD = "data"
m, h = readdlm(joinpath(DD, "data_gamma_spatial.csv"), ',', Any; header = true); h = String.(vec(h))
col(n) = m[:, findfirst(==(n), h)]
d = (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")), z = Float64.(col("z")), g = String.(col("g")))
cm = readdlm(joinpath(DD, "coords.csv"), ',', Any; skipstart = 1)
cd = Dict(String(cm[i,1]) => [Float64(cm[i,2]), Float64(cm[i,3])] for i in 1:size(cm,1))
fs = unique(d.g); P = reduce(vcat, [permutedims(cd[s]) for s in fs]); G = length(fs)
D = [hypot(P[i,1]-P[j,1], P[i,2]-P[j,2]) for i in 1:G, j in 1:G]
med = median([D[i,j] for i in 1:G for j in i+1:G]); meanD = sum(D)/(G^2-G)
KR = exp.(-D ./ med) + 1e-6I
f = bf(@formula(y ~ x1 + x2 + x3 + spatial(1 | g)), @formula(sigma ~ 1))
fit_c = drm(f, DRModels.Gamma(); data = d, coords = cd)
fit_k = drm(f, DRModels.Gamma(); data = d, K = KR)
println("R reported            -406.1954700141")
println("Julia coords (default) ", loglikelihood(fit_c), "  conv=", fit_c.converged)
println("Julia K = R kernel     ", loglikelihood(fit_k), "  conv=", fit_k.converged)
println("median dist ", med, " mean dist ", meanD)
println("theta coords ", fit_c.theta); println("theta K      ", fit_k.theta)
fz = bf(@formula(y ~ x1 + x2 + x3 + spatial(1 | g)), @formula(sigma ~ 1), @formula(sd(g, spatial) ~ z))
fz1 = bf(@formula(y ~ x1 + x2 + x3 + spatial(1 | g)), @formula(sigma ~ 1), @formula(sd(g, spatial) ~ 1))
println("sd-z   R -404.2755360722 | Julia coords ", loglikelihood(drm(fz, DRModels.Gamma(); data = d, coords = cd)), " | Julia K=R kernel ", loglikelihood(drm(fz, DRModels.Gamma(); data = d, K = KR)))
println("sd-one R -406.1954700141 | Julia coords ", loglikelihood(drm(fz1, DRModels.Gamma(); data = d, coords = cd)), " | Julia K=R kernel ", loglikelihood(drm(fz1, DRModels.Gamma(); data = d, K = KR)))
