data(ToothGrowth, package = "datasets")
d <- ToothGrowth
d$supp <- factor(as.character(d$supp), levels = sort(unique(as.character(d$supp))))
