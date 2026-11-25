include("case_a_h.jl")
# usage: SEED=<unused> julia case_a_all.jl from to out.csv
s_from, s_to, outf = parse(Int, ARGS[1]), parse(Int, ARGS[2]), ARGS[3]
starts = [(0.4, 0.25), (0.7, 0.7), (0.2, 0.1), (0.4, 0.05)]
function load_seed(s)
    global tag = @sprintf("nb2_phylo_s%03d", s)
    m, h = readdlm(joinpath(HERE, "data", tag * ".csv"), ',', Any; header = true)
    h = [strip(String(x), '"') for x in vec(h)]; c = Dict(h[j] => m[:, j] for j in eachindex(h))
    global d = (; y = Float64.(c["y"]), x = Float64.(c["x"]), z0 = Float64.(c["z0"]), z1 = Float64.(c["z1"]), g = String.(c["g"]))
    global y = d.y; global x = d.x
    global gidx = D._structured_q2_kernel(:phylo, :g, d.g; tree, K = nothing, A = nothing, coords = nothing, who = "h")[2]
    global zg0 = zeros(G); global zg1 = zeros(G); for i in eachindex(y); zg0[gidx[i]] = d.z0[i]; zg1[gidx[i]] = d.z1[i]; end
    global Z0 = hcat(ones(G), zg0); global Z1 = hcat(ones(G), zg1)
    global Xmu = hcat(ones(length(y)), x)
    global aux_from, beta0, logsigma0 = D._nb2_laplace_setup(y, Xmu)
    global last_b = zeros(2G)
end
open(outf, "w") do io
    println(io, "seed,start,f,conv_grad,gmax_n,iters,minsd,theta")
    for s in s_from:s_to
        load_seed(s)
        for (k, (a0, a1)) in enumerate(starts)
            th0 = theta_start(a0, a1)
            r = try runlb(th0) catch e; println(io, "$s,$k,NA,NA,NA,NA,NA,err"); continue end
            th = Optim.minimizer(r); gf = zeros(7); grad!(gf, th)
            minsd = min(minimum(exp.(Z0 * th[4:5])), minimum(exp.(Z1 * th[6:7])))
            @printf(io, "%d,%d,%.10f,%s,%.3e,%d,%.3e,\"%s\"\n", s, k, Optim.minimum(r), maximum(abs, gf)/length(y) <= 1e-6, maximum(abs, gf)/length(y), Optim.iterations(r), minsd, join(round.(th, digits=4), ";"))
        end
        flush(io)
    end
end
