# Generate 10 labelled-phylo Binomial datasets (64 tips, 30 Bernoulli rows each), true rho = 0.6.
using StableRNGs, LinearAlgebra, Random
const BITS = 6; G = 2^BITS; m = 30
ids = ["t$(lpad(i, 2, '0'))" for i in 1:G]
nw(ix, root) = length(ix) == 1 ? "$(ids[ix[1]]):1.5" :
    "(" * nw(ix[1:end÷2], false) * "," * nw(ix[end÷2+1:end], false) * ")" * (root ? ";" : ":0.1")
height = 1.5 + 0.1 * (BITS - 1)
bits(i) = reverse(digits(i - 1; base = 2, pad = BITS))
C = [i == j ? 1.0 : (findfirst(bits(i) .!= bits(j)) - 1) * 0.1 / height for i in 1:G, j in 1:G]
write("tree.nwk", nw(collect(1:G), true))
L = cholesky(Symmetric(C)).L
for seed in 1:10
    rng = StableRNG(20261108 + seed)
    z0 = repeat([-1.0, 1.0], G ÷ 2)
    z1 = collect(range(-1.0, 1.0; length = G))[randperm(rng, G)]
    e0, e1 = L * randn(rng, G), L * randn(rng, G)
    u0 = exp.(log(0.9) .+ 0.3 .* z0) .* e0
    u1 = exp.(log(0.8) .- 0.3 .* z1) .* (0.6 .* e0 .+ 0.8 .* e1)
    gi = repeat(1:G, inner = m)
    x = repeat(collect(range(-1.2, 1.2; length = m)), G)
    eta = 0.3 .+ 0.5 .* x .+ u0[gi] .+ x .* u1[gi]
    y = Float64.(rand(rng, length(eta)) .< 1 ./ (1 .+ exp.(-eta)))
    ord = randperm(rng, length(y))
    open("data_seed$(seed).csv", "w") do io
        println(io, "y,x,z0,z1,id")
        for i in ord
            println(io, join((Int(y[i]), x[i], z0[gi[i]], z1[gi[i]], ids[gi[i]]), ','))
        end
    end
end
println("ok")
