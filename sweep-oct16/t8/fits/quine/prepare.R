data(quine, package = "MASS")
d <- MASS::quine
for (nm in c("Eth","Sex","Age","Lrn")) d[[nm]] <- factor(as.character(d[[nm]]), levels = sort(unique(as.character(d[[nm]]))))
