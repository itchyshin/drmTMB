using DRModels, DelimitedFiles
include("agree_defs.jl")   # defs only
function theta_of(file, sid, seed)
    for l in eachline(file)
        f = split(l, '\t'); (f[1] == sid && f[2] == string(seed)) && return parse.(Float64, split(f[6], ","))
    end
end
println("shape\tseed\tJulia_nll(thJ)\tJulia_nll(thR)\tJulia_ll(thJ)\tJulia_ll(thR)\tllJ_reported\tllR_reported")
for (sid, seed) in (("B2", 2), ("B5", 9), ("B5", 10), ("B5", 0))
    cell = Dict(split(l, '\t')[1] => split(l, '\t')[2] for l in eachline("shapes.txt"))[sid]
    p = split(cell, '|'); fam, kind, lab, q, pat = p[1], p[2], parse(Int, p[3][4:end]), parse(Int, p[4][2:end]), p[5][4:end]
    d = load_data(fam, kind, seed)
    fit = drm(build(fam, kind, lab, q, pat), fam_of(fam); data = d, kwargs_for(kind)...)
    thJ = theta_of("res/julia_all.tsv", sid, seed); thR = theta_of("res/r_all.tsv", sid, seed)
    println(join((sid, seed, fit.nll(fit.theta), fit.nll(thR), -fit.nll(fit.theta), -fit.nll(thR), loglikelihood(fit), "see r_all"), "\t"))
end
