# Unified prior table

The table adapter converts supported fixed-effect and Gaussian random-intercept SD priors to existing prior specifications. Gamma table parameters are mean and shape. Unsupported targets and overlapping selectors are rejected. Updates replay resolved targets rather than expanding selectors again.

At source 2608f81, the independent dense oracle passed 483 assertions across 150 points, including seven mutation controls. Focused table and refusal tests passed. The live Julia bridge passed 38 assertions, including mismatched target checks. A previous bridge test failed two whole-frame comparisons; the subsequent test compared the named targets and their fields.

The C17 compatibility run at 2608f81 reproduced all 12 recorded attempts and three summaries. Ledger equivalence and 92 unit tests passed. These checks do not establish full package regression, current-main integration, or independent code review; those gates remain open. This slice is penalized maximum likelihood, not posterior sampling. Random slopes and correlation priors remain outside its scope.
