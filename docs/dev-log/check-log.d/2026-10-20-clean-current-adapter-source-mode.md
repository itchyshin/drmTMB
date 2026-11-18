# 2026-10-20: Clean-current adapter source mode

Added a shared resolver for the legacy and clean-current Bernoulli adapter
qualification streams. The clean-current path now checks the frozen `look2.csv`
SHA, full source schema, 9,000 ordered rows, unique seeds, prior-stream
disjointness, and three frozen cross-truth probe identities. Preparation writes
mode-labelled receipts and registers the exact source manifest. The runner
validates the same source, uses the clean-current worker design mode, and emits
a replayable non-calibration qualification receipt. Legacy remains the default.

The source resolver and clean-current receipt tests first failed because the
shared mode-aware functions did not exist. The source-bound no-fit runner test
now passes for all three probe positions and successfully replays the generated
receipt. The full stage-two Python suite passes 50 tests; Python compilation
and `git diff --check` pass.

No model fit or campaign ran. This establishes source and runner plumbing only.
The exact v4 installed library still needs a three-probe Totoro qualification;
calibration, the fresh second-look campaign, and programme gates G0-G8 remain
open. See `docs/dev-log/after-task/2026-10-20-clean-current-adapter-source-mode.md`.
