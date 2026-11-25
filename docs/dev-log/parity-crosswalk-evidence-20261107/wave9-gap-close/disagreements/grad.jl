using DRModels, DelimitedFiles, LinearAlgebra
include("agree_defs.jl")
cell = Dict(split(l, '\t')[1] => split(l, '\t')[2] for l in eachline("shapes.txt"))
println("shape\tseed\tmax|grad(thJ)|\tnewton_decrement\tmin eig Hess\tll")
for (sid, seed) in (("B2", 2), ("B5", 9), ("B5", 10))
    p = split(cell[sid], '|'); fam, kind, lab, q, pat = p[1], p[2], parse(Int, p[3][4:end]), parse(Int, p[4][2:end]), p[5][4:end]
    fit = drm(build(fam, kind, lab, q, pat), fam_of(fam); data = load_data(fam, kind, seed), kwargs_for(kind)...)
    g = DRModels.gradient(fit); H = DRModels.hessian(fit)
    println(join((sid, seed, maximum(abs, g), g' * (H \ g), minimum(eigvals(Symmetric(H))), loglikelihood(fit)), "\t"))
end
