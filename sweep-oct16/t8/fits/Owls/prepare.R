chr_factor <- function(x) {
  x <- as.character(x)
  if (length(x) && all(grepl("^[0-9]+$", x))) x <- paste0("g", x)
  factor(x, levels = sort(unique(x)))
}
data(Owls, package = "glmmTMB")
d <- glmmTMB::Owls
d$FoodTreatment <- chr_factor(d$FoodTreatment)
d$SexParent <- chr_factor(d$SexParent)
d$Nest <- chr_factor(d$Nest)
d$NCalls <- d$SiblingNegotiation
