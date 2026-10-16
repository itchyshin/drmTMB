chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(epil, package = "MASS")
d <- MASS::epil
d$trt <- chr_factor(d$trt)
d$subject <- chr_factor(d$subject)
d$V4 <- as.numeric(d$V4)
