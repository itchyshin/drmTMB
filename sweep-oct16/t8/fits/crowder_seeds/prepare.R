data(crowder.seeds, package = "agridat")
d <- agridat::crowder.seeds
d$gen <- factor(as.character(d$gen), levels = sort(unique(as.character(d$gen))))
d$extract <- factor(as.character(d$extract), levels = sort(unique(as.character(d$extract))))
d$fail <- d$n - d$germ
