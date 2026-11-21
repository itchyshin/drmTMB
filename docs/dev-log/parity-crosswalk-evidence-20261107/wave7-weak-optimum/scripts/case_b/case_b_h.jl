using DRModels, DelimitedFiles, Printf, LinearAlgebra, SparseArrays
const D = DRModels; const Optim = D.Optim
const HERE = @__DIR__
const KIND = Symbol(get(ENV, "KIND", "phylo")); const SEED = parse(Int, get(ENV, "SEED", "5"))
nwk = strip(read(joinpath(HERE, "tree.nwk"), String))
cc = readdlm(joinpath(HERE, "coords.csv"), ',', skipstart = 1)
coords = Dict(String(cc[i, 1]) => [Float64(cc[i, 2]), Float64(cc[i, 3])] for i in 1:size(cc, 1))
M = readdlm(joinpath(HERE, "data", "$(KIND)_$(SEED).csv"), ',', skipstart = 1)
ids = String.(M[:, 1]); x = Float64.(M[:, 2]); z0r = Float64.(M[:, 3]); z1r = Float64.(M[:, 4]); y = Float64.(M[:, 5])
if KIND === :phylo
    C, gidx, G = D._structured_q2_kernel(:phylo, :id, ids; tree = nwk, K = nothing, A = nothing, coords = nothing, who = "h")
else
    gidx, G = D._group_index(ids); lev = unique(ids)
    C = D._gaussian_spatial_sd_kernel(permutedims(hcat((coords[l] for l in lev)...)), G, :id)
end
Q = sparse(Symmetric(inv(cholesky(Symmetric(C))))); logdetQ = logdet(cholesky(Symmetric(Q)))
zg0 = zeros(G); zg1 = zeros(G); for i in eachindex(y); zg0[gidx[i]] = z0r[i]; zg1[gidx[i]] = z1r[i]; end
Xsd0 = hcat(ones(G), zg0); Xsd1 = hcat(ones(G), zg1); Xmu = hcat(ones(length(y)), x)
sint = round.(Int, y); nint = ones(Int, length(y)); aux = (s = sint, ntr = nint, logchoose = zeros(length(y)))
ntr = ones(length(y)); last_b = zeros(2G)
function nll(theta)
    value, b, ok = D._binomial_animal_q2_laplace(aux, y, ntr, Xmu, Xsd0, Xsd1, gidx, Q, logdetQ, x, theta; b0 = last_b, correlated = false)
    if !ok
        value, b, ok = D._binomial_animal_q2_laplace(aux, y, ntr, Xmu, Xsd0, Xsd1, gidx, Q, logdetQ, x, theta; b0 = zeros(2G), correlated = false)
    end
    ok || return 1e18
    last_b .= b; value
end
function grad!(g, theta)
    for j in eachindex(theta)
        h = 2e-4 * (1 + abs(theta[j])); e = zeros(length(theta)); e[j] = h
        g[j] = (nll(theta .+ e) - nll(theta .- e)) / (2h)
    end
    g
end
pbar = clamp(sum(y) / length(y), 1e-4, 1 - 1e-4)
function theta_start(a0, a1)
    th = zeros(6); th[1] = D._binomial_start(DRModels.Binomial(), pbar)
    th[3:4] .= Xsd0 \ fill(log(a0), G); th[5:6] .= Xsd1 \ fill(log(a1), G); th
end
theta0 = theta_start(0.4, 0.3)
function runlb(th0; iters = 250, store = false, ls = Optim.LineSearches.BackTracking())
    last_b .= 0
    od = Optim.OnceDifferentiable(nll, grad!, th0)
    Optim.optimize(od, th0, Optim.LBFGS(linesearch = ls), Optim.Options(g_tol = 1e-6, iterations = iters, store_trace = store, extended_trace = store))
end
function report(label, r)
    th = Optim.minimizer(r); gf = zeros(6); grad!(gf, th)
    @printf("%-26s ll=%.8f gmax/n=%.2e it=%d th=%s\n", label, -nll(th), maximum(abs, gf)/length(y), Optim.iterations(r), string(round.(th, digits=3)))
end
