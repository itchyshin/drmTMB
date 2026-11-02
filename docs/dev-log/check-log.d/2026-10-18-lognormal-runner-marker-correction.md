The compiled native-test runner now reports the selected test-file names and
emits `NATIVE_BINOMIAL_SD_PASS` only when a binomial test file ran. The focused
marker regression passed four cases: lognormal, binomial, beta-binomial, and a
mixed run. Runner parsing and `git diff --check` pass. The historical lognormal
Totoro log is unchanged; because its tested tarball is not retained for
independent member verification, the lognormal L4 evidence gate remains open.
