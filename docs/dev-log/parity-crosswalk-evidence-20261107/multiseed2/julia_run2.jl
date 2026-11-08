# Julia fits for the second multi-seed agreement study. usage:
#   julia --project=<DRModels test env> julia_run2.jl <route> [seed_from seed_to]
# Routes: gauss_q3 gauss_q4 gamma_same nb2_same nb2_corr gamma_corr gauss_phylo gauss_spatial
#         gauss_lphylo gauss_lspatial gauss_joint nb2_joint nb2_jcross
# Writes data/<route>_sNN.csv (Julia-generated routes) and julia/<route>_sNN.csv (+ _ll.csv).
# DRMJL (env) = DRModels worktree, needed for the Gamma/NB2 fixture in test/test_gamma_nb2_twofield_sd.jl.
using DRModels, DelimitedFiles, LinearAlgebra, Printf, Random
import Distributions
const O = @__DIR__
include(joinpath(O, "fixtures_q34.jl")); include(joinpath(O, "fixtures_joint.jl"))
ts = read(joinpath(ENV["DRMJL"], "test/test_gamma_nb2_twofield_sd.jl"), String)
include_string(Main, ts[1:first(findfirst("for (fam, shape)", ts))-1])   # defines tf_case(fam, shape; seed)
route = ARGS[1]
s_from = length(ARGS) >= 3 ? parse(Int, ARGS[2]) : 1
s_to = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 10

function write_data(path, d)
    cols = collect(keys(d))
    open(path, "w") do io
        println(io, join(cols, ","))
        for i in eachindex(d.y); println(io, join((string(getproperty(d, c)[i]) for c in cols), ",")); end
    end
end
function readcsv(path)
    m, h = readdlm(path, ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; Dict(h[j] => m[:, j] for j in eachindex(h))
end
function struct_data(tag)
    c = readcsv(joinpath(O, "data", tag * ".csv"))
    (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), id = String.(c["id"]))
end
tree() = strip(read(joinpath(O, "tree.nwk"), String))
function coordsd()
    cm = readcsv(joinpath(O, "coords.csv"))
    Dict(String(cm["id"][k]) => [Float64(cm["easting"][k]), Float64(cm["northing"][k])] for k in eachindex(cm["id"]))
end

function build(route, s)
    tag = @sprintf("%s_s%02d", route, s)
    if route in ("gauss_q3", "gauss_q4")
        q = route == "gauss_q3" ? 3 : 4
        fx = _q34_fixture(q; G = 150, m = 10, seed = 760000 + 10 * q + s)
        return tag, fx.data, _q34_formula(fx), Gaussian(), (;)
    elseif route in ("gamma_same", "nb2_same", "nb2_corr", "gamma_corr")
        fam = startswith(route, "gamma") ? :gamma : :nb2
        shape = route in ("gamma_same", "nb2_same") ? :samegroup : :corr
        case = tf_case(fam, shape; seed = 820000 + 100 * s)
        return tag, case.data, case.formula, TF_FAMS[fam], case.kw
    elseif route in ("gauss_joint", "nb2_joint", "nb2_jcross")
        fam = route == "gauss_joint" ? :gaussian : :nb2
        same = route != "nb2_jcross"
        fx = _jsw_fixture(fam; seed = 830000 + 100 * (route == "gauss_joint" ? 1 : route == "nb2_joint" ? 2 : 3) + s, same)
        f = same ?
            bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | id)), @formula(sd(id) ~ w), @formula(sd(id, sigma) ~ z)) :
            bf(@formula(y ~ x + (1 | id)), @formula(sigma ~ 1 + (1 | g)), @formula(sd(id) ~ w), @formula(sd(g, sigma) ~ z))
        return tag, fx.data, f, fam === :gaussian ? Gaussian() : NegBinomial2(), (;)
    elseif route == "gauss_phylo"
        f = bf(@formula(y ~ x + phylo(1 + x | id)), @formula(sigma ~ 1), @formula(sd(id, phylogenetic, coef(intercept)) ~ z0), @formula(sd(id, phylogenetic, coef(x)) ~ z1))
        return tag, struct_data(tag), f, Gaussian(), (; tree = tree())
    elseif route == "gauss_spatial"
        f = bf(@formula(y ~ x + spatial(1 + x | id)), @formula(sigma ~ 1), @formula(sd(id, spatial, coef(intercept)) ~ z0), @formula(sd(id, spatial, coef(x)) ~ z1))
        return tag, struct_data(tag), f, Gaussian(), (; coords = coordsd())
    elseif route == "gauss_lphylo"
        f = bf(@formula(y ~ x + phylo(1 + x | p | id)), @formula(sigma ~ 1), @formula(sd(id, phylogenetic, coef(intercept)) ~ z0), @formula(sd(id, phylogenetic, coef(x)) ~ z1))
        return tag, struct_data(tag), f, Gaussian(), (; tree = tree())
    elseif route == "gauss_lspatial"
        f = bf(@formula(y ~ x + spatial(1 + x | p | id)), @formula(sigma ~ 1), @formula(sd(id, spatial, coef(intercept)) ~ z0), @formula(sd(id, spatial, coef(x)) ~ z1))
        return tag, struct_data(tag), f, Gaussian(), (; coords = coordsd())
    end
    error("unknown route $route")
end

mkpath(joinpath(O, "data")); mkpath(joinpath(O, "julia"))
for s in s_from:s_to
    tag, d, f, fam, kw = build(route, s)
    startswith(route, "gauss_") && occursin(r"phylo|spatial", route) || write_data(joinpath(O, "data", tag * ".csv"), d)
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
            println(io, "ll,converged,seconds,msg"); println(io, "NA,error,NA,\"$(replace(sprint(showerror, e)[1:min(end, 300)], '"' => '\'', '\n' => ' '))\"")
        end
        println(tag, " ERROR ", sprint(showerror, e)[1:min(end, 400)])
    end
end
