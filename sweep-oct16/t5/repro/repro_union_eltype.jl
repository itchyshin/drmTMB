# Repro: a continuous predictor stored as Vector{Union{Missing,Float64}} that
# holds NO missing value is dummy-coded as a factor (one mu coefficient per
# distinct value). DRModels.jl f71b2923. Run from the drmTMB repo root:
#   julia --project=/path/to/DRModels.jl sweep-oct16/t5/repro/repro_union_eltype.jl
include(joinpath(@__DIR__, "common.jl"))
U(v) = Vector{Union{Missing,eltype(v)}}(v)
for fam in ("gaussian", "poisson", "gamma")
    d = t5_read("$(fam)_y00_x00")              # no missing values anywhere
    y, x, g = Float64.(d.y), Float64.(d.x), d.g
    fm = fam_of(fam)
    try_fit("$fam  x::Vector{Float64}",              () -> drm(F(fam), fm; data = (; y, x, g)))
    try_fit("$fam  x::Vector{Union{Missing,Float64}}", () -> drm(F(fam), fm; data = (; y, x = U(x), g)))
    try_fit("$fam  drm_listwise(Union columns)",    () -> (f = F(fam); drm(f, fm; data = drm_listwise(f, (; y = U(y), x = U(x), g = U(g))))))
    xr = round.(x)                              # few distinct values: plausible-looking fit
    try_fit("$fam  round(x)::Vector{Float64}",       () -> drm(F(fam), fm; data = (; y, x = xr, g)))
    try_fit("$fam  round(x)::Union{Missing,Float64}", () -> drm(F(fam), fm; data = (; y, x = U(xr), g)))
end
