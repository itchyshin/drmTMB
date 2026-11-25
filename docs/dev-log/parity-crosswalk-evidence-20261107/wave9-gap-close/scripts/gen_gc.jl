using Random, LinearAlgebra
import Distributions, ForwardDiff
using SpecialFunctions
using DRModels, Test
src = read(joinpath(ARGS[1], "test/test_gap_close_q2.jl"), String)
i = findfirst("@testset \"gap close", src)
eval(Meta.parse("begin\n" * src[1:first(i)-1] * "\nend"))
nwk, ids, Cphy = _gc_tree(); xy, Csp = _gc_grid(length(ids))
_gc_generate(Cphy, ids, joinpath(ARGS[1], "test/fixtures/gap_close/gamma_phylo.tsv"))
_gc_generate(Csp, ids, joinpath(ARGS[1], "test/fixtures/gap_close/gamma_spatial.tsv"); seed = 20261109)
println("done")
