# R-vs-Julia agreement, two-field Gamma/NB2 SD regression. Data come from the
# fixtures in test/test_gamma_nb2_twofield_sd.jl (one dataset per shape).
using DRModels, DelimitedFiles, LinearAlgebra, Random
const WT = ARGS[1]; const O = ARGS[2]
s = read(joinpath(WT, "test/test_gamma_nb2_twofield_sd.jl"), String)
include_string(Main, s[1:first(findfirst("for (fam, shape)", s))-1])
for (fam, shape) in ((:nb2, :samegroup), (:gamma, :samegroup), (:gamma, :crossed),
                     (:gamma, :ordrelmat), (:gamma, :ordanimal), (:gamma, :relmatq2),
                     (:nb2, :crossed), (:nb2, :ordrelmat), (:gamma, :labanimal),
                     (:gamma, :labrelmat), (:nb2, :labanimal), (:nb2, :corr))
    tag = "$(fam)_$(shape)"; dir = joinpath(O, tag); mkpath(dir)
    case = tf_case(fam, shape); d = case.data
    cols = collect(keys(d))
    open(joinpath(dir, "data.csv"), "w") do io
        println(io, join(cols, ","))
        for i in eachindex(d.y); println(io, join((repr(getproperty(d, c)[i]) |> x -> replace(x, "\"" => "") for c in cols), ",")); end
    end
    if !isempty(case.kw)
        C = first(values(case.kw)); writedlm(joinpath(dir, "K.csv"), C, ',')
        lab = shape in (:relmatq2, :labanimal, :labrelmat) ? unique(d.g) : unique(d.p)
        open(joinpath(dir, "K_ids.csv"), "w") do io; println(io, "id"); foreach(x -> println(io, x), lab); end
    end
    t = @elapsed fit = drm(case.formula, TF_FAMS[fam]; data = d, case.kw...)
    targets = DRModels._sd_target_parts(case.formula)
    blocks = [:mu, :sigma, [DRModels._sd_target_block(t.target; disambiguate = true) for t in targets]...]
    names_ = ["mu", "sigma", "sd1", "sd2", "recov"]
    any(p -> p.first === :recov, fit.blocks) && push!(blocks, :recov)
    se = stderror(fit); est = coef(fit)
    open(joinpath(dir, "julia_coef.csv"), "w") do io
        println(io, "block,k,est,se")
        for (bi, b) in enumerate(blocks)
            r = fit.blocks[findfirst(p -> p.first === b, fit.blocks)].second
            for (k, j) in enumerate(r); println(io, "$(names_[bi]),$k,$(repr(est[j])),$(repr(se[j]))"); end
        end
    end
    open(joinpath(dir, "julia_ll.txt"), "w") do io; println(io, repr(loglikelihood(fit))); println(io, fit.converged); end
    println(tag, " t=", round(t, digits = 2), " conv=", fit.converged, " ll=", loglikelihood(fit))
end
