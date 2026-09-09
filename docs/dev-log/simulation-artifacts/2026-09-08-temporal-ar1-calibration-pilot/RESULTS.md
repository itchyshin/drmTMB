# Pilot results and campaign decision

All 25 planned datasets produced a finite selected fit and all 50 signed-start
attempts were retained. The five-cell pilot took `45.065` seconds of summed fit
time. A labelled resource-only replay of the frozen source and seed set took
`47.18` seconds wall time and peaked at `638,795,776` bytes (about 609 MiB).
The replay wrote only temporary output; the retained result tables remain the
first pilot run.

At this observed serial rate, the 5,000-dataset campaign is about 200 pilot
sets, or approximately 2.6 serial CPU-hours before queue and filesystem
overhead. The longest observed dataset took 3.794 seconds. Any future array
plan should request one CPU and at least 1 GiB per task, with a conservative
10-minute time limit, then recheck DRAC/Fir capacity immediately before
submission.

The pilot does **not** authorize the campaign. Mean-coefficient interval
availability was 4/5 in primary C1, 5/5 in C2--C4, and 4/5 in stress C5. The
C1 unavailable interval had `pd_hessian = FALSE` and a `NaNs produced`
warning; C5 showed the same diagnostic in its stress setting. C1 is a primary
cell whose future acceptance criterion is availability at least 0.99, so this
pilot exposes a numerical-inference issue that must be diagnosed before G17
can be requested. No seed was changed, result was removed, or threshold was
relaxed.

`resource-replay.txt` is the macOS `/usr/bin/time -l` report for the exact
source and seed configuration. The first wrapper left an empty resource file
because it used a GNU-only `-o` option; the replay was required solely to
measure memory and did not replace the retained pilot outputs.
