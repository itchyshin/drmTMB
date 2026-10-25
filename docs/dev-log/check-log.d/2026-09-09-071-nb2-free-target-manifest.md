# NB2 ordinary-RI free-target manifest

The frozen NB2 RI manifest previously listed both the free log-link parameter
`fixef:sigma:(Intercept)` and its derived response-scale alias `sigma`. The
latter is `exp(fixef:sigma:(Intercept))`, so it is not a distinct outer
parameter and cannot be a second same-target profile comparison.

Both the receipt writer and reconciler now enumerate only the free link-scale
coordinate. Parsing both scripts succeeded, and a task explicitly requesting
`sigma` failed with `requested target is absent from the declared manifest`.
This removes duplicate accounting; it does not turn the native non-finite
random-effect-SD endpoint into a pass.
