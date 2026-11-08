using DRModels, DelimitedFiles, Printf, LinearAlgebra, SparseArrays
const D = DRModels; const Optim = D.Optim
const HERE = @__DIR__
const SEED = parse(Int, get(ENV, "SEED", "55"))
tree = strip(read(joinpath(HERE, "tree.nwk"), String))
tag = @sprintf("nb2_phylo_s%03d", SEED)
m, h = readdlm(joinpath(HERE, "data", tag * ".csv"), ',', Any; header = true)
h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
C, gidx, G = D._structured_q2_kernel(:phylo, :g, d.g; tree, K = nothing, A = nothing, coords = nothing, who = "h")
Q = sparse(Symmetric(inv(cholesky(Symmetric(C)))))
logdetQ = logdet(cholesky(Symmetric(Q)))
y = d.y; x = d.x
zg0 = zeros(G); zg1 = zeros(G); for i in eachindex(y); zg0[gidx[i]] = d.z0[i]; zg1[gidx[i]] = d.z1[i]; end
Z0 = hcat(ones(G), zg0); Z1 = hcat(ones(G), zg1)
Xmu = hcat(ones(length(y)), x)
aux_from, beta0, logsigma0 = D._nb2_laplace_setup(y, Xmu)
pmu = 2
last_b = zeros(2G)
function nll(theta)
    value, b, ok = D._nb2_animal_intercept_slope_laplace(y, Xmu, Z0, Z1, gidx, Q, logdetQ, theta, aux_from, x; b0 = last_b, correlated = false)
    if !ok
        value, b, ok = D._nb2_animal_intercept_slope_laplace(y, Xmu, Z0, Z1, gidx, Q, logdetQ, theta, aux_from, x; b0 = zeros(2G), correlated = false)
    end
    ok || return 1e18
    last_b .= b
    value
end
function grad!(g, theta)
    for j in eachindex(theta)
        hh = 2e-4 * (1 + abs(theta[j]))
        e = zeros(length(theta)); e[j] = hh
        g[j] = (nll(theta .+ e) - nll(theta .- e)) / (2hh)
    end
    g
end
function theta_start(a0, a1; sig = logsigma0)
    th = zeros(7); th[1:2] .= beta0; th[3] = sig
    th[4:5] .= Z0 \ fill(log(a0), G); th[6:7] .= Z1 \ fill(log(a1), G); th
end
theta0 = theta_start(0.4, 0.25)
function runlb(th0; iters = 250, store = false)
    last_b .= 0
    od = Optim.OnceDifferentiable(nll, grad!, th0)
    Optim.optimize(od, th0, Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking()),
        Optim.Options(g_tol = 1e-6, iterations = iters, store_trace = store, extended_trace = store))
end
function report(label, r)
    th = Optim.minimizer(r); gf = zeros(7); grad!(gf, th)
    @printf("%-28s f=%.8f ll=%.8f gmax/n=%.2e it=%d th=%s\n", label, nll(th), -nll(th), maximum(abs, gf)/length(y), Optim.iterations(r), string(round.(th, digits=3)))
end
