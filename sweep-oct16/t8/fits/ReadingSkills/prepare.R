data(ReadingSkills, package = "betareg")
d <- ReadingSkills
d$dyslexia <- factor(as.character(d$dyslexia), levels = sort(unique(as.character(d$dyslexia))))
