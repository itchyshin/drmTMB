args <- commandArgs(trailingOnly=TRUE)
script_arg <- commandArgs()[grepl("^--file=",commandArgs())][[1L]]
here <- dirname(normalizePath(sub("^--file=","",script_arg),mustWork=TRUE))
verifier <- file.path(here,"verify-first-look.R")
tmp <- tempfile("first-look-registry-test-"); dir.create(tmp)
prepared <- file.path(tmp,"production-prepared"); dir.create(prepared)
first <- file.path(tmp,"first-look"); dir.create(first)
manifest <- data.frame(index=1:3000,a=rep(c(-0.5,0,0.5),each=1000),
                       replicate=rep(1:1000,3),seed=10001:13000,
                       design_mode="production",master_seed=2026101703)
prepared_manifest <- file.path(prepared,"manifest.csv")
write.csv(manifest,prepared_manifest,row.names=FALSE)
copied_manifest <- file.path(first,"manifest.csv")
invisible(file.copy(prepared_manifest,copied_manifest))
registry <- file.path(first,"source-hashes.csv")
write.csv(data.frame(path=prepared_manifest,
                     sha256=digest::digest(prepared_manifest,algo="sha256",file=TRUE)),
          registry,row.names=FALSE,quote=TRUE)
seal <- file.path(tmp,"seal.json")
jsonlite::write_json(list(registry_sha256=digest::digest(registry,algo="sha256",file=TRUE)),seal,auto_unbox=TRUE)
out <- file.path(tmp,"unused-output.csv")
run_check <- function() suppressWarnings(system2("Rscript",vapply(c(verifier,first,seal,out,"--registry-only"),shQuote,character(1L)),
                                                 stdout=TRUE,stderr=TRUE))
positive <- run_check()
if(!is.null(attr(positive,"status"))) stop("Valid copied manifest layout failed: ",paste(positive,collapse="\n"))
if(!any(grepl("FIRST_LOOK_REGISTRY_PASS",positive,fixed=TRUE))) stop("Registry success receipt missing")

# The remote/prepared artifact stays unchanged; tampering only with the local
# first-look copy must fail even though the registry path is not under FIRST_LOOK.
manifest$seed[[1L]] <- manifest$seed[[1L]] + 1L
write.csv(manifest,copied_manifest,row.names=FALSE)
negative <- run_check()
if(is.null(attr(negative,"status")) || !any(grepl("Copied first-look manifest differs",negative,fixed=TRUE)))
  stop("Tampered copied first-look manifest was not rejected")
unlink(tmp,recursive=TRUE)
cat("PASS: external prepared-manifest registry layout and copied-manifest tamper guard\n")
