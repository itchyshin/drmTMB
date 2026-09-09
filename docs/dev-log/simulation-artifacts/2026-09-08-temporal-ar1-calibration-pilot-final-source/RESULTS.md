# Final-source pilot results and campaign decision

At source `8fed38ea02f14c5b6411774af10809d3d66bc3ee`, all 25 planned datasets
produced a finite selected fit and all 50 signed-start attempts were retained.
The summed fit time was `65.068` seconds; the labelled resource run took
`68.22` seconds wall time and reported a maximum resident set size of
`592,150,528` bytes (about 565 MiB). The longest dataset took `6.661` seconds.
A 5,000-dataset campaign therefore remains roughly 200 pilot sets, or about
3.8 serial CPU-hours before queue and filesystem overhead. Any future array
plan should request one CPU, at least 1 GiB, and a conservative 10-minute
limit, after checking DRAC/Fir capacity.

The pilot does **not** authorize a campaign. Mean-coefficient interval
availability was 4/5 for primary C1 and 5/5 for C2--C5. The unavailable C1
interval had a non-positive-definite Hessian and a `NaNs produced` warning.
Because C1 is a primary cell and the planned availability criterion is at least
0.99, this boundary result must be investigated before G17 can be requested.
No seed, threshold, or failed result was changed or removed.
