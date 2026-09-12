# Fixed-tree intercept-profile pre-run receipt

Rorqual job `20897431` used one CPU and 4 GiB for 13m25s (peak RSS 321,736 KiB).
It held one deterministic phylogeny fixed per P1--P3 cell and regenerated five
independent responses per tree. Every fit had a positive-definite Hessian and
every fast/default intercept profile endpoint was available.

Fast and default profile endpoints differed by 0.00044--0.00065 on average,
while default profiles took 28--51 seconds versus 11--19 seconds for fast.
This rules out the fast control as a plausible explanation of the G13
intercept-calibration failure. The observed 3/5, 4/5, and 5/5 coverage values
are mechanism signals only, not coverage estimates; they show no evidence that
holding the tree fixed removes the P1/P2 problem.

Rorqual and Totoro file SHA-256 values agree. Totoro retains the complete pilot
under `/home/snakagaw/drmtmb-campaigns/phylo-ou-g12-384048d7-20260910/g13-fixed-tree-pilot-4875c7e1`.
