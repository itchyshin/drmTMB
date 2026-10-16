# F2 twin check: DRModels.jl on the three beta_phi1e4 grid datasets that drmTMB flags (reps 15, 48, 50)
# Run from this directory:
#   JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia --project=/home/user/DRModels.jl f2_julia.jl > f2_julia.out 2>&1
using DRModels, Printf, InteractiveUtils
function read_rcsv(path)
    ls = readlines(path); hdr = [strip(h, '"') for h in split(ls[1], ',')]
    cols = [String[] for _ in hdr]
    for l in ls[2:end]; isempty(l) && continue; for (j, v) in enumerate(split(l, ',')); push!(cols[j], strip(v, '"')); end; end
    Dict(Symbol(h) => cols[j] for (j, h) in enumerate(hdr))
end
for r in (15, 48, 50)
    d = read_rcsv(joinpath("..", "..", "data", @sprintf("beta_phi1e4_r%02d.csv", r)))
    y = parse.(Float64, d[:y]); x = parse.(Float64, d[:x])
    fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Beta(); data = (; y, x))
    chk = check_drm(fit)
    @printf("rep %d: converged=%s  is_converged=%s  logLik=%.10f  coef=%s  max|grad|=%.2e\n",
            r, fit.converged, is_converged(fit), loglik(fit), string(round.(coef(fit), digits = 9)), chk.max_abs_grad)
end
versioninfo()
println("DRModels ", pkgversion(DRModels), " git HEAD ", strip(read(`git -C /home/user/DRModels.jl rev-parse HEAD`, String)))
