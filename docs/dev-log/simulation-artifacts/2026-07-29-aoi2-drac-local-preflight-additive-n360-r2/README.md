# AOI-2 local preflight — additive, n = 360, repeat 2

This repeat ran successfully from pinned campaign SHA
`331aa041ece5bd4b45eafd1c75914768f704d519`: one retained interior association
attempt, both margin `pdHess = TRUE`, and fixed newdata link predictions with
known truth.  The raw row, session information, and SHA are retained here.

It verified the repaired analyzer's source generation only.  Rorqual module
preflight then found that its bundle lacks `devtools`; the runner was corrected
to use the installed package on the cluster.  A third local preflight will run
from that final portable commit before any array submission.
