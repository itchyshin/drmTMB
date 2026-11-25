# Julia fits for the scale-extension agreement study. usage:
#   julia --project=<env> julia_run.jl <route> <seed_from> <seed_to>
# Routes: gauss_q3 gauss_q4 gauss_ord nb2_relmat poisson_relmat nb2_animal nb2_phylo gauss_relmat
# Writes data/<tag>.csv (+ _K.csv, _ids.csv for kernel routes; nb2_phylo data is written by make_data_nb2phylo.R),
# julia/<tag>.csv (block,k,est,se), julia/<tag>_ll.csv (ll, converged, seconds, msg).
using DRModels, DelimitedFiles, LinearAlgebra, Printf
include(joinpath(@__DIR__, "fixtures_scale300.jl")); include(joinpath(@__DIR__, "fixtures_q34.jl"))
const O = get(ENV, "SC_OUT", @__DIR__)
route = ARGS[1]; s_from = parse(Int, ARGS[2]); s_to = parse(Int, ARGS[3])
seedbase = Dict("gauss_ord" => 730000, "nb2_relmat" => 720000, "poisson_relmat" => 780000, "nb2_animal" => 770000,
                "gauss_relmat" => 790000)

function write_data(path, d)
    cols = collect(keys(d))
    open(path, "w") do io
        println(io, join(cols, ","))
        for i in eachindex(d.y); println(io, join((repr(getproperty(d, c)[i]) |> x -> strip(x, '"') for c in cols), ",")); end
    end
end
function write_kernel(tag, K, d)
    open(joinpath(O, "data", tag * "_K.csv"), "w") do io
        for i in 1:size(K, 1); println(io, join(repr.(K[i, :]), ",")); end
    end
    open(joinpath(O, "data", tag * "_ids.csv"), "w") do io; println(io, "id"); foreach(s -> println(io, s), unique(d.g)); end
end

function build(route, s)
    tag = @sprintf("%s_s%03d", route, s)
    seed = get(seedbase, route, 0) + s
    sdf(lev, c, z) = c == :int ? nothing : nothing
    if route in ("gauss_q3", "gauss_q4")
        q = route == "gauss_q3" ? 3 : 4
        fx = _q34_fixture(q; G = 150, m = 10, seed = 760000 + 10 * q + s)
        return tag, fx.data, nothing, _q34_formula(q), Gaussian(), (;)
    elseif route == "gauss_ord"
        d = _gord_fixture(; seed).data
        f = bf(@formula(y ~ x + (1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, coef(intercept)) ~ z0), @formula(sd(g, coef(x)) ~ z1))
        return tag, d, nothing, f, Gaussian(), (;)
    elseif route == "nb2_relmat"
        fx = _nb2_relmat_q2_fixture(; seed); K = Matrix(fx.A)
        f = bf(@formula(y ~ x + relmat(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
        return tag, fx.data, K, f, NegBinomial2(), (; K = K)
    elseif route == "poisson_relmat"
        fx = _poisson_animal_q2_fixture(; seed); K = Matrix(fx.A)
        f = bf(@formula(y ~ x + relmat(1 + x | g)), @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
        return tag, fx.data, K, f, Poisson(), (; K = K)
    elseif route == "nb2_animal"
        fx = _nb2_relmat_q2_fixture(; seed); K = Matrix(fx.A)
        f = bf(@formula(y ~ x + animal(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, animal, coef(intercept)) ~ z0), @formula(sd(g, animal, coef(x)) ~ z1))
        return tag, fx.data, K, f, NegBinomial2(), (; A = K)
    elseif route == "gauss_relmat"
        fx = _gq2_fixture(; seed); K = Matrix(fx.C)
        f = bf(@formula(y ~ x + relmat(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, relmat, coef(intercept)) ~ z0), @formula(sd(g, relmat, coef(x)) ~ z1))
        return tag, fx.data, K, f, Gaussian(), (; K = K)
    elseif route == "nb2_phylo"
        m, h = readdlm(joinpath(O, "data", tag * ".csv"), ',', Any; header = true)
        h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
        d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
        tree = strip(read(joinpath(@__DIR__, "tree.nwk"), String))
        f = bf(@formula(y ~ x + phylo(1 + x | g)), @formula(sigma ~ 1), @formula(sd(g, phylogenetic, coef(intercept)) ~ z0), @formula(sd(g, phylogenetic, coef(x)) ~ z1))
        return tag, d, nothing, f, NegBinomial2(), (; tree)
    end
    error("unknown route $route")
end

mkpath(joinpath(O, "data")); mkpath(joinpath(O, "julia"))
for s in s_from:s_to
    tag, d, K, f, fam, kw = build(route, s)
    if route != "nb2_phylo"
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
            println(io, "ll,converged,seconds,msg"); println(io, "$(repr(loglikelihood(fit))),$(fit.converged),$t,")
        end
        @printf("%s ll=%.8f converged=%s t=%.1fs\n", tag, loglikelihood(fit), fit.converged, t)
    catch e
        msg = replace(sprint(showerror, e)[1:min(end, 300)], '"' => '\'', '\n' => ' ', ',' => ';')
        open(joinpath(O, "julia", tag * "_ll.csv"), "w") do io
            println(io, "ll,converged,seconds,msg"); println(io, "NA,error,NA,$msg")
        end
        println(tag, " ERROR ", msg)
    end
end
