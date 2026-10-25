# Results and diagnostic note

The committed recovery runner completed all twelve selected fits and retained
two signed persistence starts for each fit. Its predeclared criteria passed:
mean absolute fixed-effect error was `0.0915`, median absolute SD error was
`0.0786`, and median absolute persistence error was `0.0779`.

The batch emitted one `sqrt(diag(cov))` warning. The retained estimates show
that AR1-only fixtures P02 and P04 placed residual `sigma` near zero
(`0.000113` and `0.0000544`). This is a boundary/weak-information diagnostic,
not a recovery failure under the predeclared median criterion. No coefficient
interval is interpreted from this fixture. The separate five-cell ADEMP
calibration must report interval availability and count unavailable intervals
as uncovered before any general Wald-interval claim is made.

`provenance.csv` fixes the source commit and runner checksum used for these
outputs. The raw attempt table retains both starts, objectives, convergence
codes, selected status, and any fit errors for every fixture.
