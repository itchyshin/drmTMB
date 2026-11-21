# Native Julia DRModels runner for the refusal-gap map. One process, many cells, one result line per cell.
# Usage: julia --project=<env> run_julia.jl <cells.tsv> <idlist.txt> <start_index> <outfile>
# Env: FUZZ_DATA (data dir).
using DRModels, DelimitedFiles, Logging, Printf
const DD = get(ENV, "FUZZ_DATA", "data")
cells_file, idfile, start, outfile = ARGS[1], ARGS[2], parse(Int, ARGS[3]), ARGS[4]
idlist = readlines(idfile)

rows = readdlm(cells_file, '\t', Any; header = false)
const CELLS = Dict{String,NamedTuple}()
for r in 2:size(rows, 1)
    CELLS[String(rows[r, 1])] = (; family = String(rows[r, 2]), kind = String(rows[r, 3]), lab = Int(rows[r, 4]),
        q = Int(rows[r, 5]), pat = String(rows[r, 6]), cm = Int(rows[r, 7]), est = String(rows[r, 8]))
end

const NWK = strip(read(joinpath(DD, "tree.nwk"), String))
const COORDS = let m = readdlm(joinpath(DD, "coords.csv"), ',', Any; skipstart = 1)
    Dict(String(m[i, 1]) => [Float64(m[i, 2]), Float64(m[i, 3])] for i in 1:size(m, 1))
end
const IDS = String.(vec(readdlm(joinpath(DD, "A_ids.csv"), ',', Any; skipstart = 1)))
const AMAT = Matrix{Float64}(readdlm(joinpath(DD, "A.csv"), ',', Float64))

fam_of(f) = f == "gaussian" ? Gaussian() : f == "poisson" ? Poisson() : f == "nb2" ? NegBinomial2() :
    f == "gamma" ? DRModels.Gamma() : f == "binomial" ? Binomial(:logit) : f == "beta" ? Beta() :
    f == "lognormal" ? LogNormal() : f == "student" ? Student() : f == "tweedie" ? Tweedie() : error("family $f")
has_sigma(f) = !(f in ("poisson", "binomial"))

const _DATA = Dict{String,Any}()
function load_data(fam, kind)
    key = "$(fam)_$(kind)"
    get!(_DATA, key) do
        m, h = readdlm(joinpath(DD, "data_$(key).csv"), ',', Any; header = true)
        h = String.(vec(h))
        col(n) = m[:, findfirst(==(n), h)]
        (; y = Float64.(col("y")), x1 = Float64.(col("x1")), x2 = Float64.(col("x2")), x3 = Float64.(col("x3")),
           z = Float64.(col("z")), z2 = Float64.(col("z2")), g = String.(col("g")), g2 = String.(col("g2")))
    end
end

const CNAME = ["intercept", "x1", "x2", "x3"]
const LEVEL = Dict("animal" => "animal", "relmat" => "relmat", "phylo" => "phylogenetic", "spatial" => "spatial")
mkf(s) = eval(Meta.parse("@formula(" * s * ")"))

function build(cl)
    q, kind = cl.q, cl.kind
    bar = join(["1", "x1", "x2", "x3"][1:q], " + ")
    lab = (cl.lab == 1 || cl.cm == 1) ? " | p | " : " | "
    inner = bar * lab * "g"
    re = kind == "slope" ? "(0 + x1 | g)" : kind == "indep" ? "(1 | g)" * join([" + (0 + $v | g)" for v in ["x1", "x2", "x3"][1:q-1]]) :
         kind == "ordinary" ? "($inner)" : kind == "crossed" ? "($inner) + (1 | g2)" :
         kind == "animal" ? "animal($inner)" : kind == "relmat" ? "relmat($inner)" :
         kind == "phylo" ? "phylo($inner)" : "spatial($inner)"
    mu = mkf("y ~ x1 + x2 + x3 + $re")
    sel = cl.pat == "none" ? Int[] : cl.pat in ("one", "z") ? collect(1:q) : cl.pat == "first" ? [1] : [q]
    rhs = cl.pat == "one" ? "1" : "z"
    lv = haskey(LEVEL, kind) ? ", " * LEVEL[kind] : ""
    sds = Any[]
    for j in sel
        cf = kind == "slope" ? ", coef(x1)" : q == 1 ? "" : ", coef($(CNAME[j]))"
        push!(sds, mkf("sd(g$lv$cf) ~ $rhs"))
    end
    if kind == "crossed" && !(cl.pat in ("none", "last"))
        push!(sds, mkf("sd(g2) ~ " * (cl.pat == "one" ? "1" : "z2")))
    end
    parts = Any[mu]
    has_sigma(cl.family) && push!(parts, cl.cm == 1 ? mkf("sigma ~ 1 + (1 | p | g)") : mkf("sigma ~ 1"))
    return bf(parts..., sds...)
end

# Optional follow-up mode: FUZZ_MARGINAL=Laplace re-runs cells with drmTMB's Laplace objective (documented opt-in).
const EXTRA_KW = haskey(ENV, "FUZZ_MARGINAL") ? (; marginal = Symbol(ENV["FUZZ_MARGINAL"])) : (;)
# FUZZ_COORDS=matrix passes `coords` as a G x 2 Matrix (rows in A_ids order) instead of a Dict: some routes
# accept only one of the two formats.
const COORDS_MAT = reduce(vcat, [permutedims(COORDS[i]) for i in IDS])
function kwargs_for(kind)
    kind == "phylo" ? (; tree = NWK) : kind == "spatial" ? (; coords = get(ENV, "FUZZ_COORDS", "dict") == "matrix" ? COORDS_MAT : COORDS) :
    kind == "animal" ? (; A = AMAT, ids = IDS) : kind == "relmat" ? (; K = AMAT) : (;)
end

struct CaptureLogger <: Logging.AbstractLogger
    msgs::Vector{String}
end
Logging.min_enabled_level(::CaptureLogger) = Logging.Warn
Logging.shouldlog(::CaptureLogger, args...) = true
Logging.catch_exceptions(::CaptureLogger) = true
function Logging.handle_message(l::CaptureLogger, level, message, args...; kwargs...)
    level >= Logging.Warn && push!(l.msgs, string(message))
    return nothing
end

function first_line(s)
    ls = [strip(replace(l, '\t' => ' ')) for l in split(String(s), '\n')]
    ls = filter(!isempty, ls)
    isempty(ls) ? "" : first(ls[1], 400)
end
full_msg(s) = first(strip(replace(String(s), r"\s+" => " ")), 600)
clean(x) = replace(String(x), '\t' => ' ', '\n' => ' ')

function mm_msg(e::MethodError)
    a = e.args
    if !isempty(a) && a[1] isa NamedTuple
        return "MethodError: no method matching keyword call " * string(a[2]) * " with keywords " * string(keys(a[1]))
    end
    return "MethodError: no method matching " * string(e.f) * "(" * join(string.(typeof.(a)), ", ") * ")"
end

function run_one(id)
    cl = CELLS[id]
    d = load_data(cl.family, cl.kind in ("indep", "slope") ? "ordinary" : cl.kind)
    lg = CaptureLogger(String[])
    t0 = time()
    local fit, err = nothing, nothing
    Logging.with_logger(lg) do
        try
            f = build(cl)
            kw = merge(kwargs_for(cl.kind), EXTRA_KW)
            if cl.est == "REML"
                fit = drm(f, fam_of(cl.family); data = d, method = :REML, kw...)
            else
                fit = drm(f, fam_of(cl.family); data = d, kw...)
            end
        catch e
            err = (e, catch_backtrace())
        end
    end
    secs = time() - t0
    w1 = isempty(lg.msgs) ? "" : first_line(lg.msgs[1])
    if err !== nothing
        e = err[1]
        msg = e isa MethodError ? mm_msg(e) : first_line(sprint(showerror, e))
        fullm = e isa MethodError ? msg : full_msg(sprint(showerror, e))
        loc = ""
        if !(e isa ArgumentError)
            bt = err[2]
            for fr in Base.stacktrace(bt)
                s = string(fr.file)
                if occursin("DRModels", s) || occursin("/src/", s)
                    loc = basename(s) * ":" * string(fr.line); break
                end
            end
        end
        return ("ERROR", string(typeof(e)), msg, fullm, "", "", loc == "" ? "" : "at=" * loc, @sprintf("%.2f", secs), w1)
    end
    ll = try Float64(loglikelihood(fit)) catch; NaN end
    conv = try fit.converged catch; missing end
    sefin = try all(isfinite, stderror(fit)) catch; missing end
    ok = isfinite(ll) && conv === true
    return (ok ? "FITS" : "NONCONVERGED", "", "", "", @sprintf("%.10f", ll), string(conv),
            "se_finite=$(sefin);npar=$(try length(fit.theta) catch; -1 end)", @sprintf("%.2f", secs), w1)
end

open(outfile, "a") do io
    for i in start:length(idlist)
        id = idlist[i]
        println(io, "S\t", i, "\t", id); flush(io)
        r = try run_one(id) catch e
            ("RUNNER_ERROR", string(typeof(e)), first_line(sprint(showerror, e)), full_msg(sprint(showerror, e)), "", "", "", "", "")
        end
        println(io, "R\t", i, "\t", id, "\t", join(clean.(collect(r)), "\t")); flush(io)
    end
end
