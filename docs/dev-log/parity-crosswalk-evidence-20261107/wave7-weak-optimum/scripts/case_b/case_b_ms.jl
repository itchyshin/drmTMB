include("case_b_h.jl")
rest = readdlm(joinpath(HERE, "out", "r_$(KIND)_$(SEED).csv"), ',', skipstart = 1)
thR = Float64.(rest[:, 2])
@printf("R theta in Julia objective: ll=%.8f (R reports %s)\n", -nll(thR), strip(read(joinpath(HERE, "out", "r_$(KIND)_$(SEED)_ll.txt"), String)))
r = runlb(thR); report("polish from R theta", r)
for (a0, a1) in ((0.4, 0.3), (0.2, 0.1), (0.7, 0.7), (0.4, 0.05), (0.4, 0.5), (0.9, 0.9), (0.1, 0.03), (1.5, 1.5))
    t = @elapsed r = runlb(theta_start(a0, a1)); report("start $a0/$a1 ($(round(t,digits=1))s)", r)
end
