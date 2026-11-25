using DRModels, DelimitedFiles
m, h = readdlm("data/data_tweedie_ordinary.csv", ',', Any; header = true); h = String.(vec(h))
col(n) = m[:, findfirst(==(n), h)]
d = (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")), z = Float64.(col("z")), g = String.(col("g")))
for (tag, f) in (("ord_none", bf(@formula(y ~ x1+x2+x3+(1|g)), @formula(sigma ~ 1))),
                 ("ord_z", bf(@formula(y ~ x1+x2+x3+(1|g)), @formula(sigma ~ 1), @formula(sd(g) ~ z))),
                 ("slope_none", bf(@formula(y ~ x1+x2+x3+(0 + x1|g)), @formula(sigma ~ 1))),
                 ("slope_z", bf(@formula(y ~ x1+x2+x3+(0 + x1|g)), @formula(sigma ~ 1), @formula(sd(g, coef(x1)) ~ z))))
    fit = drm(f, Tweedie(); data = d)
    println(tag, " ll ", loglikelihood(fit), " conv ", fit.converged)
    println(tag, " blocks ", fit.blocks)
    println(tag, " theta ", fit.theta)
    println(tag, " coefnames ", fit.coefnames)
    println(tag, " fam ", fit.family)
end
