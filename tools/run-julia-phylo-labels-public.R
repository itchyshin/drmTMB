#!/usr/bin/env Rscript
# Lossless label transport with a shuffled-row Gaussian phylogenetic LSS model.
args <- commandArgs(TRUE)
if(!length(args)%in%c(2L,3L)) stop("usage: run-julia-phylo-labels-public.R JULIA_ROOT NEW_JSON [tree|input]")
direct_order <- if(length(args)==3L) args[3] else "tree"
if(!direct_order%in%c("tree","input")) stop("direct order must be tree or input")
jroot <- normalizePath(args[1],mustWork=TRUE);output <- args[2]
drmjl_ref <- tryCatch(system2("git",c("-C",jroot,"rev-parse","HEAD"),stdout=TRUE,stderr=TRUE),error=function(e) NA_character_) # provenance: the DRM.jl ref this receipt ran against
if(file.exists(output)) stop("refusing to overwrite evidence")
Sys.setenv(DRM_JL_PATH=jroot,JULIA_NUM_THREADS="1",OPENBLAS_NUM_THREADS="1")
sha <- function(p) digest::digest(file=p,algo="sha256")
files <- c(sort(list.files("R",full.names=TRUE,pattern="[.]R$")),
           sort(list.files(file.path(jroot,"src"),recursive=TRUE,full.names=TRUE,pattern="[.]jl$")))
manifest <- function() as.list(setNames(vapply(files,sha,""),files))
out <- list(source_before=manifest(),runner_sha256=sha("tools/run-julia-phylo-labels-public.R"),
  scope=paste("One shuffled-row labeled-polytomy Gaussian LSS workflow; direct order:",direct_order))
t0 <- proc.time()[["elapsed"]]
out$result <- tryCatch({
  pkgload::load_all(quiet=TRUE,recompile=FALSE)
  tree <- ape::read.tree(text="((a:1,b:1,c:1):1,(d:1,e:1,f:1):1,(g:1,h:1,i:1):1,(j:1,k:1,l:1):1);")
  labels <- c("A B","AB","A_B","O'Brien","comma,tip","colon:tip","semi;tip",
              "(tip)[x]","日本 tree","  edge  ","tab\ttip","line\nbreak")
  tree$tip.label <- labels
  K <- ape::vcv(tree,corr=TRUE)
  set.seed(56330);g <- rep(1:12,each=6L);n <- length(g)
  zg <- rnorm(12);x <- rnorm(n);u <- exp(-.4+.2*zg)*as.numeric(t(chol(K))%*%rnorm(12))
  d <- data.frame(y=.4+.3*x+u[g]+exp(-1+.1*x)*rnorm(n),x=x,z=zg[g],species=labels[g])
  d <- d[sample(n),,drop=FALSE];rownames(d)<-NULL
  form <- bf(y~x+phylo(1|species,tree=tree),sigma~x,sd(species,level="phylogenetic")~z)
  native <- drmTMB(form,gaussian(),data=d)
  bridge <- drmTMB(form,gaussian(),data=d,engine="julia")
  payload <- drm_julia_phylo_newick(tree)
  ord <- if(direct_order=="tree") order(match(d$species,payload$tip_order)) else seq_len(n)
  dd <- d[ord,,drop=FALSE]
  JuliaCall::julia_assign("label_tree",payload$newick)
  for(nm in names(dd)) JuliaCall::julia_assign(paste0("label_",nm),dd[[nm]])
  direct <- JuliaCall::julia_eval('begin
    using DRM, LinearAlgebra
    pt = augmented_phy(label_tree)
    pf = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x), @formula(sd(species, phylogenetic) ~ z)), Gaussian();
        data=(y=label_y,x=label_x,z=label_z,species=label_species),tree=pt)
    Dict("mu"=>coef(pf,:mu),"sigma"=>coef(pf,:sigma),"sd_phylo"=>coef(pf,:sd_phylo),
      "loglik"=>loglik(pf),"fitted"=>fitted(pf),"converged"=>is_converged(pf),
      "labels"=>pt.leaf_names,"covariance"=>DRM.sigma_phy_dense(pt),
      "julia"=>string(VERSION),"threads"=>Threads.nthreads(),"blas"=>BLAS.get_num_threads(),"source"=>pathof(DRM))
  end')
  pull <- function(f) list(mu=unname(coef(f,"mu")),sigma=unname(coef(f,"sigma")),
     sd_phylo=unname(coef(f,if(inherits(f,"drmTMB_julia"))"sd_phylo" else "sd_phylo(species)")),
     loglik=as.numeric(logLik(f)),converged=is_converged(f))
  fits <- list(native=pull(native),bridge=pull(bridge),direct=direct)
  oracle <- function(f) {
    a <- exp(f$sd_phylo[1]+f$sd_phylo[2]*zg)
    V <- diag(exp(2*(f$sigma[1]+f$sigma[2]*d$x)))+((a%o%a)*K)[match(d$species,labels),match(d$species,labels)]
    C <- chol(V);r <- d$y-f$mu[1]-f$mu[2]*d$x
    -.5*(n*log(2*pi)+2*sum(log(diag(C)))+sum(backsolve(C,r,transpose=TRUE)^2))
  }
  errors <- lapply(fits,function(f) abs(f$loglik-oracle(f)))
  differences <- vapply(c("mu","sigma","sd_phylo","loglik"),function(k) max(abs(fits$native[[k]]-direct[[k]])),0.0)
  bridge_diff <- vapply(c("mu","sigma","sd_phylo","loglik"),function(k) max(abs(fits$bridge[[k]]-direct[[k]])),0.0)
  checks <- c(names=identical(as.character(direct$labels),payload$tip_order),
    covariance=max(abs(direct$covariance-ape::vcv(tree)[payload$tip_order,payload$tip_order]))<1e-12,
    likelihood=all(unlist(errors)<1e-7),native_parity=all(differences<=4e-6),
    bridge_parity=all(bridge_diff<=4e-6),
    rows=max(abs(fitted(bridge)-direct$fitted[order(ord)]))<1e-8,
    converged=all(vapply(fits,function(f)isTRUE(f$converged),TRUE)),
    source=normalizePath(direct$source)==file.path(jroot,"src","DRM.jl"))
  list(status=if(all(checks)) "PASS" else "FAIL",checks=as.list(checks),labels=labels,
       payload=payload,data=d,permutation=ord,direct_order=direct_order,outputs=fits,
       bridge_fitted=unname(fitted(bridge)),native_correlation=unname(K),
       group_covariate=zg,tree_edge=unname(tree$edge),tree_edge_length=tree$edge.length,
       runtime=list(R=R.version.string,drmTMB=as.character(packageVersion("drmTMB")),drmjl_ref=drmjl_ref,
         native_dll=lapply(getLoadedDLLs()[intersect("drmTMB",names(getLoadedDLLs()))],
           function(x)list(path=x[["path"]],sha256=sha(x[["path"]])))),oracle_errors=errors,
       native_differences=as.list(differences),bridge_differences=as.list(bridge_diff))
},error=function(e)list(status="ERROR",message=conditionMessage(e)))
out$source_after<-manifest();out$source_unchanged<-identical(out$source_before,out$source_after)
out$elapsed<-proc.time()[["elapsed"]]-t0
out$status<-if(out$source_unchanged&&identical(out$result$status,"PASS"))"PASS" else "FAIL"
jsonlite::write_json(out,output,pretty=TRUE,auto_unbox=TRUE,digits=17,na="string",null="null")
cat("PHYLO_LABEL_PUBLIC_",out$status," elapsed=",out$elapsed,"\n",sep="")
if(out$status!="PASS")quit(status=1L)
