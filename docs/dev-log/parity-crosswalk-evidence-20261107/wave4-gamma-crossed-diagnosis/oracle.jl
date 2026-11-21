# Independent dense Laplace oracle for the Gamma crossed joint mu+sigma SD model,
# in RAW (unstandardised) random-effect coordinates, using Distributions logpdf.
# theta = [b_mu(2); b_sigma(1); sd_id(2: int, w); sd_g(2: int, z)].
import Distributions, ForwardDiff, DelimitedFiles
using SpecialFunctions: loggamma
using LinearAlgebra, Random

struct GCData; y::Vector{Float64}; x::Vector{Float64}; ia::Vector{Int}; ig::Vector{Int}
    w::Vector{Float64}; z::Vector{Float64}; Ga::Int; Gb::Int; end   # w,z per level
function load_gc(path)
    M, _ = DelimitedFiles.readdlm(path, ',', header = true)
    ids = String.(M[:, 3]); gs = String.(M[:, 4])
    lid = sort(unique(ids)); lg = sort(unique(gs))
    ia = [findfirst(==(s), lid) for s in ids]; ig = [findfirst(==(s), lg) for s in gs]
    w = zeros(length(lid)); z = zeros(length(lg))
    for i in eachindex(ia); w[ia[i]] = M[i, 5]; z[ig[i]] = M[i, 6]; end
    GCData(Float64.(M[:, 1]), Float64.(M[:, 2]), ia, ig, w, z, length(lid), length(lg))
end
function logjoint(d::GCData, θ, u)
    T = promote_type(eltype(θ), eltype(u))
    a = u[1:d.Ga]; b = u[d.Ga+1:end]
    sda = exp.(θ[4] .+ θ[5] .* d.w); sdb = exp.(θ[6] .+ θ[7] .* d.z)
    s = zero(T)
    for i in eachindex(d.y)
        mu = exp(θ[1] + θ[2] * d.x[i] + a[d.ia[i]])
        k = exp(-2 * (θ[3] + b[d.ig[i]]))
        s += (k - 1) * log(d.y[i]) - d.y[i] * k / mu - k * log(mu / k) - loggamma(k)   # Gamma(shape k, scale mu/k)
    end
    for j in 1:d.Ga; s += -0.5 * log(2π) - log(sda[j]) - 0.5 * (a[j] / sda[j])^2; end
    for j in 1:d.Gb; s += -0.5 * log(2π) - log(sdb[j]) - 0.5 * (b[j] / sdb[j])^2; end
    s
end
function inner_mode(d::GCData, θ, u0; maxit = 200, tol = 1e-11)
    u = copy(u0); m = length(u)
    f(v) = (x = -logjoint(d, θ, v); isfinite(x) ? x : Inf)
    for _ in 1:maxit
        g = ForwardDiff.gradient(f, u); maximum(abs, g) < tol && return u, true
        H = ForwardDiff.hessian(f, u)
        lam = 0.0; step = nothing
        while true
            C = cholesky(Symmetric(H + lam * I); check = false)
            if issuccess(C); step = C \ g; break; end
            lam = lam == 0 ? 1e-3 : lam * 10; lam > 1e12 && return u, false
        end
        t = 1.0; F = f(u); ok = false
        while t > 1e-14
            un = u .- t .* step; Fn = f(un)
            if isfinite(Fn) && Fn <= F - 1e-4 * t * dot(g, step); u = un; ok = true; break; end
            t /= 2
        end
        ok || return u, maximum(abs, g) < 1e-8
    end
    u, maximum(abs, ForwardDiff.gradient(f, u)) < 1e-8
end
# Laplace log-likelihood at the mode `u`; returns (ll, pd).
function laplace_at(d::GCData, θ, u)
    H = ForwardDiff.hessian(v -> -logjoint(d, θ, v), u)
    C = cholesky(Symmetric(H); check = false)
    issuccess(C) || return (NaN, false)
    (logjoint(d, θ, u) + 0.5 * length(u) * log(2π) - 0.5 * logdet(C), true)
end
# All distinct inner modes found from `nstart` starts (zero, then random); returns
# vector of (ll, u) sorted by ll descending, de-duplicated at 1e-6 in ll.
function inner_modes(d::GCData, θ; nstart = 12, seed = 1, scale = 1.0)
    rng = MersenneTwister(seed); m = d.Ga + d.Gb
    sd0 = vcat(exp.(θ[4] .+ θ[5] .* d.w), exp.(θ[6] .+ θ[7] .* d.z))
    out = Tuple{Float64,Vector{Float64}}[]
    for s in 0:nstart
        u0 = s == 0 ? zeros(m) : scale .* sd0 .* randn(rng, m)
        u, ok = inner_mode(d, θ, u0); ok || continue
        ll, pd = laplace_at(d, θ, u); pd || continue
        any(o -> abs(o[1] - ll) < 1e-6, out) || push!(out, (ll, u))
    end
    sort!(out; by = o -> -o[1]); out
end
# sanity: hand-written Gamma/Normal log densities equal Distributions' at one point
let k = 2.3, mu = 1.7, y = 0.9
    @assert abs(((k - 1) * log(y) - y * k / mu - k * log(mu / k) - loggamma(k)) - Distributions.logpdf(Distributions.Gamma(k, mu / k), y)) < 1e-12
end
