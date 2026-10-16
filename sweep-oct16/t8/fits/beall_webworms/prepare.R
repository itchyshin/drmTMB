data(beall.webworms, package = "agridat")
d <- agridat::beall.webworms
d$spray <- factor(as.character(d$spray), levels = sort(unique(as.character(d$spray))))
d$lead <- factor(as.character(d$lead), levels = sort(unique(as.character(d$lead))))
