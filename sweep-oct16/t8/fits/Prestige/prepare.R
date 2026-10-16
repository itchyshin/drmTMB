data(Prestige, package = "carData")
d <- subset(carData::Prestige, !is.na(type))
d$type <- factor(as.character(d$type), levels = sort(unique(as.character(d$type))))
rownames(d) <- NULL
