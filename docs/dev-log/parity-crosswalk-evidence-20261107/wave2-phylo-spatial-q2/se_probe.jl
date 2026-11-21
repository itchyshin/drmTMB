include("/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad/w2ps/julia_fit.jl")
fit = fitcase("pphy")
nll = fit.nll
for h in (1e-4, 3e-4, 1e-3, 3e-3)
    H = DRModels._finite_hessian(nll, fit.theta; h = h)
    println("h=$h  se=", round.(sqrt.(diag(inv(Symmetric(H)))); sigdigits = 7))
end
