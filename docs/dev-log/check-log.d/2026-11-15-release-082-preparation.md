# drmTMB 0.8.2 release preparation

The candidate starts at merged main `5d53eae0ba3ede53b3f43a78f690694e7f1133f0`. DESCRIPTION now declares 0.8.2, and NEWS separates the post-0.8.1 changes from the existing history. It includes the two prior fragments and names the two-intercept, mixed-prior and inference limits. An independent reviewer checked the proposed split and scope before these files were applied.

DESCRIPTION parsing and `git diff --check` passed. The prior integration PR passed its ten reported checks before merging. Release-candidate checks, artifact and platform review, release-wide claims review, and the compatible Julia release remain open. No release is claimed.
