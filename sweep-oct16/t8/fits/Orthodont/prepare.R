chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(Orthodont, package = "nlme")
d <- as.data.frame(nlme::Orthodont)
d$Subject <- chr_factor(d$Subject)
d$Sex <- chr_factor(d$Sex)
