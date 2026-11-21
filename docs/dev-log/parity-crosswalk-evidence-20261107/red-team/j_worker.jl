# usage: julia --project=env j_worker.jl cells.tsv start out.tsv
using DRModels, DelimitedFiles, Logging
import Distributions
const RT = dirname(abspath(ARGS[1])); const START = parse(Int, ARGS[2]); const OUT = ARGS[3]
VIA = ""
const CELLS = readdlm(ARGS[1], '\t', Any; header = true)[1]
clean(s) = replace(replace(String(s), r"[\t\r\n]+" => " "), r"\s+" => " ")
function readdata(path)
    L = readlines(path); hdr = split(L[1], ','); rows = [split(l, ',') for l in L[2:end]]
    cols = Dict{Symbol,Any}()
    for (j, h) in enumerate(hdr)
        raw = [strip(r[j], '"') for r in rows]; nm = Symbol(strip(h, '"'))
        if nm == :g; cols[nm] = String.(raw)
        elseif any(==("NA"), raw); cols[nm] = Union{Missing,Float64}[r == "NA" ? missing : parse(Float64, r) for r in raw]
        else cols[nm] = Float64.(parse.(Float64, raw)); end
    end
    return (; (k => cols[k] for k in (:y, :x, :z, :z0, :z1, :g))...)
end
function readmat(path); M, h = readdlm(path, ',', Float64; header = true); M; end
famJ(f) = f == "gaussian" ? Gaussian() : f == "poisson" ? Poisson() : f == "nb2" ? NegBinomial2() :
          f == "gamma" ? Gamma() : Binomial()
function formulaJ(route, fam)
    nuis = fam in ("gaussian", "nb2", "gamma")
    mu = route == "ord" ? @formula(y ~ x + (1 | g)) : route == "ordq2" ? @formula(y ~ x + (1 + x | g)) :
         route == "animal" ? @formula(y ~ x + animal(1 | g)) : route == "phylo" ? @formula(y ~ x + phylo(1 | g)) :
         @formula(y ~ x + spatial(1 | g))
    sds = route == "ord" ? [@formula(sd(g) ~ z)] :
          route == "ordq2" ? [@formula(sd(g, coef(intercept)) ~ z0), @formula(sd(g, coef(x)) ~ z1)] :
          route == "animal" ? [@formula(sd(g, animal) ~ z)] : route == "phylo" ? [@formula(sd(g, phylogenetic) ~ z)] :
          [@formula(sd(g, spatial) ~ z)]
    return nuis ? bf(mu, @formula(sigma ~ 1), sds...) : bf(mu, sds...)
end
function runcell(ds, route, fam)
    dir = joinpath(RT, "cells", ds)
    data = readdata(joinpath(dir, "data_$(route)_$(fam).csv"))
    aids = String.(strip.(readlines(joinpath(dir, "A_ids.csv"))[2:end], '"'))
    kw = if route == "animal"
        startswith(ds, "d21") ? (; A = readmat(joinpath(dir, "A.csv"))) : (; A = readmat(joinpath(dir, "A.csv")), ids = aids)
    elseif route == "phylo"; (; tree = strip(read(joinpath(dir, "tree.nwk"), String)))
    elseif route == "spatial"
        c, _ = readdlm(joinpath(dir, "coords.csv"), ',', Any; header = true)
        (; coords = Dict(String(strip(String(c[k, 1]), '"')) => [Float64(c[k, 2]), Float64(c[k, 3])] for k in 1:size(c, 1)))
    else (;) end
    try
        return drm(formulaJ(route, fam), famJ(fam); data, kw...)
    catch e
        # the Binomial spatial route did not resolve a labelled Dict of coordinates (recorded as a finding);
        # retry with a first-seen-order matrix so the rest of the cell is still informative
        if route == "animal" && e isa MethodError && haskey(kw, :ids)
            kw3 = (; A = kw.A)
            fit = drm(formulaJ(route, fam), famJ(fam); data, kw3...)
            global VIA = "bare-A fallback after MethodError on `ids` kwarg (Binomial animal route does not accept ids)"
            return fit
        end
        if route == "spatial" && e isa ErrorException && occursin("neither", e.msg)
            seen = unique(data.g); cd = kw.coords
            kw2 = (; coords = reduce(vcat, [permutedims(cd[s]) for s in seen if haskey(cd, s)]))
            fit = drm(formulaJ(route, fam), famJ(fam); data, kw2...)
            global VIA = "matrix-fallback after: " * first(split(e.msg, '\n'))
            return fit
        end
        rethrow()
    end
end
for r in ("ord", "ordq2", "animal", "phylo", "spatial")
    try; runcell("d00_baseline", r, "gaussian"); catch; end
end
touch(OUT * ".ready")
for i in START:min(parse(Int, ARGS[4]), size(CELLS, 1))
    id, ds, route, fam = String(CELLS[i, 1]), String(CELLS[i, 2]), String(CELLS[i, 3]), String(CELLS[i, 4])
    global VIA = ""; t0 = time(); io = IOBuffer(); status = "fit"; cls = ""; msg = ""; ll = NaN; conv = ""; nob = ""; seok = ""; cf = ""
    res = try
        with_logger(SimpleLogger(io, Logging.Warn)) do; runcell(ds, route, fam); end
    catch e
        e
    end
    if res isa Exception
        status = "error"; cls = string(typeof(res)); msg = clean(sprint(showerror, res))[1:min(end, 700)]
    else
        fit = res
        ll = loglikelihood(fit); conv = string(fit.converged)
        nob = try string(nobs(fit)) catch; "NA" end
        seok = try string(all(isfinite, stderror(fit))) catch; "NA" end
        cf = try join(["$(first(b))=" * join(round.(vec(coef(fit, first(b))); sigdigits = 8), ",") for b in fit.blocks], ";") catch; "" end
    end
    el = round(time() - t0; digits = 2)
    w = clean(replace(String(take!(io)), r"┌ Warning: |└ @ .*|│" => " "))
    open(OUT, "a") do f
        println(f, join([id, "J", status, cls, conv, ll, nob, el, seok, clean(cf), w[1:min(end, 400)], isempty(msg) ? clean(VIA)[1:min(end,300)] : msg], '\t'))
    end
end
