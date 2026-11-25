# Julia fits for the multi-seed agreement study. usage:
#   julia --project=<DRModels test env> julia_run.jl <route> [seed_from seed_to]
# Routes: poisson_animal nb2_relmat gauss_ord gauss_animal poisson_phylo poisson_spatial poisson_labelled lord_poisson lord_nb2
# Writes data/<route>_sNN.csv (+ _K.csv, _ids.csv for kernels) and julia/<route>_sNN.csv.
using DRModels, DelimitedFiles, LinearAlgebra, Printf
include(joinpath(@__DIR__, "fixtures.jl"))
const O = get(ENV, "SC_OUT", @__DIR__)
route = ARGS[1]
s_from = length(ARGS) >= 3 ? parse(Int, ARGS[2]) : 1
s_to = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 300
seedbase = Dict("poisson_animal" => 710000, "nb2_relmat" => 720000, "gauss_ord" => 730000,
                "gauss_animal" => 740000, "poisson_labelled" => 750000)

function write_data(path, d)
    open(path, "w") do io
        println(io, "y,x,z0,z1,g")
        for i in eachindex(d.y); println(io, join((repr(d.y[i]), repr(d.x[i]), repr(d.z0[i]), repr(d.z1[i]), d.g[i]), ",")); end
    end
end
function write_kernel(tag, K, d)
    open(joinpath(O, "data", tag * "_K.csv"), "w") do io
        for i in 1:size(K, 1); println(io, join(repr.(K[i, :]), ",")); end
    end
    open(joinpath(O, "data", tag * "_ids.csv"), "w") do io; println(io, "id"); foreach(s -> println(io, s), unique(d.g)); end
end

function build(route, s)
    seed = get(seedbase, route, 0) + s
    tag = @sprintf("%s_s%03d", route, s)
    if route == "poisson_animal"
        fx = _poisson_animal_q2_fixture(; seed); d = fx.data; K = Matrix(fx.A)
        f = bf(@formula(y ~ x + animal(1 + x | g)), @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1))
        return tag, d, K, f, Poisson(), (; A = K)
    elseif route == "nb2_relmat"
        fx = _nb2_relmat_q2_fixture(; seed); d = fx.data; K = Matrix(fx.A)
        f = bf(@formula(y ~ x + relmat(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
        return tag, d, K, f, NegBinomial2(), (; K = K)
    elseif route == "gauss_animal"
        fx = _gq2_fixture(; seed); d = fx.data; K = Matrix(fx.C)
        f = bf(@formula(y ~ x + animal(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1))
        return tag, d, K, f, Gaussian(), (; A = K)
    elseif route == "poisson_labelled"
        fx = _lrho_fixture(; seed); d0 = fx.data; K = Matrix(fx.A)
        d = (; y = d0.yp, x = d0.x, z0 = d0.z0, z1 = d0.z1, g = d0.g)
        f = bf(@formula(y ~ x + animal(1 + x | p | g)), @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1))
        return tag, d, K, f, Poisson(), (; A = K)
    elseif route == "gauss_ord"
        fx = _gord_fixture(; seed); d = fx.data
        f = bf(@formula(y ~ x + (1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, coef(intercept)) ~ z0), @formula(sd(g, coef(x)) ~ z1))
        return tag, d, nothing, f, Gaussian(), (;)
    elseif route in ("lord_poisson", "lord_nb2", "poisson_phylo", "poisson_spatial")
        path = joinpath(O, "data", tag * ".csv")
        m, h = readdlm(path, ',', Any; header = true)
        h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
        d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
        if route in ("lord_poisson", "lord_nb2")
            fam = route == "lord_poisson" ? Poisson() : NegBinomial2()
            f0 = @formula(sd(g, coef(intercept)) ~ z0); f1 = @formula(sd(g, coef(x)) ~ z1)
            f = route == "lord_poisson" ? bf(@formula(y ~ x + (1 + x | p | g)), f0, f1) : bf(@formula(y ~ x + (1 + x | p | g)), @formula(sigma ~ 1), f0, f1)
            return tag, d, nothing, f, fam, (;)
        elseif route == "poisson_phylo"
            tree = strip(read(joinpath(@__DIR__, "tree.nwk"), String))
            f = bf(@formula(y ~ x + phylo(1 + x | g)), @formula(sd(g, phylogenetic, coef(intercept)) ~ z0), @formula(sd(g, phylogenetic, coef(x)) ~ z1))
            return tag, d, nothing, f, Poisson(), (; tree)
        else
            cm, ch = readdlm(joinpath(@__DIR__, "coords.csv"), ',', Any; header = true)
            coords = Dict(String(cm[k, 1]) => [Float64(cm[k, 2]), Float64(cm[k, 3])] for k in 1:size(cm, 1))
            f = bf(@formula(y ~ x + spatial(1 + x | g)), @formula(sd(g, spatial, coef(intercept)) ~ z0), @formula(sd(g, spatial, coef(x)) ~ z1))
            return tag, d, nothing, f, Poisson(), (; coords)
        end
    end
    error("unknown route $route")
end

mkpath(joinpath(O, "data")); mkpath(joinpath(O, "julia"))
for s in s_from:s_to
    tag, d, K, f, fam, kw = build(route, s)
    if !(route in ("poisson_phylo", "poisson_spatial", "lord_poisson", "lord_nb2"))
        write_data(joinpath(O, "data", tag * ".csv"), d)
        K === nothing || write_kernel(tag, K, d)
    end
    try
        t = @elapsed fit = drm(f, fam; data = d, kw...)
        se = stderror(fit)
        open(joinpath(O, "julia", tag * ".csv"), "w") do io
            println(io, "block,k,est,se")
            for (b, r) in fit.blocks, (k, j) in enumerate(r)
                println(io, "$(b),$(k),$(repr(fit.theta[j])),$(repr(se[j]))")
            end
        end
        open(joinpath(O, "julia", tag * "_ll.csv"), "w") do io
            println(io, "ll,converged,seconds"); println(io, "$(repr(loglikelihood(fit))),$(fit.converged),$t")
        end
        @printf("%s ll=%.8f converged=%s t=%.1fs\n", tag, loglikelihood(fit), fit.converged, t)
    catch e
        open(joinpath(O, "julia", tag * "_ll.csv"), "w") do io
            println(io, "ll,converged,seconds"); println(io, "NA,error,NA")
        end
        println(tag, " ERROR ", sprint(showerror, e)[1:min(end, 400)])
    end
end
