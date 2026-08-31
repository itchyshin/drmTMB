#!/usr/bin/env Rscript
# Bounded ordinary-batch success plus deterministic public-R failure transport.
# Injected failures are NOT reproduced optimizer failures or coverage evidence.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
jl_root <- normalizePath(args[[1L]], mustWork = TRUE)
prefix <- args[[2L]]
stopifnot(!any(file.exists(paste0(prefix, c('.json', '.rds')))))
Sys.setenv(DRM_JL_PATH = jl_root, JULIA_NUM_THREADS = '1', OPENBLAS_NUM_THREADS = '1')
Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'))
options(drmTMB.DRM.jl.path = jl_root)
sha <- function(p) digest::digest(file = p, algo = 'sha256')
paths <- sort(unique(normalizePath(c(
  list.files('R', recursive = TRUE, full.names = TRUE, pattern = '[.]R$'),
  list.files(file.path(jl_root, 'src'), recursive = TRUE, full.names = TRUE, pattern = '[.]jl$'),
  'tools/run-julia-profile-status-public.R', 'tools/check-julia-profile-status-receipt.R',
  'tests/testthat/test-julia-inference.R',
  file.path(jl_root,c('Project.toml','Manifest.toml'))
))))
manifest <- function() as.list(setNames(vapply(paths, sha, ''), paths))
before <- manifest()
started <- proc.time()[['elapsed']]
suppressMessages(pkgload::load_all('.', quiet = TRUE))
Sys.unsetenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN'))
batch_environment <- as.list(Sys.getenv(c('DRMTMB_JULIA_TESTS','NOT_CRAN','_R_CHECK_PACKAGE_NAME_')))
stopifnot(!nzchar(batch_environment$DRMTMB_JULIA_TESTS),!nzchar(batch_environment$NOT_CRAN))
# Extract the actual generated function, preserving every Julia character.
candidates <- list()
walk <- function(x) {
  if (!is.call(x) && !is.expression(x)) return(invisible(NULL))
  if (is.call(x) && identical(x[[1L]], quote(paste)) &&
      any(vapply(as.list(x)[-1L], function(v) is.character(v) &&
        any(startsWith(v, 'function drmTMB_drm_bridge_fixef_inference(')), TRUE))) {
    candidates[[length(candidates) + 1L]] <<- eval(x, baseenv())
  }
  for (v in as.list(x)) if (is.call(v) || is.expression(v)) walk(v)
}
walk(body(drmTMB:::drm_julia_setup))
stopifnot(length(candidates) == 1L)
wrapper <- candidates[[1L]]

# Actual ordinary Rscript success, with independent Gaussian ML LR endpoints.
set.seed(563301L)
x <- rnorm(80); y <- 0.4 + 0.7*x + rnorm(80, sd = 0.6)
dat <- data.frame(y, x)
fit <- drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1), data = dat, engine = 'julia')
success <- stats::confint(fit, parm = 'fixef:mu:x', method = 'profile', level = .90)
X <- cbind(1, x); beta <- solve(crossprod(X), crossprod(X, y)); rss <- sum((y-X%*%beta)^2)
halfwidth <- sqrt(expm1(qchisq(.9, 1)/length(y)) * rss * solve(crossprod(X))[2,2])
oracle <- c(beta[2]-halfwidth, beta[2]+halfwidth)
runtime <- JuliaCall::julia_eval('Dict("source"=>pathof(DRM), "version"=>string(VERSION), "threads"=>Threads.nthreads(), "blas"=>DRM.BLAS.get_num_threads())')
stopifnot(normalizePath(runtime$source) == file.path(jl_root,'src','DRM.jl'), runtime$threads == 1, runtime$blas == 1)
stopifnot(identical(success$conf.status, 'profile'),
          max(abs(c(success$lower, success$upper)-oracle)) < 1e-5)

# Source test fixture definitions only: do not execute the existing test file.
fixture_env <- new.env(parent = globalenv())
for (expr in parse('tests/testthat/test-julia-inference.R')) {
  if (is.call(expr) && identical(expr[[1]], quote(`<-`)) &&
      identical(expr[[2]], quote(drm_julia_inference_synthetic_fit_with_payload)))
    eval(expr, fixture_env)
}
synthetic <- fixture_env$drm_julia_inference_synthetic_fit_with_payload()
facade <- r"---(
module ProfileTransport
module DRM
const Real = Main.DRM
const state = Ref{Any}(nothing)
const selector = Ref{Any}(nothing)
_bridge_data(data) = data
_bridge_formula(formula, family, data) = (nothing, data)
_bridge_family(family) = nothing
_bridge_options(options) = Dict{Symbol,Any}()
_bridge_tree(tree) = tree
_bridge_fit(args...; kwargs...) = nothing
function profile_result(fit; level, threads, parm)
    selector[] = parm
    return state[]
end
_bridge_profile_outcome(result,row) = Real._bridge_profile_outcome(result,row)
_bridge_inference_flatten(args...;kwargs...) = Real._bridge_inference_flatten(args...;kwargs...)
end
end
)---"
JuliaCall::julia_command(facade)
# Same generated function, tested both with and without the new DRM helper.
JuliaCall::julia_command(sub('module ProfileTransport', 'module ProfileTransportOld',
  sub('_bridge_profile_outcome(result,row) = Real._bridge_profile_outcome(result,row)', '',
      facade, fixed = TRUE), fixed = TRUE))
JuliaCall::julia_assign('profile_transport_wrapper_source', wrapper)
JuliaCall::julia_command('Core.eval(ProfileTransport, Meta.parse(profile_transport_wrapper_source)); Core.eval(ProfileTransportOld, Meta.parse(profile_transport_wrapper_source))')
JuliaCall::julia_command(r"---(
function profile_transport_case(old, scenario, dpar, coefname)
    mod = old ? ProfileTransportOld : ProfileTransport
    lowerfailed = scenario in ("lower", "both", "empty")
    upperfailed = scenario in ("upper", "both")
    searched = scenario == "searched"
    row = (param=Symbol(dpar),coef=String(coefname),estimate=0.4,
           lower=(lowerfailed || searched) ? -Inf : 0.2,
           upper=upperfailed ? Inf : 0.7)
    st = (param=row.param,coef=row.coef,lower_endpoint_failed=lowerfailed,
          upper_endpoint_failed=upperfailed,lower_unbounded=searched,upper_unbounded=false)
    stats = scenario == "empty" ? NamedTuple[] : [st]
    if scenario == "other"
        push!(stats, merge(st,(coef="another",lower_endpoint_failed=true)))
    end
    failed = (lowerfailed || upperfailed || scenario == "other") ? 1 : 0
    mod.DRM.state[] = (ci=[row],stats=stats,failed=failed,attempted=(scenario == "other" ? 2 : 1),
        used=(scenario == "other" ? 2 : 1),elapsed=0.0,threaded=false,worker_threads=1,julia_threads=1,blas_threads=1)
    answer = mod.drmTMB_drm_bridge_fixef_inference(nothing,nothing,nothing,nothing,
        nothing,"profile",0.9,1,nothing,false,dpar,coefname)
    @assert mod.DRM.selector[] == (Symbol(dpar) => String(coefname))
    return answer
end
)---")
rows <- list()
for (old in c(FALSE, TRUE)) for (scenario in c('lower','upper','both','other','searched','empty','good')) {
  result <- testthat::with_mocked_bindings({
    stats::confint(synthetic, parm = 'fixef:mu:x', method = 'profile', level = .9)
  }, drm_julia_call_fixef_inference = function(object,target,method,level,R,seed,threads) {
    stopifnot(identical(method,'profile'),identical(target$term,'x'))
    JuliaCall::julia_call('profile_transport_case',old,scenario,target$dpar[[1]],target$term[[1]])
  }, .package = 'drmTMB')
  failed <- scenario %in% c('lower','upper','both','empty') || (old && scenario == 'other')
  stopifnot(identical(result$conf.status,if(failed) 'profile_failed' else 'profile'))
  stopifnot(identical(result$parm,'fixef:mu:x'),
            identical(result$lower,if(scenario %in% c('lower','both','searched','empty')) -Inf else .2),
            identical(result$upper,if(scenario %in% c('upper','both')) Inf else .7))
  if (failed) stopifnot(grepl('failed',result$profile.message,fixed=TRUE))
  if (!old && scenario == 'searched') stopifnot(grepl('searched range',result$profile.message,fixed=TRUE))
  rows[[paste(old,scenario,sep=':')]] <- as.data.frame(result)
}
# Public SD dispatch must retain failure even after exp(-Inf) becomes zero.
sd_result <- testthat::with_mocked_bindings({
  stats::confint(synthetic, parm = 'sd:mu:phylo(1 | species)', method = 'profile', level = .9)
}, drm_julia_call_inference = function(...) {
  list(lower=-Inf,upper=log(2),status='profile_failed',message='profile endpoint solve failed: lower',
       threaded=FALSE,worker_threads=1L,julia_threads=1L,blas_threads=1L,elapsed=0)
}, .package='drmTMB')
stopifnot(sd_result$lower == 0, abs(sd_result$upper - 2*sqrt(2)) < 1e-12,
          identical(sd_result$parm,'sd:mu:phylo(1 | species)'),
          identical(sd_result$conf.status,'profile_failed'))
after <- manifest(); stopifnot(identical(before,after))
receipt <- list(status='PASS',scope='Ordinary batch actual success; injected failures test transport only, not numerical optimizer reproduction',
 elapsed=proc.time()[['elapsed']]-started,ordinary_batch=!nzchar(Sys.getenv('DRMTMB_JULIA_TESTS')) && !nzchar(Sys.getenv('NOT_CRAN')),
 wrapper_sha256=digest::digest(wrapper,algo='sha256',serialize=FALSE),
 runtime=runtime, batch_environment=batch_environment, R_version=R.version.string, drmtmb_version=as.character(packageVersion('drmTMB')),
 head_r=system2('git',c('rev-parse','HEAD'),stdout=TRUE),
 status_r=system2('git',c('status','--short'),stdout=TRUE),
 source_before=before,source_after=after,success=as.data.frame(success),oracle=oracle,
 data=dat, level=.9, tolerance=1e-5, fit_converged=drmTMB::is_converged(fit),
 coefficients=stats::coef(fit), loglik=as.numeric(stats::logLik(fit)),
 synthetic_limit='Preparation is stubbed; not model admission. Older facade tests helper absence, not all prior releases.',
 injected_fixed=rows,injected_sd=as.data.frame(sd_result))
saveRDS(receipt,paste0(prefix,'.rds'))
jsonlite::write_json(receipt,paste0(prefix,'.json'),pretty=TRUE,auto_unbox=TRUE,digits=NA,na='string')
cat('JULIA_PROFILE_STATUS_PUBLIC_PASS elapsed=',receipt$elapsed,' injected_fixed=14 injected_sd=1\n',sep='')
