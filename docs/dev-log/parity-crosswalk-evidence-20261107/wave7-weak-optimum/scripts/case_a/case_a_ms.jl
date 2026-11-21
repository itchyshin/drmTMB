include("case_a_h.jl")
for (a0, a1) in ((0.4, 0.25), (0.7, 0.7), (0.2, 0.1), (0.4, 0.5), (0.4, 0.05), (1.0, 1.0))
    t = @elapsed r = runlb(theta_start(a0, a1))
    report("start sd0=$a0 sd1=$a1 (" * string(round(t, digits=1)) * "s)", r)
end
