lane_b_scalar_q1_contract_path <- function(root=".") file.path(root,"docs/dev-log/interval-campaign-bindings/2026-07-29-scalar-animal-relmat-q1-highinfo-contracts.tsv")
lane_b_scalar_q1_validate <- function(x) {
  target <- c("mc-0297::sd:mu:animal(1 | id)","mc-0300::sd:sigma:animal(1 | id)","mc-0312::sd:sigma:relmat(1 | id)")
  parameter <- sub("^[^:]+::","",target); required <- c("cell_id","target_id","dgp_id","formula","true_parameter_scale","profile_parameter","execution_information_rung","n_id","n_each","seed","target_truth","target_cardinality","binding_source","review_state")
  if (length(setdiff(required,names(x))) || nrow(x)!=3L || anyDuplicated(x$target_id) || !identical(x$target_id,target) || !identical(x$profile_parameter,parameter) || any(x$execution_information_rung!="high_n32_each20") || any(as.integer(x$n_id)!=32L) || any(as.integer(x$n_each)!=20L) || any(as.integer(x$seed)!=2026072903L) || !isTRUE(all.equal(as.numeric(x$target_truth),c(.65,.30,.30),tolerance=1e-12)) || any(as.integer(x$target_cardinality)!=1L) || any(x$review_state!="canonical_targetwise_execution_authorized")) stop("Scalar animal/relmat high-information contract is not exact.",call.=FALSE)
  transform(x,execution_authorized=TRUE,promotion_eligible=FALSE)
}
lane_b_scalar_q1_read_validate <- function(root=".") lane_b_scalar_q1_validate(utils::read.delim(lane_b_scalar_q1_contract_path(root),check.names=FALSE,stringsAsFactors=FALSE))
