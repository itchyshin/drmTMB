include("case_a_h.jl")
r = runlb(theta0; store = true)
report("default start", r)
for t in r.trace; @printf("%3d f=%.8f gn=%.2e th=%s\n", t.iteration, t.value, t.g_norm, string(round.(t.metadata["x"], digits=2))); end
