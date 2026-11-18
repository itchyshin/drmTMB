# PR 1651 compatibility receipt

The candidate run used a package-source subset of synthetic candidate tree `20278e542bd9eea013da6f258aaf341454b666f0`, recorded on Totoro as subset commit `7092e585480fe8bd0365283f08abf6fb3b9839f2`. Its 366 exported paths and modes were checked against that tree. This identifier is not a full-tree commit. The runner recorded the namespace path but did not record the hash of the loaded DLL.

The separate `baseline/` run used the same subset with `R/drmTMB.R` replaced by the current-main blob, recorded as subset commit `b1f9d992592cc951aee4c0e2da34b8f96c8cd92e`. Both runs passed all four attempts in each of the three cells, and their summary files match byte for byte. This is a same-host source comparison, not a complete main-tree comparison or coverage study.

The candidate's mean relative errors differ from the prior Mac receipt by at most 3.23e-11. That difference is reported rather than described as exact cross-platform agreement; the available receipts do not identify the cause. The earlier Mac and historical receipts remain unchanged.
