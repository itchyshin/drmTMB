# F5-tiny-n-gaussian: minimal self-contained DRModels.jl repro (data inline, from
# sweep-oct16/t4/data/gauss_n8_rNN.csv; R seed 933663568 + rep - 1, see t4_gen_data.R).
# Run: JULIA_PKG_SERVER="" JULIA_DEPOT_PATH=/home/user/.julia /home/user/jlenv/bin/julia \
#        --project=/home/user/DRModels.jl f5_min_DRModels.jl > f5_min_DRModels.out 2>&1
using DRModels, Printf, Logging
println("Julia ", VERSION, " | DRModels ", pkgversion(DRModels), " | HEAD ",
        strip(read(`git -C $(dirname(dirname(pathof(DRModels)))) rev-parse HEAD`, String)))
D = Dict(
    5 => (y = [1.158368339985550, 0.806600694097909, 3.560356323283090, 0.529824720865173, 1.784801892624800, 0.453842867106797, 0.381593567242596, 0.805037905982587],
          x = [-0.170812532495643,  0.204997306971440,  1.576741379923950, -1.232875498992810,  0.617346270085745, -0.339272911830529, -0.129132073925437, -1.097336680384540]),
    9 => (y = [1.5107489935387799, 0.0362409647360906, 1.2118940643619900, 1.9329107861367001, 0.9173653755294030, 0.8418816361793140, 0.5578298128421110, 0.5896997962328770],
          x = [ 1.3420825004491199, -0.0257711267611960,  0.9435957346402410,  0.6944443884654730,  0.4110030339203780, -0.0811043946933806, -1.8991220983335300, -0.2023051027931010]),
    28 => (y = [-0.0931334758127496,  0.6209369087256450,  0.3621800932290740,  2.4209544906212899,  1.6466020335442400, -0.4416632290049910,  1.0383969748871400,  1.6909042358182200],
          x = [-1.970747633007080, -0.908022762338984, -0.996121657858792,  2.027725569550000, -0.425139919042740, -2.112832703032380, -0.469959166651941,  0.313498865880186]),
    4 => (y = [1.929079617527810, 3.165976205526790, 2.659495356890570, 0.932591209300907, 1.506440973890160, 0.539063100149113, 0.726783902246797, 0.903113598839686],
          x = [ 0.5848607034772020,  0.9297118727210140,  0.8454904765246980, -1.0356383882578499,  0.7745679828635960,  0.6490798614687560,  0.3229625027683870, -0.0959813783918258]))
# the other (higher) local maximum, found by an engine-independent profile scan (f5_reference.R)
other = Dict(5  => [0.62897981, 1.85913573, -1.4548979, -3.0420365],
             9  => [0.57975945, 0.01155896, -1.3209085,  2.0000361],
             28 => [1.55547165, 0.42682448, -3.0166713, -2.7533529])
f = bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x))
for r in (5, 9, 28)
    fit = drm(f, Gaussian(); data = D[r])
    @printf("r%02d loglik %.5f  converged %s  is_converged %s | -nll at the other maximum %.5f\n",
            r, loglik(fit), fit.converged, is_converged(fit), -fit.nll(other[r]))
end
fit = with_logger(NullLogger()) do; drm(f, Gaussian(); data = D[4]); end
g = DRModels.ForwardDiff.gradient(fit.nll, fit.theta)
@printf("r04 loglik %.7f (engine-independent maximum 6.7247381)  converged %s | max|grad| %.2e | min log sigma %.2f\n",
        loglik(fit), fit.converged, maximum(abs, g), minimum(log.(fit.scales[:sigma])))
