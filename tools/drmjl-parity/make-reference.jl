# Produce DRModels.jl reference values for the drmTMB parity fixtures
# (tests/testthat/test-drmjl-parity-fixtures.R).
#
# Fits every case directly through DRModels.drm_bridge on the CSVs written by
# tools/drmjl-parity/make-data.R and records logLik, coefficients and Wald SEs
# (sqrt of the vcov diagonal, on the working scale DRModels.jl reports).
# The DRModels.jl commit is written next to the values, so a stale fixture is
# visible from the file itself.
#
# Run from the package root, with a DRModels.jl checkout:
#   julia --project=/path/to/DRModels.jl tools/drmjl-parity/make-reference.jl /path/to/DRModels.jl

using DRModels
using Dates
using LinearAlgebra: diag

drmjl_path = length(ARGS) >= 1 ? ARGS[1] : error("pass the DRModels.jl checkout path")
fixture_dir = joinpath("tests", "testthat", "fixtures", "drmjl-parity")

commit = readchomp(`git -C $drmjl_path rev-parse HEAD`)
dirty = !isempty(readchomp(`git -C $drmjl_path status --porcelain --untracked-files=no`))

# Minimal numeric CSV reader: quoted header, numeric body (what write.csv emits
# for these files). Avoids a CSV.jl dependency in the DRModels.jl project.
function read_numeric_csv(path)
    lines = filter(!isempty, readlines(path))
    header = [strip(h, '"') for h in split(lines[1], ',')]
    cols = [Float64[] for _ in header]
    for line in lines[2:end]
        for (j, v) in enumerate(split(line, ','))
            push!(cols[j], parse(Float64, v))
        end
    end
    return NamedTuple{Tuple(Symbol.(header))}(Tuple(cols))
end

# case id => (family, data file stem, DRModels.jl formula string, bridge options).
# Non-Gaussian (1 | g) cases are fitted twice: with marginal = "Laplace" (the
# TMB-convention integrator, the like-for-like parity target) and with the
# DRModels.jl default `:LA` integrator (32-node adaptive Gauss-Hermite for
# these routes, DRModels.jl#1071), recorded as `<family>_re_default`.
laplace = Dict{String,Any}("marginal" => "Laplace")
default = Dict{String,Any}()
cases = [
    ("gaussian_fe", "gaussian", "y ~ x; sigma ~ x", default),
    ("gaussian_re", "gaussian", "y ~ x + (1 | g); sigma ~ 1", default),
    ("poisson_fe", "poisson", "y ~ x", default),
    ("poisson_re", "poisson", "y ~ x + (1 | g)", laplace),
    ("poisson_re_default", "poisson", "y ~ x + (1 | g)", default),
    ("nbinom2_fe", "nbinom2", "y ~ x; sigma ~ 1", default),
    ("nbinom2_re", "nbinom2", "y ~ x + (1 | g); sigma ~ 1", laplace),
    ("nbinom2_re_default", "nbinom2", "y ~ x + (1 | g); sigma ~ 1", default),
    ("beta_fe", "beta", "y ~ x; sigma ~ 1", default),
    ("beta_re", "beta", "y ~ x + (1 | g); sigma ~ 1", laplace),
    ("beta_re_default", "beta", "y ~ x + (1 | g); sigma ~ 1", default),
    ("binomial_fe", "binomial", "cbind(successes, failures) ~ x", default),
    ("binomial_re", "binomial", "cbind(successes, failures) ~ x + (1 | g)", laplace),
    ("binomial_re_default", "binomial", "cbind(successes, failures) ~ x + (1 | g)", default),
    ("student_fe", "student", "y ~ x; sigma ~ 1; nu ~ 1", default),
    ("student_re", "student", "y ~ x + (1 | g); sigma ~ 1; nu ~ 1", laplace),
    ("student_re_default", "student", "y ~ x + (1 | g); sigma ~ 1; nu ~ 1", default),
    ("gamma_fe", "gamma", "y ~ x; sigma ~ 1", default),
    ("gamma_re", "gamma", "y ~ x + (1 | g); sigma ~ 1", laplace),
    ("gamma_re_default", "gamma", "y ~ x + (1 | g); sigma ~ 1", default),
]

fmt(v) = v isa AbstractFloat ? string(Float64(v)) : string(v)
csvq(s) = "\"" * replace(string(s), "\"" => "\"\"") * "\""

rows = String[]
push!(rows, "case,family,quantity,term,value")
for (case, family, formula, options) in cases
    data = read_numeric_csv(joinpath(fixture_dir, "data-$(family).csv"))
    out = try
        drm_bridge(; formula = formula, family = family, data = data,
                   options = options)
    catch err
        msg = first(replace(sprint(showerror, err), r"\s+" => " "), 300)
        @warn "case $case failed" msg
        push!(rows, join([case, family, "error", "", csvq(msg)], ","))
        continue
    end
    push!(rows, join([case, family, "loglik", "", fmt(out["loglik"])], ","))
    push!(rows, join([case, family, "converged", "", fmt(out["converged"])], ","))
    push!(rows, join([case, family, "marginal", "", out["marginal"]], ","))
    names = out["coef_names"]
    coefs = out["coefficients"]
    se = sqrt.(max.(diag(out["vcov"]), 0.0))
    for (k, nm) in enumerate(names)
        push!(rows, join([case, family, "coef", csvq(nm), fmt(coefs[k])], ","))
    end
    vnames = out["vcov_names"]
    for (k, nm) in enumerate(vnames)
        push!(rows, join([case, family, "se", csvq(nm), fmt(se[k])], ","))
    end
end

open(joinpath(fixture_dir, "reference.csv"), "w") do io
    for r in rows
        println(io, r)
    end
end

open(joinpath(fixture_dir, "PROVENANCE"), "w") do io
    println(io, "drmjl_commit: ", commit)
    println(io, "drmjl_dirty: ", dirty)
    println(io, "julia_version: ", VERSION)
    println(io, "generated: ", Dates.format(now(), "yyyy-mm-dd"))
    println(io, "generator: tools/drmjl-parity/make-reference.jl (DRModels.drm_bridge)")
    println(io, "data: tools/drmjl-parity/make-data.R")
end
