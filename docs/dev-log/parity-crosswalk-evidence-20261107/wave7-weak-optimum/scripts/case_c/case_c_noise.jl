include("case_c_h.jl")
th = [-0.15081759190265276, 0.1566312918318081, -1.1085606445208331, 0.013446604913960233, -8.980235482237966, -7.894441996974677, -10.00019268598538]
f0 = nll(th)
for j in (1, 6)
  println("coord ", j)
  for t in range(-4e-4, 4e-4; length = 17)
    e = zeros(7); e[j] = t
    last_b .= 0; vc = nll(th .+ e)
    @printf("  t=%+.1e  f-f0=%+.3e\n", t, vc - f0)
  end
end
