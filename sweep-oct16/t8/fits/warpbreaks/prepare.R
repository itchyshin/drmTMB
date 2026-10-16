data(warpbreaks, package = "datasets")
d <- warpbreaks
d$wool <- factor(as.character(d$wool), levels = sort(unique(as.character(d$wool))))
d$tension <- factor(as.character(d$tension), levels = sort(unique(as.character(d$tension))))
