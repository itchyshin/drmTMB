# Calibration harness root review

Production status: blocked before launch. The six-seed feasibility runners use
the correct DGP. This review concerns the newly generated production harness.

1. `worker.R` indexes observation-level `w` using group IDs. That samples only
   the first ten predictor levels for the SDs. Separate `w_group` from the
   observation map, and test the realised latent SD vector against the formula
   over every group and every signed truth condition before fitting.
2. The stored source/runtime hashes are not verified at launch. Include the
   manifest hash, verify source/library identity before any worker, and reject
   changed scripts, manifests or installed DLL/R databases.
3. Require zero supervisor exit and completed worker state for valid intervals.
   A partial result from an interrupted child cannot count as successful.
4. Enforce the independent Laplace oracle tolerance in worker validity and
   campaign qualification. Merely storing the error does not close that gate.
5. Add `try/finally` and SIGINT/SIGTERM cleanup around the supervisor. A failed
   child launch or parent termination must kill and wait for owned process
   groups and leave every state explicit. Launch-error cleanup needs a test.
6. Summary must reject duplicate/mismatched identities, missing receipt cases,
   wrong seeds/truth, and unverified manifests. Report attempted-denominator and
   planned-denominator coverage separately; a stopped study is incomplete.
7. Use a 3,600-second cap for the 45-to-60-minute estimated campaign. The current
   7,200-second default would allow an estimate overrun to continue.

Root and the independent numerical-review agent found the DGP error separately.
All repairs require meaningful negative controls before the production pilot.
