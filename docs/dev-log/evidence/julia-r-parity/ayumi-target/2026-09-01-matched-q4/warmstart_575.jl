using DRM
using TOML
using LinearAlgebra
using DelimitedFiles: readdlm

FIXTURE = joinpath("/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/afd6975e-02e8-4ecd-ae5c-478837cfc231/scratchpad/wt-fix575", "test", "parity", "q4-reml", "biv-q4-phylo-reml")

function _load_data(dir)
    raw, header = readdlm(joinpath(dir, "data.csv"), ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    numeric = Set((:y1, :y2, :x))
    pairs = map(enumerate(cols)) do (j, name)
        col = raw[:, j]
        if name in numeric
            name => Float64[parse(Float64, string(v)) for v in col]
        else
            name => string.(col)
        end
    end
    return NamedTuple(pairs)
end

DAT = _load_data(FIXTURE)
TREE = read(joinpath(FIXTURE, "tree.newick"), String)
FORM = bf(mu1    = @formula(y1 ~ x + phylo(1 | species)),
          mu2    = @formula(y2 ~ x + phylo(1 | species)),
          sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
          sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
          rho12  = @formula(rho12 ~ 1))

rhs = Dict(FORM.forms)
fixed, marker = DRM._bivariate_q4_marker(rhs)
grp = marker[2]
lc_zero = length(marker) >= 3 ? marker[3] : Int[]
phy = DRM._as_augmented_phy(TREE)

y1, X1, _ = DRM._design(FORM.response1, fixed[:mu1], DAT)
y2, X2, _ = DRM._design(FORM.response2, fixed[:mu2], DAT)
_, Xs1, _ = DRM._design(FORM.response1, fixed[:sigma1], DAT)
_, Xs2, _ = DRM._design(FORM.response1, fixed[:sigma2], DAT)
_, Xr, _  = DRM._design(FORM.response1, fixed[:rho12], DAT)

obs1 = DRM._observed_response_mask(y1)
obs2 = DRM._observed_response_mask(y2)
species = DRM._phylo_species_index(phy, getproperty(DAT, grp))
prob, Q_cond = DRM.make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr; species = species)

β1 = X1[obs1, :] \ y1[obs1]
β2 = X2[obs2, :] \ y2[obs2]
res1 = y1[obs1] .- X1[obs1, :] * β1
res2 = y2[obs2] .- X2[obs2, :] * β2
β0 = (mu1 = β1, mu2 = β2,
      s1 = DRM._initial_scale_beta(Xs1, res1), s2 = DRM._initial_scale_beta(Xs2, res2),
      rho = zeros(size(Xr, 2)))
Λ0 = Matrix(Symmetric([
    0.30 0.02 0.01 0.010
    0.02 0.30 0.01 0.010
    0.01 0.01 0.08 0.005
    0.01 0.01 0.005 0.080
]))
if !isempty(lc_zero)
    lc0 = DRM.Λ_to_lc(Λ0); lc0[lc_zero] .= 0.0; Λ0 = DRM.lc_to_Λ(lc0)
end

n_beta = size(X1, 2) + size(X2, 2) + size(Xs1, 2) + size(Xs2, 2)
println("n_beta (marginalised fixed effects) = ", n_beta)
const_offset = 0.5 * n_beta * log(2π)
println("(n_beta/2)*log(2*pi) = ", const_offset)

g_tol = 1e-3
rr = DRM.fit_q4_reml(prob, Q_cond; beta0 = β0, Lambda0 = Λ0,
                      g_tol = g_tol, iterations = 300, n_newton = 40, lc_zero = lc_zero)

println("=== Julia's own REML optimum ===")
println("converged = ", rr.converged, "  g_residual = ", rr.g_residual)
println("reml_loglik (normalised) = ", rr.reml_loglik)
phi_hat = rr.phi
rho_hat, lc_hat = DRM.unpack_phi(prob, phi_hat)
println("phi_hat rho = ", rho_hat)
Lam_hat = DRM.lc_to_Λ(lc_hat)
println("Lambda_hat = "); show(stdout, "text/plain", Lam_hat); println()

# ---- TMB's fitted point ----
expected = TOML.parsefile(joinpath(FIXTURE, "expected.toml"))
tmb_ll = Float64(expected["fit"]["loglik"])
rho12_tmb = Float64(expected["coef"]["rho12_(Intercept)"])

# TMB's phylo_q4_covariance (order mu1, mu2, sigma1, sigma2), from R refit report()
Lambda_tmb = [
    0.5288095   0.25509007 -0.1228962  -0.15554224
    0.25509007  0.28551843 -0.1794685  -0.02445802
   -0.1228962  -0.1794685   0.4857264  -0.10269499
   -0.15554224 -0.02445802 -0.10269499  0.16678147
]

println("lc_zero = ", lc_zero)
phi_tmb = DRM.pack_phi(prob, [rho12_tmb], Lambda_tmb)

# Evaluate DRM.jl's own (unnormalised) objective AT TMB's phi, profiling beta
# (mu1,mu2,sigma1,sigma2) via the same conditional-Newton machinery, warm-started
# from TMB's own fixed-effect estimates so the inner profile has every chance to
# land at its true conditional optimum.
beta0_tmb = (mu1 = [Float64(expected["coef"]["mu1_(Intercept)"]), Float64(expected["coef"]["mu1_x"])],
             mu2 = [Float64(expected["coef"]["mu2_(Intercept)"]), Float64(expected["coef"]["mu2_x"])],
             s1  = [Float64(expected["coef"]["sigma1_(Intercept)"])],
             s2  = [Float64(expected["coef"]["sigma2_(Intercept)"])],
             rho = [rho12_tmb])

rv_tmb, u_tmb, ch_tmb, bv_tmb, P_tmb, inner_conv_tmb = DRM.reml_ll_and_mode(
    prob, Q_cond, phi_tmb; u0 = nothing, beta0 = beta0_tmb, n_newton = 60)

println()
println("=== DRM.jl objective evaluated AT TMB's (phi, beta) ===")
println("inner_converged = ", inner_conv_tmb)
println("raw (unnormalised) reml_ll at theta_TMB = ", rv_tmb)
norm_rv_tmb = rv_tmb + const_offset
println("normalised reml_ll at theta_TMB = ", norm_rv_tmb)
println("profiled beta at TMB's phi: ", bv_tmb)

println()
println("=== Summary (all normalised, same scale as TMB's reported loglik) ===")
println("TMB optimum (expected.toml)                : ", tmb_ll)
println("Julia's own optimum (fit_q4_reml)           : ", rr.reml_loglik)
println("Julia objective AT theta_TMB (profiled beta): ", norm_rv_tmb)
println("Julia_own - Julia_at_TMB                    : ", rr.reml_loglik - norm_rv_tmb)
println("TMB - Julia_own                             : ", tmb_ll - rr.reml_loglik)
println("TMB - Julia_at_TMB                           : ", tmb_ll - norm_rv_tmb)

println()
println("=== Warm-start fit_q4_reml DIRECTLY at phi_tmb (bypassing ML warm start) ===")
rr_tmb = DRM.fit_q4_reml(prob, Q_cond; phi0 = phi_tmb, beta0 = beta0_tmb, Lambda0 = Lambda_tmb,
                          g_tol = 1e-3, iterations = 300, n_newton = 40, lc_zero = lc_zero)
println("converged = ", rr_tmb.converged, "  g_residual = ", rr_tmb.g_residual)
println("reml_loglik (normalised) = ", rr_tmb.reml_loglik)
println("phi moved from phi_tmb by norm = ", norm(rr_tmb.phi .- phi_tmb))
