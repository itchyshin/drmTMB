# Julia side of the wave-9 agreement study. Usage: julia --project=<env> agree.jl <jobs.tsv> <k> <N> <out.tsv>
# Runs jobs k, k+N, k+2N, ... (1-based). Output: one tab-separated line per job.
using DRModels, DelimitedFiles, Logging, Printf
const DD = get(ENV, "W9_DATA", "data")
jobs = nothing
const NWK = strip(read(joinpath(DD, "tree.nwk"), String))
const COORDS = let m = readdlm(joinpath(DD, "coords.csv"), ',', Any; skipstart = 1)
    Dict(String(m[i, 1]) => [Float64(m[i, 2]), Float64(m[i, 3])] for i in 1:size(m, 1)) end
const IDS = String.(vec(readdlm(joinpath(DD, "A_ids.csv"), ',', Any; skipstart = 1)))
const AMAT = Matrix{Float64}(readdlm(joinpath(DD, "A.csv"), ',', Float64))
fam_of(f) = f == "gaussian" ? Gaussian() : f == "poisson" ? Poisson() : f == "nb2" ? NegBinomial2() :
    f == "gamma" ? DRModels.Gamma() : f == "binomial" ? Binomial(:logit) : error("family $f")
has_sigma(f) = !(f in ("poisson", "binomial"))
function load_data(fam, kind, seed)
    file = seed == 0 ? "data_$(fam)_$(kind).csv" : "data_$(fam)_$(kind)_s$(seed).csv"
    m, h = readdlm(joinpath(DD, file), ',', Any; header = true); h = String.(vec(h))
    col(n) = m[:, findfirst(==(n), h)]
    (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")),
       z = Float64.(col("z")), g = String.(col("g")), g2 = String.(col("g2")))
end
const CNAME = ["intercept", "x1", "x2", "x3"]
const LEVEL = Dict("animal" => "animal", "relmat" => "relmat", "phylo" => "phylogenetic", "spatial" => "spatial")
mkf(s) = eval(Meta.parse("@formula(" * s * ")"))
function build(fam, kind, lab, q, pat)
    bar = join(["1", "x1", "x2", "x3"][1:q], " + "); labs = lab == 1 ? " | p | " : " | "
    inner = bar * labs * "g"
    re = "$kind($inner)"
    mu = mkf("y ~ x1 + x2 + x3 + $re")
    sel = pat == "none" ? Int[] : collect(1:q); rhs = pat == "one" ? "1" : "z"
    sds = [mkf("sd(g, $(LEVEL[kind]), coef($(CNAME[j]))) ~ $rhs") for j in sel]
    parts = Any[mu]; has_sigma(fam) && push!(parts, mkf("sigma ~ 1"))
    return bf(parts..., sds...)
end
kwargs_for(kind) = kind == "phylo" ? (; tree = NWK) : kind == "spatial" ? (; coords = COORDS) :
    kind == "animal" ? (; A = AMAT, ids = IDS) : (; K = AMAT)
clean(x) = replace(String(x), '\t' => ' ', '\n' => ' ')
