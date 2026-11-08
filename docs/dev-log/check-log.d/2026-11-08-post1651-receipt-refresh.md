# Post-#1651 receipt refresh

The bridge fixture on R source `51f94e61a` and Julia source `0460f25ff` passed eight checks and twelve negative controls. The local CI-equivalent staleness check passed for the R source and runner; without `DRM_JL_PATH`, it did not verify the 115 Julia entries. The remote current-source checker verified the Julia paths. See `docs/dev-log/post1651-receipt-refresh/`.
