# PR #1612 local repair checks

Merged current `drmTMB` main (`2fb93b768977330fc9939d86375c37329a539277`)
into the isolated CMR repair lane without conflicts. The C17/C14 current-source
compatibility runner passed 12 of 12 fits on merge-source commit
`cdf87f2851f327d55f2d230d20820fc2ed267174`, four per route. The three
mean relative errors for the random-effect SD were 0.0990, 0.1661, and 0.0613.
This is a narrow compatibility receipt, not CMR recovery or interval calibration.

Updated the three matching ledger rows and preserved their model-15 source
fingerprint. The reader-vignette contract test first found the CJS page missing
from the 38-page design map. Added it as a separate specialist route and updated
the count to 39. The final capability-ledger check passed 31 generated outputs,
the Python ledger suite passed 81 checks, and the R reader-vignette contract test
passed 35 expectations. The full R package suite and current-head GitHub checks
remain unrun.
