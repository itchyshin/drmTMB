# Repro: a `missing` in the (1 | g) grouping column becomes one extra pooled
# random-effect level, silently. DRModels.jl f71b2923. Run from the drmTMB repo root:
#   julia --project=/path/to/DRModels.jl sweep-oct16/t5/repro/repro_missing_group.jl
include(joinpath(@__DIR__, "common.jl"))
rows = 1:8:80                                   # 10 rows, one in each of g01..g10
for fam in ("gaussian", "poisson", "gamma")
    d = t5_read("$(fam)_y00_x00")
    y, x, g = Float64.(d.y), Float64.(d.x), d.g
    gm = Vector{Union{Missing,String}}(g); gm[rows] .= missing
    gl = copy(g); gl[rows] .= "__NA__"             # an explicit 26th level
    keep = setdiff(eachindex(y), rows)
    fm = fam_of(fam); kw = fam == "gaussian" ? (;) : (; marginal = :Laplace)
    try_fit("$fam  g with 10 missing", () -> drm(F(fam), fm; data = (; y, x, g = gm), kw...))
    try_fit("$fam  g with literal \"__NA__\" level", () -> drm(F(fam), fm; data = (; y, x, g = gl), kw...))
    try_fit("$fam  those 10 rows dropped", () -> drm(F(fam), fm; data = (; y = y[keep], x = x[keep], g = g[keep]), kw...))
    if fam == "gaussian"
        fit = drm(F(fam), fm; data = (; y, x, g = gm))
        println("gaussian  length(ranef(fit)[:g]) = ", length(ranef(fit)[:g]), "  (data has 25 non-missing groups)")
    end
end
