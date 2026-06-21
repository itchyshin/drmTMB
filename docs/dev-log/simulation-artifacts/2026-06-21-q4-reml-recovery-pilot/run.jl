# q4 REML-vs-ML among-axis SD recovery pilot (direct DRM.jl engine).
#
# Evidence for the drmTMB `biv_q4_phylo_reml` bridge cell: the REML estimator the
# bridge forwards is LESS biased than ML, recovering the four among-axis SDs
# (sqrt(diag(Sigma_a)) of the q4 PLSM) closer to the known truth on every axis.
# Direct-DRM.jl lane (the same restricted-likelihood estimator the bridge forwards);
# native TMB cannot fit q4 phylo REML, so there is no engine-vs-engine comparison.
#
# Run against the DRM.jl engine (seeded + reproducible):
#   JULIA_HOME=<juliaup bin> julia --project=<DRM.jl checkout> \
#     docs/dev-log/simulation-artifacts/2026-06-21-q4-reml-recovery-pilot/run.jl
#
# 40 replicates = a PILOT, not a full (>=200-rep) calibration. See results.md.

using DRM, Random, LinearAlgebra, Statistics

Random.seed!(20260621)
p = 16; m = 5
phy = DRM.random_balanced_tree(p; branch_length = 0.3)
Σphy = DRM.sigma_phy_dense(phy; σ²_phy = 1.0)
LC = cholesky(Symmetric(Σphy)).L
Λ = [0.25 0.10 0.05 0.00;
     0.10 0.25 0.00 0.04;
     0.05 0.00 0.16 0.02;
     0.00 0.04 0.02 0.16]
truth = sqrt.(diag(Λ))            # [0.5, 0.5, 0.4, 0.4]
LamL = cholesky(Symmetric(Λ)).L
sp = repeat(1:p, inner = m); n = length(sp)

form = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
          mu2    = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
          sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12  = @formula(rho12 ~ 1))

R = 40
ml = Vector{Vector{Float64}}(); rl = Vector{Vector{Float64}}()
for r in 1:R
    U = LC * randn(p, 4) * LamL'
    x = randn(n)
    y1 = 0.5 .+ 0.3 .* x .+ U[sp, 1] .+ exp.(-0.6 .+ U[sp, 3]) .* randn(n)
    y2 = -0.2 .+ 0.4 .* x .+ U[sp, 2] .+ exp.(-0.6 .+ U[sp, 4]) .* randn(n)
    dat = (; y1, y2, x, species = phy.leaf_names[sp])
    fml = drm(form, Gaussian(); data = dat, tree = phy, method = :ML,   q4_vcov = false)
    frl = drm(form, Gaussian(); data = dat, tree = phy, method = :REML, q4_vcov = false)
    push!(ml, sqrt.(max.(diag(fml.ranef.Sigma_a), 0.0)))
    push!(rl, sqrt.(max.(diag(frl.ranef.Sigma_a), 0.0)))
end

ML = reduce(hcat, ml)'; RL = reduce(hcat, rl)'
ax = ["mu1", "mu2", "sigma1", "sigma2"]
println("reps_ok = ", size(ML, 1), " / ", R)
println("axis    truth  ML_mean RE_mean ML_MAE RE_MAE RE_closer")
for j in 1:4
    println(rpad(ax[j], 7), " ", rpad(round(truth[j], digits = 3), 6), " ",
            rpad(round(mean(ML[:, j]), digits = 3), 7), " ", rpad(round(mean(RL[:, j]), digits = 3), 7), " ",
            rpad(round(mean(abs.(ML[:, j] .- truth[j])), digits = 3), 6), " ",
            rpad(round(mean(abs.(RL[:, j] .- truth[j])), digits = 3), 6), " ",
            round(mean(abs.(RL[:, j] .- truth[j]) .< abs.(ML[:, j] .- truth[j])), digits = 2))
end
println("OVERALL ML_MAE = ", round(mean(abs.(ML .- truth')), digits = 4),
        "  REML_MAE = ", round(mean(abs.(RL .- truth')), digits = 4))
# Per-axis bias significance (z = mean bias / Monte-Carlo SE of the mean). The
# mean-bias direction is the load-bearing signal; the per-draw "closer" win-rate
# above is descriptive only (not individually significant at R=40).
println("axis    ML_bias ML_MCSE ML_z   RE_bias RE_MCSE RE_z")
for j in 1:4
    mlse = std(ML[:, j]) / sqrt(size(ML, 1)); rese = std(RL[:, j]) / sqrt(size(RL, 1))
    mlb = mean(ML[:, j]) - truth[j]; reb = mean(RL[:, j]) - truth[j]
    println(rpad(ax[j], 7), " ", rpad(round(mlb, digits = 3), 7), " ", rpad(round(mlse, digits = 3), 7), " ",
            rpad(round(mlb / mlse, digits = 2), 6), " ", rpad(round(reb, digits = 3), 7), " ",
            rpad(round(rese, digits = 3), 7), " ", round(reb / rese, digits = 2))
end
