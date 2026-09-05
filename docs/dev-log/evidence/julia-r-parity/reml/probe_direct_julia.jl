## Direct Julia probe for leaf-biv-animal-reml (G1 item 4 / G3): bypasses the
## R<->Julia bridge (which refuses this whole cell unconditionally for
## REML=TRUE, see bridge_marshalling in the scout findings) and calls DRM.jl's
## own top-level `drm()` for the bivariate Gaussian q=2 route with animal()
## (A=) and relmat() (K=) markers on the SAME shared-x fixture, under
## method=:REML. Confirms DRM.jl's own mathematics is provider-blind (bit-
## identical loglik between animal and relmat on the same numeric matrix).
##
## Run: julia --project=<DRM_JL_PATH> probe_direct_julia.jl <fixture_dir>

using DRM
using LinearAlgebra: diag
using DelimitedFiles: readdlm

fixture_dir = length(ARGS) >= 1 ? ARGS[1] : "."

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

function _load_K(dir)
    raw, header = readdlm(joinpath(dir, "K.csv"), ','; header = true)
    ids = string.(raw[:, 1])
    K = Float64[parse(Float64, string(v)) for v in raw[:, 2:end]]
    K = reshape(K, size(raw, 1), size(raw, 1))
    return K, ids
end

DAT = _load_data(fixture_dir)
K, ids = _load_K(fixture_dir)
println("ids match data levels: ", ids == sort(unique(DAT.id)) || ids == unique(DAT.id))

form_animal = bf(mu1 = @formula(y1 ~ x + animal(1 | id)),
                  mu2 = @formula(y2 ~ x + animal(1 | id)),
                  sigma1 = @formula(sigma1 ~ 1),
                  sigma2 = @formula(sigma2 ~ 1),
                  rho12  = @formula(rho12 ~ 1))

form_relmat = bf(mu1 = @formula(y1 ~ x + relmat(1 | id)),
                  mu2 = @formula(y2 ~ x + relmat(1 | id)),
                  sigma1 = @formula(sigma1 ~ 1),
                  sigma2 = @formula(sigma2 ~ 1),
                  rho12  = @formula(rho12 ~ 1))

println("=== animal(A=K), method=:REML ===")
fit_animal = drm(form_animal, Gaussian(); data = DAT, A = K, method = :REML)
println("estimation_method = ", estimation_method(fit_animal))
println("converged = ", fit_animal.converged)
println(string("loglik = ", loglik(fit_animal)))
println(string("reml_loglik = ", reml_loglik(fit_animal)))
println(string("ml_loglik = ", fit_animal.ml_loglik))
println(string("theta = ", fit_animal.theta))
println(string("coefnames mu1 = ", Dict(fit_animal.coefnames)[:mu1]))
println(string("coefnames mu2 = ", Dict(fit_animal.coefnames)[:mu2]))
println(string("vcov diag = ", diag(fit_animal.vcov)))

println("=== relmat(K=K), method=:REML ===")
fit_relmat = drm(form_relmat, Gaussian(); data = DAT, K = K, method = :REML)
println("estimation_method = ", estimation_method(fit_relmat))
println("converged = ", fit_relmat.converged)
println(string("loglik = ", loglik(fit_relmat)))
println(string("reml_loglik = ", reml_loglik(fit_relmat)))
println(string("theta = ", fit_relmat.theta))

println("=== comparison ===")
println("loglik identical? ", loglik(fit_animal) == loglik(fit_relmat))
println("theta identical? ", fit_animal.theta == fit_relmat.theta)
println(string("max|d_theta| = ", maximum(abs.(fit_animal.theta .- fit_relmat.theta))))
