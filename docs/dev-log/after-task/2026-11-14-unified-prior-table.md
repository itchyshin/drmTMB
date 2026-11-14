# Unified prior table

The table adapter converts supported fixed-effect and Gaussian random-intercept SD priors to existing prior specifications. Gamma table parameters are mean and shape. Unsupported targets and overlapping selectors are rejected. Updates replay resolved targets rather than expanding selectors again.

At R source `d5bd21009`, the full Totoro check passed all four shards. Each reported one spelling NOTE; the four test logs recorded 117 warnings and 709 skips. Grouped warning messages matched the earlier foundation run; grouped skip-reason counts differed by one additional opt-in live-bridge skip. The live bridge was exercised separately. The earlier full run failed the skip-census check; the census was refreshed in `d5bd21009` and that failure was retained.

Independent dense-oracle tests covered 150 objective, gradient and Hessian points and 12 fitted comparisons in each native package. An instrumented test of R-marshalled payloads checked another 150 two-intercept points and 30 single-intercept points; it bypassed public bridge result serialization. The live R-to-Julia fitted-result bridge passed 38 checks at R `d5bd21009` and Julia `e4fee23c8`. A glmmTMB 1.1.14 comparison matched on one fixture with verified numeric SD indices; its named selectors mapped both SD priors to the first coordinate in this fixture.

The C17 compatibility run at `2608f81` reproduced all 12 attempts and three summaries. Its five recorded source files remain unchanged at `d5bd21009`; ledger equivalence and the generated-output check pass. This does not widen the certified model-15 claim.

This slice is penalized maximum likelihood, not posterior sampling. Random slopes, correlation priors and unsupported families remain outside its scope. Julia's corrected Linux suite passed on `164068f4f`, with warnings and skips including R parity. A synthetic Julia current-main combination passed focused tests; a full current-main suite remains unverified.
