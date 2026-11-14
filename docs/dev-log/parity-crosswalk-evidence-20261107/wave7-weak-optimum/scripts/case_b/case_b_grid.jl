include("case_b_h.jl")
function go()
    for (i1, s1) in ((-1.5, -2.0), (-1.5, 2.0), (-1.5, -1.0), (-1.5, 1.0), (-3.0, -2.0), (-3.0, 2.0), (-0.7, -1.5), (-0.7, 1.5))
        th0 = theta_start(0.4, 0.3); th0[5] = i1; th0[6] = s1
        t = @elapsed r = runlb(th0); report("slope-sd start ($i1,$s1)", r)
    end
end
go()
