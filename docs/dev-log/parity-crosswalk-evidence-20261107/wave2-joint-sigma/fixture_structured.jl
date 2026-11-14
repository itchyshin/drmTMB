# Copy of the fixture in DRModels test/test_gaussian_sigma_phylo_spatial_sd.jl.
using Random, LinearAlgebra, Statistics
# Random ultrametric tree on `ntip` labelled tips: Newick string plus the
# shared-path (MRCA depth) covariance C, from the recursion itself.
function _gps_tree(rng, labels; height = 1.0)
    function build(labs, depth)
        if length(labs) == 1
            return labs[1] * ":" * string(height - depth), Dict((labs[1], labs[1]) => height)
        end
        local k, dn, nl, Cl, nr, Cr, C        # do not capture the outer names
        k = rand(rng, 1:(length(labs) - 1))
        dn = depth + (height - depth) * rand(rng) * 0.6           # child node depth
        (nl, Cl) = build(labs[1:k], dn); (nr, Cr) = build(labs[(k+1):end], dn)
        C = merge(Cl, Cr)
        for a in labs[1:k], b in labs[(k+1):end]
            C[(a, b)] = dn; C[(b, a)] = dn
        end
        return "(" * nl * "," * nr * "):" * string(dn - depth), C
    end
    k = rand(rng, 1:(length(labels) - 1))                      # root at depth 0
    (nl, Cl) = build(labels[1:k], 0.0); (nr, Cr) = build(labels[(k+1):end], 0.0)
    C = merge(Cl, Cr)
    for a in labels[1:k], b in labels[(k+1):end]
        C[(a, b)] = 0.0; C[(b, a)] = 0.0
    end
    newick = "(" * nl * "," * nr * ");"
    G = length(labels)
    Cm = [C[(labels[i], labels[j])] for i in 1:G, j in 1:G]
    return newick, Cm
end

function _gps_fixture(provider::Symbol; seed, n_g = 48, n_each = 20)
    rng = MersenneTwister(seed)
    ids = [string("s", lpad(string(j), 2, '0')) for j in 1:n_g]
    tree = nothing; coords = nothing
    K = if provider === :phylo
        tree, C = _gps_tree(rng, shuffle(rng, ids))
        Cl = similar(C)
        # C is in the shuffled tip order; reorder to ids order through labels
        lab_order = [m.match for m in eachmatch(r"s\d\d", tree)]
        pos = Dict(l => i for (i, l) in enumerate(lab_order))
        P = [pos[l] for l in ids]
        C = C[P, P]
        C ./ sqrt.(diag(C) * diag(C)')
    else
        coords = hcat(repeat(1:8; inner = 8)[1:n_g], repeat(1:8; outer = 8)[1:n_g]) .* 1.0
        D = [norm(coords[i, :] .- coords[j, :]) for i in 1:n_g, j in 1:n_g]
        rng_ = median([D[i, j] for i in 1:n_g for j in (i+1):n_g if D[i, j] > 0])
        exp.(-D ./ rng_) + 1e-6 * I
    end
    z = collect(range(-1, 1; length = n_g))
    u = cholesky(Symmetric(K)).L * randn(rng, n_g)
    alpha = [log(0.45), 0.5]
    gi = repeat(1:n_g; inner = n_each)
    x = randn(rng, length(gi))
    sc = exp.(alpha[1] .+ alpha[2] .* z)
    y = 0.2 .+ 0.5 .* x .+ exp.(log(0.5) .+ sc[gi] .* u[gi]) .* randn(rng, length(gi))
    data = (; y, x, id = ids[gi], z = z[gi])
    return (; data, K, z, gi, tree, coords, ids)
end

