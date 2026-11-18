# Prior run findings

The initial builder probe rejected two Gamma relmat SD formulas while confirming base q=2 support. An initial animal q2 fit converged but its conditional predictor differed from the TMB fitted predictor by max 1.341697.

The first broader Gamma run reported 107 passing checks and one stale rejection-message expectation in test-gamma-animal-slope-sd-regression.R. The current refusal requires an explicit coefficient selector. That assertion was updated; the final five-file run passes 108/108. This note summarizes the captured tool output; it is not a retained raw log of that first broader run.
