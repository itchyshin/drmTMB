# R6: Ayumi all-species fixed-alpha receipt

R6 reproduces the local `eco-climatic-rules` source preparation: join
Delhey's species-level climate records to passerine AVONET traits, centre
`log(Mass)`, standardise annual temperature and precipitation, match the
Hackett tree, replace non-positive/missing edges by the source's deterministic
median-edge epsilon, and resolve polytomies with seed 42. The fit is

```r
bf(
  c_body_mass_g ~ precip_z + I(precip_z^2) + temp_z + I(temp_z^2) +
    phylo(1 | TipLabel, tree = tree, model = "ou"),
  sigma ~ temp_z + precip_z
)
```

with `alpha_mu` fixed at the R5 grid *divided by the common root-to-tip tree
depth*, so the assumptions are comparable to R5's depth-one fixture; BM omits
`model = "ou"`. There is no
sigma-side OU field or free alpha. This is a sensitivity receipt only.
