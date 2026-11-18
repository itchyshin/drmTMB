# Combined phylogenetic feature receipt

The runner used R source `7bf63a960169bb53bac4f73ac642f1cd83b1bb29` and synthetic Julia integration `2d355dfe97811fb82022b91d3ba4c0ad8b8bc476` on Totoro with one thread. The fixture is a no-prior Gaussian phylogenetic model with 12 labels and 72 observations. Eight checks passed and 12 deliberate mutations were rejected. The release agent matched 68 R source hashes, 127 Julia source hashes and the runner to the isolated integration inputs. Independent review remains open.

An initial local staleness check against release-only Julia `cbd870be` failed on three feature source files, as expected for the wrong checkout. The recorded `ci-staleness.log` passed using the synthetic combined source. The native binary build was not independently reproduced. This fixture does not validate priors or uncertainty, and a final merged-source receipt remains required.
