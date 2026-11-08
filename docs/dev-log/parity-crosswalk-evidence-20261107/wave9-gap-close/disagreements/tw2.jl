# Common-objective check of the Tweedie random-intercept / random-slope disagreements.
# For each cell, evaluate BOTH engines' optima (theta_J, theta_R) under (a) the exact marginal
# log-likelihood (adaptive Gauss-Kronrod over the 1-D random effect, per group) and (b) the Laplace
# approximation (the objective drmTMB optimises). Likelihood = DRModels' Dunn-Smyth series (shared).
using DRModels, DelimitedFiles, QuadGK, ForwardDiff, LinearAlgebra
const lp = DRModels._logpdf_tweedie
m, h = readdlm("data/data_tweedie_ordinary.csv", ',', Any; header = true); h = String.(vec(h))
col(n) = m[:, findfirst(==(n), h)]
y = Float64.(col("y")); x1 = Float64.(col("x1")); x2 = Float64.(col("x2")); x3 = Float64.(col("x3")); z = Float64.(col("z")); g = String.(col("g"))
X = hcat(ones(length(y)), x1, x2, x3); gs = unique(g); members = [findall(==(s), g) for s in gs]
logistic(a) = 1 / (1 + exp(-a))
function groupfun(theta, slope, zsd)
    beta = theta[1:4]; phi = exp(2theta[5]); p = 1 + logistic(theta[6]); a = theta[7:end]
    eta0 = X * beta
    out = []
    for (k, idx) in enumerate(members)
        zg = z[idx[1]]
        sdg = zsd ? exp(a[1] + a[2] * zg) : exp(a[1])
        w = slope ? x1[idx] : ones(length(idx))
        f(u) = sum(lp(y[idx[j]], exp(clamp(eta0[idx[j]] + w[j] * sdg * u, -30, 30)), phi, p) for j in eachindex(idx))
        push!(out, (f = f, sd = sdg))
    end
    out
end
function ll_exact(theta, slope, zsd)
    tot = 0.0
    for gf in groupfun(theta, slope, zsd)
        h(u) = gf.f(u) - u^2 / 2
        # locate the mode, then integrate over mode +- 12 sd of the local curvature
        u0 = 0.0
        for _ in 1:60
            gr = ForwardDiff.derivative(h, u0); hh = ForwardDiff.derivative(v -> ForwardDiff.derivative(h, v), u0)
            st = -gr / hh; u0 += clamp(st, -2, 2); abs(st) < 1e-12 && break
        end
        hh = -ForwardDiff.derivative(v -> ForwardDiff.derivative(h, v), u0); sc = 1 / sqrt(hh)
        I, _ = quadgk(u -> exp(gf.f(u) - u^2 / 2 - h(u0)), u0 - 14sc, u0 + 14sc; rtol = 1e-12, atol = 0, order = 15)
        tot += h(u0) + log(I) - 0.5 * log(2π)
    end
    tot
end
function ll_laplace(theta, slope, zsd)
    tot = 0.0
    for gf in groupfun(theta, slope, zsd)
        h(u) = gf.f(u) - u^2 / 2
        u0 = 0.0
        for _ in 1:80
            gr = ForwardDiff.derivative(h, u0); hh = ForwardDiff.derivative(v -> ForwardDiff.derivative(h, v), u0)
            st = -gr / hh; u0 += clamp(st, -2, 2); abs(st) < 1e-13 && break
        end
        hh = -ForwardDiff.derivative(v -> ForwardDiff.derivative(h, v), u0)
        tot += h(u0) - 0.5 * log(hh)          # = h(u*) + 0.5 log(2pi) - 0.5 log(h'') - 0.5 log(2pi)
    end
    tot
end
cells = [("ord_none", false, false, -766.5667801791, -766.6476812942),
         ("ord_z", false, true, -766.5356601293, -766.6166608731),
         ("slope_none", true, false, -780.8964446563, -780.9642781147),
         ("slope_z", true, true, -777.0720784234, -777.1023396668)]
thR = Dict(); thJ = Dict()
for l in readlines("tw_R_par.txt")
    occursin(" par ", l) && (p = split(l); thR[p[1]] = parse.(Float64, split(p[3], ",")))
end
thJ["ord_none"] = [0.44892975875461166, 0.3849586064342318, 0.29371228295621893, -0.11963015367393287, 0.19762836506726644, 0.18440194639953417, -0.5190161359254983]
thJ["ord_z"] = [0.4460345230528436, 0.3856979087963632, 0.29303137468987306, -0.12010085625516835, 0.19740803578772673, 0.1840497618995834, -0.5166878163192432, 0.06162342049603061]
thJ["slope_none"] = [0.531597426433216, 0.389037569088564, 0.3700291636216513, -0.06690257770005932, 0.2535401027277318, 0.2879578101274821, -1.0565904903843706]
thJ["slope_z"] = [0.543843566883083, 0.37911171659503, 0.37360161936318836, -0.076027290374164, 0.2587157109359252, 0.29889361989750135, -3.3252902208336765, -3.3416288649264736]
println("cell\tR_reported\tJ_reported\tLap(thR)\tLap(thJ)\tExact(thR)\tExact(thJ)")
for (tag, slope, zsd, rrep, jrep) in cells
    println(join((tag, rrep, jrep, round(ll_laplace(thR[tag], slope, zsd); digits = 6), round(ll_laplace(thJ[tag], slope, zsd); digits = 6),
        round(ll_exact(thR[tag], slope, zsd); digits = 6), round(ll_exact(thJ[tag], slope, zsd); digits = 6)), "\t"))
end
