// R 4.5's Apple clang headers currently use a diagnostic pragma for
// -Wfixed-enum-extension that this local clang does not recognize. Including
// Boolean.h through the legacy branch before TMB avoids a package-check
// installation warning without shipping non-portable compiler flags.
#include <Rconfig.h>
#ifdef HAVE_ENUM_BASE_TYPE
#define DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE 1
#undef HAVE_ENUM_BASE_TYPE
#endif
#include <R_ext/Boolean.h>
#ifdef DRMTMB_RESTORE_HAVE_ENUM_BASE_TYPE
#define HAVE_ENUM_BASE_TYPE 1
#endif
#include <TMB.hpp>
#include "drm_count_kernels.h"

// Smooth clamp of a log-sigma linear predictor. EXACTLY identity inside the band
// [lo, hi] (so a well-posed fit, whose log-sigma lies in the band, is unchanged
// to the bit), and saturating C1-smoothly within a margin beyond each bound
// (overall range (lo - margin, hi + margin)). A runaway per-observation scale --
// e.g. a per-group scale random effect estimated from one observation per group
// -- is therefore bounded and cannot overflow the Gaussian density or break the
// inner Laplace solve, while ordinary fits see no change at all.
// See docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md.
template<class Type>
void drm_softclamp_log_sigma(vector<Type>& v, Type lo, Type hi, Type margin) {
  for (int i = 0; i < v.size(); ++i) {
    Type x = v(i);
    Type above = hi + margin * tanh((x - hi) / margin); // used only when x > hi
    Type below = lo - margin * tanh((lo - x) / margin); // used only when x < lo
    Type y = CppAD::CondExpGt(x, hi, above, x);
    y = CppAD::CondExpLt(x, lo, below, y);
    v(i) = y;
  }
}

// PC-prior penalty (negative log-prior) for an optional penalized/MAP fit: an
// exponential prior on each phylogenetic SD = exp(log_sd_phylo) with the
// log-Jacobian, plus an optional mean-zero normal on the live phylogenetic
// correlation parameter (eta_cor_phylo for q == 2, theta_phylo for q > 2).
// See docs/design/172-phylo-penalized-map.md.
template<class Type>
Type drm_phylo_penalty_value(const vector<Type>& log_sd_phylo,
                             int q_phylo,
                             Type eta_cor_phylo,
                             const vector<Type>& theta_phylo,
                             const vector<Type>& sd_penalty_rate,
                             const vector<Type>& cor_penalty_sd) {
  Type pen = Type(0.0);
  for (int k = 0; k < q_phylo; ++k) {
    if (k < sd_penalty_rate.size()) {
      Type lam = sd_penalty_rate(k);
      if (lam > Type(0.0)) {
        Type sd_k = exp(log_sd_phylo(k));
        pen += lam * sd_k - log_sd_phylo(k) - log(lam);
      }
    }
  }
  if (cor_penalty_sd.size() > 0) {
    Type s = cor_penalty_sd(0);
    if (s > Type(0.0)) {
      Type half_log_2pi = Type(0.5) * log(Type(2.0) * M_PI);
      if (q_phylo == 2) {
        Type z = eta_cor_phylo / s;
        pen += Type(0.5) * z * z + log(s) + half_log_2pi;
      } else if (q_phylo > 2) {
        for (int t = 0; t < theta_phylo.size(); ++t) {
          Type z = theta_phylo(t) / s;
          pen += Type(0.5) * z * z + log(s) + half_log_2pi;
        }
      }
    }
  }
  return pen;
}

template<class Type>
Type objective_function<Type>::operator()()
{
  DATA_VECTOR(y);
  DATA_IVECTOR(observed_y);
  DATA_IVECTOR(observed_y1);
  DATA_IVECTOR(observed_y2);
  DATA_INTEGER(has_mi);
  DATA_INTEGER(mi_family);
  DATA_INTEGER(mi_col);
  DATA_VECTOR(mi_x);
  DATA_VECTOR(mi_successes);
  DATA_VECTOR(mi_trials);
  DATA_IVECTOR(mi_observed);
  DATA_IVECTOR(mi_missing_index);
  DATA_INTEGER(has_mi_group);
  DATA_IVECTOR(mi_group_index);
  DATA_INTEGER(has_mi_struct);
  DATA_IVECTOR(mi_struct_index);
  DATA_VECTOR(mi_struct_value);
  DATA_SPARSE_MATRIX(Q_mi_struct);
  DATA_SCALAR(log_det_Q_mi_struct);
  DATA_MATRIX(X_mi);
  DATA_INTEGER(mi_n_state);
  DATA_MATRIX(X_mi_state_mu);
  DATA_VECTOR(mi_quad_nodes);
  DATA_VECTOR(mi_quad_weights);
  DATA_VECTOR(trials);
  DATA_VECTOR(weights);
  DATA_VECTOR(offset_mu);
  DATA_INTEGER(use_gaussian_aggregation);
  DATA_INTEGER(n_agg);
  DATA_VECTOR(agg_n);
  DATA_VECTOR(agg_sum_y);
  DATA_VECTOR(agg_sum_y2);
  DATA_MATRIX(X_mu_agg);
  DATA_MATRIX(X_sigma_agg);
  DATA_VECTOR(offset_mu_agg);
  DATA_VECTOR(offset_sigma_agg);
  DATA_VECTOR(V_known);
  DATA_MATRIX(V_known_matrix);
  DATA_INTEGER(V_known_type);
  DATA_VECTOR(y1);
  DATA_VECTOR(y2);
  DATA_INTEGER(model_type);
  DATA_MATRIX(X_mu);
  DATA_INTEGER(use_sparse_X_mu);
  DATA_SPARSE_MATRIX(X_mu_sparse);
  DATA_MATRIX(X_sigma);
  DATA_MATRIX(X_nu);
  DATA_MATRIX(X_zi);
  DATA_MATRIX(X_sd_mu);
  DATA_INTEGER(has_sd_mu_model);
  DATA_MATRIX(X_sd_phylo);
  DATA_INTEGER(has_sd_phylo_model);
  DATA_INTEGER(sd_phylo_beta_offset);
  DATA_MATRIX(X_mu1);
  DATA_MATRIX(X_mu2);
  DATA_MATRIX(X_sigma1);
  DATA_MATRIX(X_sigma2);
  DATA_MATRIX(X_rho12);
  DATA_INTEGER(n_mu_re_terms);
  DATA_INTEGER(n_mu_re_cors);
  DATA_IMATRIX(mu_re_index);
  DATA_MATRIX(mu_re_value);
  DATA_IVECTOR(mu_re_term);
  DATA_IVECTOR(mu_re_dpar);
  DATA_IVECTOR(mu_re_pos);
  DATA_IVECTOR(mu_re_cor_id);
  DATA_IVECTOR(mu_re_pair_index);
  DATA_IVECTOR(mu_re_sd_row);
  DATA_MATRIX(X_cor_mu);
  DATA_INTEGER(has_cor_mu_model);
  DATA_INTEGER(n_sigma_re_terms);
  DATA_INTEGER(n_sigma_re_cors);
  DATA_INTEGER(n_mu_sigma_re_cors);
  DATA_IMATRIX(sigma_re_index);
  DATA_MATRIX(sigma_re_value);
  DATA_IVECTOR(sigma_re_term);
  DATA_IVECTOR(sigma_re_dpar);
  DATA_IVECTOR(sigma_re_cor_id);
  DATA_IVECTOR(sigma_re_pair_index);
  DATA_IVECTOR(sigma_re_cross_cor);
  DATA_IVECTOR(sigma_re_cross_mu);
  DATA_INTEGER(has_phylo_mu);
  DATA_IVECTOR(phylo_mu_sd_row);
  DATA_IVECTOR(phylo_mu_node_index);
  DATA_MATRIX(phylo_mu_value);
  DATA_IVECTOR(phylo_mu_block_id);
  DATA_IVECTOR(phylo_mu_dpar);
  DATA_INTEGER(phylo_mu_n_blocks);
  DATA_SPARSE_MATRIX(Q_phylo);
  DATA_SCALAR(log_det_Q_phylo);
  DATA_INTEGER(penalize_phylo);
  DATA_VECTOR(phylo_sd_penalty_rate);
  DATA_VECTOR(phylo_cor_penalty_sd);
  DATA_INTEGER(n_re_cov_blocks);
  DATA_IVECTOR(re_cov_block_size);
  DATA_IVECTOR(re_cov_block_group_count);
  DATA_IVECTOR(re_cov_block_member_start);
  DATA_IVECTOR(re_cov_block_pair_start);
  DATA_IVECTOR(re_cov_member_component);
  DATA_IVECTOR(re_cov_member_dpar);
  DATA_IVECTOR(re_cov_member_response);
  DATA_IVECTOR(re_cov_member_source_term);
  DATA_IVECTOR(re_cov_member_coef_pos);
  DATA_IMATRIX(re_cov_member_latent_index);
  DATA_MATRIX(re_cov_member_design_value);
  DATA_IVECTOR(re_cov_pair_from_member);
  DATA_IVECTOR(re_cov_pair_to_member);
  DATA_IVECTOR(re_cov_pair_parameter);
  DATA_IVECTOR(re_cov_pair_parameter_index);
  DATA_VECTOR(re_cov_probe_theta);
  DATA_VECTOR(re_cov_probe_sd);
  DATA_VECTOR(re_cov_probe_x);
  DATA_VECTOR(re_cov_probe_z);
  DATA_MATRIX(re_cov_probe_covariance);

  PARAMETER_VECTOR(beta_mu);
  PARAMETER_VECTOR(beta_sigma);
  PARAMETER_VECTOR(beta_nu);
  PARAMETER_VECTOR(beta_zi);
  PARAMETER_VECTOR(beta_zoi);
  PARAMETER_VECTOR(beta_coi);
  PARAMETER_VECTOR(theta_ord);
  PARAMETER_VECTOR(beta_sd_mu);
  PARAMETER_VECTOR(beta_mu1);
  PARAMETER_VECTOR(beta_mu2);
  PARAMETER_VECTOR(beta_sigma1);
  PARAMETER_VECTOR(beta_sigma2);
  PARAMETER_VECTOR(beta_rho12);
  PARAMETER_VECTOR(beta_cor_mu);
  PARAMETER_VECTOR(beta_mi);
  PARAMETER_VECTOR(log_sigma_mi);
  PARAMETER_VECTOR(x_miss);
  PARAMETER_VECTOR(u_mi_group);
  PARAMETER_VECTOR(log_sd_mi_group);
  PARAMETER_VECTOR(u_mi_struct);
  PARAMETER_VECTOR(log_sd_mi_struct);
  PARAMETER_VECTOR(u_mu);
  PARAMETER_VECTOR(log_sd_mu);
  PARAMETER_VECTOR(eta_cor_mu);
  PARAMETER_VECTOR(eta_cor_mu_sigma);
  PARAMETER_VECTOR(eta_cor_sigma);
  PARAMETER_VECTOR(u_sigma);
  PARAMETER_VECTOR(log_sd_sigma);
  PARAMETER_VECTOR(u_phylo);
  PARAMETER_VECTOR(u_re_cov);
  PARAMETER_VECTOR(log_sd_re_cov);
  PARAMETER_VECTOR(theta_re_cov);
  PARAMETER_VECTOR(u_re_cov_probe);
  PARAMETER_VECTOR(log_sd_phylo);
  PARAMETER_VECTOR(theta_phylo);
  PARAMETER(eta_cor_phylo);

  Type nll = 0;
  Type phylo_penalty = Type(0.0);
  (void)mi_observed;
  (void)n_re_cov_blocks;
  (void)re_cov_block_size;
  (void)re_cov_block_group_count;
  (void)re_cov_block_member_start;
  (void)re_cov_block_pair_start;
  (void)re_cov_member_component;
  (void)re_cov_member_dpar;
  (void)re_cov_member_response;
  (void)re_cov_member_source_term;
  (void)re_cov_member_coef_pos;
  (void)re_cov_member_latent_index;
  (void)re_cov_member_design_value;
  (void)re_cov_pair_from_member;
  (void)re_cov_pair_to_member;
  (void)re_cov_pair_parameter;
  (void)re_cov_pair_parameter_index;
  if (model_type == 93) {
    int n_phylo = Q_phylo.rows();
    int q = log_sd_phylo.size();
    matrix<Type> effect(n_phylo, q);
    for (int j = 0; j < q; ++j) {
      for (int i = 0; i < n_phylo; ++i) {
        int pos = j * n_phylo + i;
        effect(i, j) = u_re_cov_probe(pos);
      }
    }
    density::UNSTRUCTURED_CORR_t<Type> phylo_q4_density(theta_phylo);
    matrix<Type> phylo_q4_corr = phylo_q4_density.cov();
    vector<Type> sd_phylo = exp(log_sd_phylo);
    matrix<Type> phylo_q4_covariance(q, q);
    for (int a = 0; a < q; ++a) {
      for (int b = 0; b < q; ++b) {
        phylo_q4_covariance(a, b) =
          sd_phylo(a) * phylo_q4_corr(a, b) * sd_phylo(b);
      }
    }
    matrix<Type> covariance_inverse = phylo_q4_covariance.inverse();
    Type log_det_covariance = log(phylo_q4_covariance.determinant());
    matrix<Type> quadratic_matrix(q, q);
    quadratic_matrix.setZero();
    for (int b = 0; b < q; ++b) {
      vector<Type> effect_b(n_phylo);
      for (int i = 0; i < n_phylo; ++i) {
        effect_b(i) = effect(i, b);
      }
      vector<Type> Q_effect_b = Q_phylo * effect_b;
      for (int a = 0; a < q; ++a) {
        for (int i = 0; i < n_phylo; ++i) {
          quadratic_matrix(a, b) += effect(i, a) * Q_effect_b(i);
        }
      }
    }
    Type quadratic = Type(0.0);
    for (int a = 0; a < q; ++a) {
      for (int b = 0; b < q; ++b) {
        quadratic += covariance_inverse(a, b) * quadratic_matrix(a, b);
      }
    }
    nll += Type(0.5) * (
      Type(n_phylo * q) * log(Type(2.0) * M_PI) +
      Type(n_phylo) * log_det_covariance -
      Type(q) * log_det_Q_phylo +
      quadratic
    );
    REPORT(quadratic);
    REPORT(log_det_covariance);
    REPORT(quadratic_matrix);
    REPORT(sd_phylo);
    REPORT(theta_phylo);
    REPORT(phylo_q4_corr);
    REPORT(phylo_q4_covariance);
  } else if (model_type == 94) {
    int n_phylo = Q_phylo.rows();
    int q = re_cov_probe_covariance.rows();
    matrix<Type> effect(n_phylo, q);
    for (int j = 0; j < q; ++j) {
      for (int i = 0; i < n_phylo; ++i) {
        int pos = j * n_phylo + i;
        effect(i, j) = u_re_cov_probe(pos);
      }
    }
    matrix<Type> covariance_inverse = re_cov_probe_covariance.inverse();
    Type log_det_covariance = log(re_cov_probe_covariance.determinant());
    matrix<Type> quadratic_matrix(q, q);
    quadratic_matrix.setZero();
    for (int b = 0; b < q; ++b) {
      vector<Type> effect_b(n_phylo);
      for (int i = 0; i < n_phylo; ++i) {
        effect_b(i) = effect(i, b);
      }
      vector<Type> Q_effect_b = Q_phylo * effect_b;
      for (int a = 0; a < q; ++a) {
        for (int i = 0; i < n_phylo; ++i) {
          quadratic_matrix(a, b) += effect(i, a) * Q_effect_b(i);
        }
      }
    }
    Type quadratic = Type(0.0);
    for (int a = 0; a < q; ++a) {
      for (int b = 0; b < q; ++b) {
        quadratic += covariance_inverse(a, b) * quadratic_matrix(a, b);
      }
    }
    nll += Type(0.5) * (
      Type(n_phylo * q) * log(Type(2.0) * M_PI) +
      Type(n_phylo) * log_det_covariance -
      Type(q) * log_det_Q_phylo +
      quadratic
    );
    REPORT(quadratic);
    REPORT(log_det_covariance);
    REPORT(quadratic_matrix);
  } else if (model_type == 95 || model_type == 96 || model_type == 97) {
    density::UNSTRUCTURED_CORR_t<Type> re_cov_probe_density(re_cov_probe_theta);
    matrix<Type> re_cov_probe_corr = re_cov_probe_density.cov();
    matrix<Type> re_cov_probe_contribution(
      re_cov_member_design_value.rows(),
      re_cov_member_design_value.cols()
    );
    re_cov_probe_contribution.setZero();
    for (int b = 0; b < n_re_cov_blocks; ++b) {
      int block_size = re_cov_block_size(b);
      int n_groups = re_cov_block_group_count(b);
      int member_start = re_cov_block_member_start(b);
      for (int g = 0; g < n_groups; ++g) {
        vector<Type> z(block_size);
        for (int m = 0; m < block_size; ++m) {
          int z_pos = g * block_size + m;
          z(m) = Type(0.0);
          if (z_pos < u_re_cov_probe.size()) {
            z(m) = u_re_cov_probe(z_pos);
          } else if (z_pos < re_cov_probe_z.size()) {
            z(m) = re_cov_probe_z(z_pos);
          }
        }
        vector<Type> latent(block_size);
        if (re_cov_probe_sd.size() == block_size) {
          latent = density::VECSCALE(
            re_cov_probe_density,
            re_cov_probe_sd
          ).sqrt_cov_scale(z);
        } else {
          latent = re_cov_probe_density.sqrt_cov_scale(z);
        }
        for (int m = 0; m < block_size; ++m) {
          int member_col = member_start + m;
          for (int i = 0; i < re_cov_member_design_value.rows(); ++i) {
            if (re_cov_member_latent_index(i, member_col) == g) {
              re_cov_probe_contribution(i, member_col) =
                re_cov_member_design_value(i, member_col) * latent(m);
            }
          }
        }
      }
    }
    for (int j = 0; j < u_re_cov_probe.size(); ++j) {
      nll -= dnorm(u_re_cov_probe(j), Type(0.0), Type(1.0), true);
    }
    if (model_type == 95) {
      vector<Type> mu1 = X_mu1 * beta_mu1;
      vector<Type> mu2 = X_mu2 * beta_mu2;
      vector<Type> log_sigma1 = X_sigma1 * beta_sigma1;
      vector<Type> log_sigma2 = X_sigma2 * beta_sigma2;
      vector<Type> eta_rho12 = X_rho12 * beta_rho12;
      vector<Type> rho12 = Type(0.99999999) * tanh(eta_rho12);
      for (int i = 0; i < y1.size(); ++i) {
        if (i < re_cov_probe_contribution.rows()) {
          for (int m = 0; m < re_cov_probe_contribution.cols(); ++m) {
            int dpar_code = re_cov_member_dpar(m);
            if (dpar_code == 2) {
              mu1(i) += re_cov_probe_contribution(i, m);
            } else if (dpar_code == 3) {
              mu2(i) += re_cov_probe_contribution(i, m);
            } else if (dpar_code == 4) {
              log_sigma1(i) += re_cov_probe_contribution(i, m);
            } else if (dpar_code == 5) {
              log_sigma2(i) += re_cov_probe_contribution(i, m);
            }
          }
        }
      }
      vector<Type> sigma1 = exp(log_sigma1);
      vector<Type> sigma2 = exp(log_sigma2);
      Type log2pi = log(Type(2.0) * M_PI);
      for (int i = 0; i < y1.size(); ++i) {
        if (observed_y1(i) == 1 && observed_y2(i) == 1) {
          Type z1 = (y1(i) - mu1(i)) / sigma1(i);
          Type z2 = (y2(i) - mu2(i)) / sigma2(i);
          Type one_minus_rho2 = Type(1.0) - rho12(i) * rho12(i);
          Type row_nll = log2pi + log_sigma1(i) + log_sigma2(i);
          row_nll += Type(0.5) * log(one_minus_rho2);
          row_nll += Type(0.5) * (z1 * z1 - Type(2.0) * rho12(i) * z1 * z2 + z2 * z2) / one_minus_rho2;
          nll += weights(i) * row_nll;
        } else if (observed_y1(i) == 1) {
          Type z1 = (y1(i) - mu1(i)) / sigma1(i);
          Type row_nll = Type(0.5) * log2pi + log_sigma1(i);
          row_nll += Type(0.5) * z1 * z1;
          nll += weights(i) * row_nll;
        } else if (observed_y2(i) == 1) {
          Type z2 = (y2(i) - mu2(i)) / sigma2(i);
          Type row_nll = Type(0.5) * log2pi + log_sigma2(i);
          row_nll += Type(0.5) * z2 * z2;
          nll += weights(i) * row_nll;
        }
      }
      REPORT(mu1);
      REPORT(mu2);
      REPORT(log_sigma1);
      REPORT(log_sigma2);
      REPORT(sigma1);
      REPORT(sigma2);
      REPORT(eta_rho12);
      REPORT(rho12);
    } else if (model_type == 96) {
      vector<Type> mu = X_mu * beta_mu;
      vector<Type> log_sigma = X_sigma * beta_sigma;
      for (int i = 0; i < y.size(); ++i) {
        if (i < re_cov_probe_contribution.rows()) {
          for (int m = 0; m < re_cov_probe_contribution.cols(); ++m) {
            if (re_cov_member_component(m) == 0) {
              mu(i) += re_cov_probe_contribution(i, m);
            } else if (re_cov_member_component(m) == 1) {
              log_sigma(i) += re_cov_probe_contribution(i, m);
            }
          }
        }
      }
      vector<Type> sigma = exp(log_sigma);
      vector<Type> obs_sigma = sqrt(V_known + sigma * sigma);
      for (int i = 0; i < y.size(); ++i) {
        nll -= weights(i) * dnorm(y(i), mu(i), obs_sigma(i), true);
      }
      REPORT(mu);
      REPORT(log_sigma);
      REPORT(sigma);
      REPORT(obs_sigma);
    }
    REPORT(re_cov_probe_corr);
    REPORT(re_cov_probe_contribution);
  } else if (model_type == 98) {
    density::UNSTRUCTURED_CORR_t<Type> re_cov_probe_density(re_cov_probe_theta);
    matrix<Type> re_cov_probe_corr = re_cov_probe_density.cov();
    vector<Type> re_cov_probe_latent(re_cov_probe_z.size());
    if (re_cov_probe_z.size() > 0) {
      if (re_cov_probe_sd.size() == re_cov_probe_z.size()) {
        re_cov_probe_latent = density::VECSCALE(
          re_cov_probe_density,
          re_cov_probe_sd
        ).sqrt_cov_scale(re_cov_probe_z);
      } else {
        re_cov_probe_latent = re_cov_probe_density.sqrt_cov_scale(re_cov_probe_z);
      }
    }
    if (re_cov_probe_x.size() > 0) {
      if (re_cov_probe_sd.size() == re_cov_probe_x.size()) {
        nll += density::VECSCALE(
          re_cov_probe_density,
          re_cov_probe_sd
        )(re_cov_probe_x);
      } else {
        nll += re_cov_probe_density(re_cov_probe_x);
      }
    }
    REPORT(re_cov_probe_corr);
    REPORT(re_cov_probe_latent);
  } else if (model_type == 99) {
    int n_phylo = u_phylo.size();
    vector<Type> Q_u = Q_phylo * u_phylo;
    Type quadratic = Type(0.0);
    for (int i = 0; i < n_phylo; ++i) {
      quadratic += u_phylo(i) * Q_u(i);
    }
    nll += Type(0.5) * (
      Type(n_phylo) * log(Type(2.0) * M_PI) +
      Type(2.0) * Type(n_phylo) * log_sd_phylo(0) -
      log_det_Q_phylo +
      exp(Type(-2.0) * log_sd_phylo(0)) * quadratic
    );
    REPORT(quadratic);
    REPORT(log_det_Q_phylo);
  } else if (model_type == 1) {
    if (use_gaussian_aggregation == 1) {
      vector<Type> mu = offset_mu_agg + X_mu_agg * beta_mu;
      vector<Type> log_sigma = offset_sigma_agg + X_sigma_agg * beta_sigma;
      vector<Type> sigma = exp(log_sigma);
      for (int g = 0; g < n_agg; ++g) {
        Type variance = sigma(g) * sigma(g);
        Type quadratic =
          agg_sum_y2(g) -
          Type(2.0) * mu(g) * agg_sum_y(g) +
          agg_n(g) * mu(g) * mu(g);
        nll += Type(0.5) * agg_n(g) * log(Type(2.0) * M_PI) +
          agg_n(g) * log_sigma(g) +
          Type(0.5) * quadratic / variance;
      }
      REPORT(mu);
      REPORT(log_sigma);
      REPORT(sigma);
      REPORT(agg_n);
      REPORT(agg_sum_y);
      REPORT(agg_sum_y2);
      ADREPORT(beta_mu);
      ADREPORT(beta_sigma);
    } else {
      vector<Type> fixed_mu(y.size());
      if (use_sparse_X_mu == 1) {
        fixed_mu = X_mu_sparse * beta_mu;
      } else {
        fixed_mu = X_mu * beta_mu;
      }
      vector<Type> mu = fixed_mu;
      vector<Type> log_sigma = X_sigma * beta_sigma;

      if (n_re_cov_blocks > 0) {
        int n_re_cov_qgt2_blocks = 0;
        for (int b = 0; b < n_re_cov_blocks; ++b) {
          if (re_cov_block_size(b) > 2) {
            n_re_cov_qgt2_blocks += 1;
          }
        }
        if (n_re_cov_qgt2_blocks > 0) {
          int theta_offset = 0;
          int sd_offset = 0;
          int u_offset = 0;
          int rho_offset = 0;
          vector<Type> sd_re_cov(log_sd_re_cov.size());
          for (int j = 0; j < log_sd_re_cov.size(); ++j) {
            sd_re_cov(j) = exp(log_sd_re_cov(j));
          }
          vector<Type> rho_re_cov(theta_re_cov.size());
          matrix<Type> re_cov_contribution(
            re_cov_member_design_value.rows(),
            re_cov_member_design_value.cols()
          );
          re_cov_contribution.setZero();

          for (int b = 0; b < n_re_cov_blocks; ++b) {
            int block_size = re_cov_block_size(b);
            int n_groups = re_cov_block_group_count(b);
            int member_start = re_cov_block_member_start(b);
            int pair_start = re_cov_block_pair_start(b);
            int n_pairs = block_size * (block_size - 1) / 2;
            if (block_size <= 2) {
              continue;
            }

            vector<Type> theta_block(n_pairs);
            for (int p = 0; p < n_pairs; ++p) {
              theta_block(p) = theta_re_cov(theta_offset + p);
            }
            density::UNSTRUCTURED_CORR_t<Type> re_cov_density(theta_block);
            matrix<Type> re_cov_corr = re_cov_density.cov();
            vector<Type> sd_block(block_size);
            for (int m = 0; m < block_size; ++m) {
              sd_block(m) = sd_re_cov(sd_offset + m);
            }
            for (int p = 0; p < n_pairs; ++p) {
              int from = re_cov_pair_from_member(pair_start + p);
              int to = re_cov_pair_to_member(pair_start + p);
              rho_re_cov(rho_offset + p) = re_cov_corr(from, to);
            }

            for (int g = 0; g < n_groups; ++g) {
              vector<Type> z(block_size);
              for (int m = 0; m < block_size; ++m) {
                z(m) = u_re_cov(u_offset + g * block_size + m);
              }
              vector<Type> latent = density::VECSCALE(
                re_cov_density,
                sd_block
              ).sqrt_cov_scale(z);
              for (int m = 0; m < block_size; ++m) {
                int member_col = member_start + m;
                for (int i = 0; i < y.size(); ++i) {
                  if (re_cov_member_latent_index(i, member_col) == g) {
                    Type contribution =
                      re_cov_member_design_value(i, member_col) * latent(m);
                    re_cov_contribution(i, member_col) = contribution;
                    int dpar_code = re_cov_member_dpar(member_col);
                    if (dpar_code == 0) {
                      mu(i) += contribution;
                    } else if (dpar_code == 1) {
                      log_sigma(i) += contribution;
                    }
                  }
                }
              }
            }

            theta_offset += n_pairs;
            sd_offset += block_size;
            u_offset += n_groups * block_size;
            rho_offset += n_pairs;
          }
          for (int j = 0; j < u_re_cov.size(); ++j) {
            nll -= dnorm(u_re_cov(j), Type(0.0), Type(1.0), true);
          }
          if (theta_re_cov.size() > 0) {
            REPORT(u_re_cov);
            REPORT(log_sd_re_cov);
            REPORT(sd_re_cov);
            REPORT(theta_re_cov);
            REPORT(rho_re_cov);
            REPORT(re_cov_contribution);
            ADREPORT(log_sd_re_cov);
            ADREPORT(sd_re_cov);
            ADREPORT(theta_re_cov);
            ADREPORT(rho_re_cov);
          }
        }
      }

      if (n_mu_re_terms > 0) {
        vector<Type> sd_mu_re = exp(log_sd_mu);
        vector<Type> sd_mu_group(X_sd_mu.rows());
        if (has_sd_mu_model == 1) {
          for (int g = 0; g < X_sd_mu.rows(); ++g) {
            Type eta_sd = Type(0.0);
            for (int k = 0; k < X_sd_mu.cols(); ++k) {
              eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
            }
            sd_mu_group(g) = exp(eta_sd);
          }
        }
        vector<Type> rho_mu_re(n_mu_re_cors);
        for (int j = 0; j < n_mu_re_cors; ++j) {
          rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
        }
        for (int i = 0; i < y.size(); ++i) {
          for (int j = 0; j < n_mu_re_terms; ++j) {
            int idx = mu_re_index(i, j);
            int cor_id = mu_re_cor_id(idx);
            int sd_row = mu_re_sd_row(idx);
            Type sd_current = sd_mu_re(mu_re_term(idx));
            if (sd_row >= 0) {
              sd_current = sd_mu_group(sd_row);
            }
            Type u_cond = u_mu(idx);
            if (cor_id >= 0 && mu_re_pos(idx) == 1) {
              Type rho = rho_mu_re(cor_id);
              int pair_idx = mu_re_pair_index(idx);
              u_cond = rho * u_mu(pair_idx) + sqrt(Type(1.0) - rho * rho) * u_mu(idx);
            }
            mu(i) += mu_re_value(i, j) * sd_current * u_cond;
          }
        }
        for (int j = 0; j < u_mu.size(); ++j) {
          nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
        }
      }

    if (n_sigma_re_terms > 0) {
      vector<Type> sd_sigma_re = exp(log_sd_sigma);
      vector<Type> rho_mu_sigma_re(n_mu_sigma_re_cors);
      for (int j = 0; j < n_mu_sigma_re_cors; ++j) {
        rho_mu_sigma_re(j) = Type(0.999999) * tanh(eta_cor_mu_sigma(j));
      }
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_sigma_re_terms; ++j) {
          int idx = sigma_re_index(i, j);
          Type u_cond = u_sigma(idx);
          int cross_cor_id = sigma_re_cross_cor(idx);
          if (cross_cor_id >= 0) {
            Type rho = rho_mu_sigma_re(cross_cor_id);
            int mu_idx = sigma_re_cross_mu(idx);
            u_cond = rho * u_mu(mu_idx) + sqrt(Type(1.0) - rho * rho) * u_sigma(idx);
          }
          log_sigma(i) += sigma_re_value(i, j) * sd_sigma_re(sigma_re_term(idx)) * u_cond;
        }
      }
      for (int j = 0; j < u_sigma.size(); ++j) {
        nll -= dnorm(u_sigma(j), Type(0.0), Type(1.0), true);
      }
    }

    if (has_phylo_mu == 1) {
      vector<Type> sd_phylo_group(X_sd_phylo.rows());
      vector<Type> log_sd_phylo_group(X_sd_phylo.rows());
      vector<Type> sd_phylo = exp(log_sd_phylo);
      if (has_sd_phylo_model == 1) {
        for (int g = 0; g < X_sd_phylo.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_phylo.cols(); ++k) {
            eta_sd += X_sd_phylo(g, k) *
              beta_sd_mu(sd_phylo_beta_offset + k);
          }
          log_sd_phylo_group(g) = eta_sd;
          sd_phylo_group(g) = exp(eta_sd);
        }
      }
      int n_phylo = Q_phylo.rows();
      int q_phylo = log_sd_phylo.size();
      bool has_cross_dpar_phylo =
        q_phylo == 2 && phylo_mu_dpar(0) != phylo_mu_dpar(1);
      for (int i = 0; i < y.size(); ++i) {
        for (int k = 0; k < q_phylo; ++k) {
          int effect_index = k * n_phylo + phylo_mu_node_index(i);
          Type field_effect = u_phylo(effect_index);
          if (has_sd_phylo_model == 1) {
            field_effect *= sd_phylo_group(phylo_mu_sd_row(i));
          }
          Type contribution = phylo_mu_value(i, k) * field_effect;
          if (phylo_mu_dpar(k) == 1) {
            log_sigma(i) += contribution;
          } else {
            mu(i) += contribution;
          }
        }
      }
      Type quadratic = Type(0.0);
      if (has_cross_dpar_phylo && has_sd_phylo_model == 0) {
        Type rho_phylo = Type(0.999999) * tanh(eta_cor_phylo);
        vector<Type> u1(n_phylo);
        vector<Type> u2(n_phylo);
        for (int j = 0; j < n_phylo; ++j) {
          u1(j) = u_phylo(j);
          u2(j) = u_phylo(n_phylo + j);
        }
        vector<Type> Q_u1 = Q_phylo * u1;
        vector<Type> Q_u2 = Q_phylo * u2;
        Type q11 = Type(0.0);
        Type q12 = Type(0.0);
        Type q22 = Type(0.0);
        for (int j = 0; j < n_phylo; ++j) {
          q11 += u1(j) * Q_u1(j);
          q12 += u1(j) * Q_u2(j);
          q22 += u2(j) * Q_u2(j);
        }
        Type one_minus_rho2 = Type(1.0) - rho_phylo * rho_phylo;
        Type sd1 = sd_phylo(0);
        Type sd2 = sd_phylo(1);
        Type inv11 = Type(1.0) / (sd1 * sd1 * one_minus_rho2);
        Type inv22 = Type(1.0) / (sd2 * sd2 * one_minus_rho2);
        Type inv12 = -rho_phylo / (sd1 * sd2 * one_minus_rho2);
        Type log_det_cov = Type(2.0) * log_sd_phylo(0) +
          Type(2.0) * log_sd_phylo(1) +
          log(one_minus_rho2);
        Type quadratic_phylo =
          inv11 * q11 + Type(2.0) * inv12 * q12 + inv22 * q22;
        quadratic = quadratic_phylo;
        nll += Type(0.5) * (
          Type(2 * n_phylo) * log(Type(2.0) * M_PI) +
          Type(n_phylo) * log_det_cov -
          Type(2.0) * log_det_Q_phylo +
          quadratic_phylo
        );
        REPORT(eta_cor_phylo);
        REPORT(rho_phylo);
        ADREPORT(eta_cor_phylo);
        ADREPORT(rho_phylo);
      } else {
        for (int k = 0; k < q_phylo; ++k) {
          vector<Type> effect_k(n_phylo);
          for (int j = 0; j < n_phylo; ++j) {
            effect_k(j) = u_phylo(k * n_phylo + j);
          }
          vector<Type> Q_u = Q_phylo * effect_k;
          Type quadratic_k = Type(0.0);
          for (int j = 0; j < n_phylo; ++j) {
            quadratic_k += effect_k(j) * Q_u(j);
          }
          quadratic += quadratic_k;
          if (has_sd_phylo_model == 1) {
            nll += Type(0.5) * (
              Type(n_phylo) * log(Type(2.0) * M_PI) -
              log_det_Q_phylo +
              quadratic_k
            );
          } else {
            nll += Type(0.5) * (
              Type(n_phylo) * log(Type(2.0) * M_PI) +
              Type(2.0) * Type(n_phylo) * log_sd_phylo(k) -
              log_det_Q_phylo +
              exp(Type(-2.0) * log_sd_phylo(k)) * quadratic_k
            );
          }
        }
      }
      REPORT(u_phylo);
      REPORT(log_sd_phylo);
      REPORT(quadratic);
      if (has_sd_phylo_model == 1) {
        REPORT(log_sd_phylo_group);
        REPORT(sd_phylo_group);
        ADREPORT(log_sd_phylo_group);
        ADREPORT(sd_phylo_group);
      } else {
        ADREPORT(log_sd_phylo);
        REPORT(sd_phylo);
        ADREPORT(sd_phylo);
      }
      if (penalize_phylo == 1) {
        phylo_penalty = drm_phylo_penalty_value(
          log_sd_phylo, q_phylo, eta_cor_phylo, theta_phylo,
          phylo_sd_penalty_rate, phylo_cor_penalty_sd);
        nll += phylo_penalty;
        REPORT(phylo_penalty);
      }
    }

    if (has_mi == 1 && mi_family == 0) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type sigma_mi = exp(log_sigma_mi(0));
      Type sd_mi_group = Type(0.0);
      Type sd_mi_struct = Type(0.0);
      if (has_mi_group == 1) {
        sd_mi_group = exp(log_sd_mi_group(0));
        for (int i = 0; i < mi_eta.size(); ++i) {
          mi_eta(i) += sd_mi_group * u_mi_group(mi_group_index(i));
        }
        for (int g = 0; g < u_mi_group.size(); ++g) {
          nll -= dnorm(u_mi_group(g), Type(0.0), Type(1.0), true);
        }
      }
      if (has_mi_struct == 1) {
        sd_mi_struct = exp(log_sd_mi_struct(0));
        for (int i = 0; i < mi_eta.size(); ++i) {
          mi_eta(i) +=
            mi_struct_value(i) * u_mi_struct(mi_struct_index(i));
        }
        vector<Type> Q_u_mi_struct = Q_mi_struct * u_mi_struct;
        Type quadratic_mi_struct = Type(0.0);
        for (int j = 0; j < u_mi_struct.size(); ++j) {
          quadratic_mi_struct += u_mi_struct(j) * Q_u_mi_struct(j);
        }
        nll += Type(0.5) * (
          Type(u_mi_struct.size()) * log(Type(2.0) * M_PI) +
          Type(2.0) * Type(u_mi_struct.size()) * log_sd_mi_struct(0) -
          log_det_Q_mi_struct +
          exp(Type(-2.0) * log_sd_mi_struct(0)) * quadratic_mi_struct
        );
      }
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_x.size(); ++i) {
        mi_x_full(i) = mi_x(i);
      }
      for (int j = 0; j < mi_missing_index.size(); ++j) {
        int row = mi_missing_index(j);
        mi_x_full(row) = x_miss(j);
      }
      for (int i = 0; i < mi_x_full.size(); ++i) {
        nll -= dnorm(mi_x_full(i), mi_eta(i), sigma_mi, true);
      }
      for (int i = 0; i < y.size(); ++i) {
        mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(sigma_mi);
      REPORT(x_miss);
      if (has_mi_group == 1) {
        REPORT(u_mi_group);
        REPORT(log_sd_mi_group);
        REPORT(sd_mi_group);
        ADREPORT(log_sd_mi_group);
        ADREPORT(sd_mi_group);
      }
      if (has_mi_struct == 1) {
        REPORT(u_mi_struct);
        REPORT(log_sd_mi_struct);
        REPORT(sd_mi_struct);
        ADREPORT(log_sd_mi_struct);
        ADREPORT(sd_mi_struct);
      }
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_mi);
    }

    if (has_mi == 1 && mi_family == 1) {
      vector<Type> mi_eta = X_mi * beta_mi;
      vector<Type> mi_probability(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        Type log_p1 = -logspace_add(Type(0.0), -mi_eta(i));
        mi_probability(i) = exp(log_p1);
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type log_p1 = -logspace_add(Type(0.0), -mi_eta(i));
        Type log_p0 = -logspace_add(Type(0.0), mi_eta(i));
        if (mi_observed(i) == 1) {
          nll -= mi_x(i) * log_p1 + (Type(1.0) - mi_x(i)) * log_p0;
          mu(i) += beta_mu(mi_col) * (mi_x(i) - X_mu(i, mi_col));
        } else {
          Type mu1 = mu(i) + beta_mu(mi_col) * (Type(1.0) - X_mu(i, mi_col));
          Type mu0 = mu(i) + beta_mu(mi_col) * (Type(0.0) - X_mu(i, mi_col));
          Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
          Type log_y1 = observed_y(i) == 1 ?
            weights(i) * dnorm(y(i), mu1, sigma_i, true) : Type(0.0);
          Type log_y0 = observed_y(i) == 1 ?
            weights(i) * dnorm(y(i), mu0, sigma_i, true) : Type(0.0);
          nll -= logspace_add(log_p1 + log_y1, log_p0 + log_y0);
          mi_x_full(i) = mi_probability(i);
          mu(i) += beta_mu(mi_col) * (mi_probability(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(mi_probability);
      ADREPORT(beta_mi);
    }

    if (has_mi == 1 && mi_family == 2) {
      vector<Type> mi_eta = X_mi * beta_mi;
      vector<Type> mi_cutpoints(theta_ord.size());
      if (theta_ord.size() > 0) {
        mi_cutpoints(0) = theta_ord(0);
        for (int j = 1; j < theta_ord.size(); ++j) {
          mi_cutpoints(j) = mi_cutpoints(j - 1) + exp(theta_ord(j));
        }
      }
      int n_state = mi_n_state;
      matrix<Type> mi_state_probability(mi_x.size(), n_state);
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_x.size(); ++i) {
        mi_x_full(i) = mi_x(i);
        for (int state = 0; state < n_state; ++state) {
          Type log_prob;
          if (state == 0) {
            log_prob = drm_log_inv_logit(mi_cutpoints(0) - mi_eta(i));
          } else if (state == n_state - 1) {
            log_prob = drm_log1m_inv_logit(
              mi_cutpoints(n_state - 2) - mi_eta(i)
            );
          } else {
            Type upper = mi_cutpoints(state) - mi_eta(i);
            Type lower = mi_cutpoints(state - 1) - mi_eta(i);
            log_prob = drm_log_inv_logit_diff(upper, lower);
          }
          mi_state_probability(i, state) = exp(log_prob);
        }
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        if (mi_observed(i) == 1) {
          int state = (int) asDouble(mi_x(i)) - 1;
          Type log_prob;
          if (state == 0) {
            log_prob = drm_log_inv_logit(mi_cutpoints(0) - mi_eta(i));
          } else if (state == n_state - 1) {
            log_prob = drm_log1m_inv_logit(
              mi_cutpoints(n_state - 2) - mi_eta(i)
            );
          } else {
            Type upper = mi_cutpoints(state) - mi_eta(i);
            Type lower = mi_cutpoints(state - 1) - mi_eta(i);
            log_prob = drm_log_inv_logit_diff(upper, lower);
          }
          nll -= log_prob;
        } else {
          vector<Type> log_terms(n_state);
          for (int state = 0; state < n_state; ++state) {
            Type log_prob;
            if (state == 0) {
              log_prob = drm_log_inv_logit(mi_cutpoints(0) - mi_eta(i));
            } else if (state == n_state - 1) {
              log_prob = drm_log1m_inv_logit(
                mi_cutpoints(n_state - 2) - mi_eta(i)
              );
            } else {
              Type upper = mi_cutpoints(state) - mi_eta(i);
              Type lower = mi_cutpoints(state - 1) - mi_eta(i);
              log_prob = drm_log_inv_logit_diff(upper, lower);
            }
            Type state_fixed_mu = Type(0.0);
            int state_row = i * n_state + state;
            for (int col = 0; col < X_mi_state_mu.cols(); ++col) {
              state_fixed_mu += X_mi_state_mu(state_row, col) * beta_mu(col);
            }
            Type mu_state = mu(i) - fixed_mu(i) + state_fixed_mu;
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = observed_y(i) == 1 ?
              weights(i) * dnorm(y(i), mu_state, sigma_i, true) : Type(0.0);
            log_terms(state) = log_prob + log_y;
          }
          Type log_denom = log_terms(0);
          for (int state = 1; state < n_state; ++state) {
            log_denom = logspace_add(log_denom, log_terms(state));
          }
          nll -= log_denom;
          Type expected_score = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int state = 0; state < n_state; ++state) {
            Type posterior = exp(log_terms(state) - log_denom);
            mi_state_probability(i, state) = posterior;
            expected_score += Type(state + 1) * posterior;
            Type state_fixed_mu = Type(0.0);
            int state_row = i * n_state + state;
            for (int col = 0; col < X_mi_state_mu.cols(); ++col) {
              state_fixed_mu += X_mi_state_mu(state_row, col) * beta_mu(col);
            }
            expected_mu += (mu(i) - fixed_mu(i) + state_fixed_mu) * posterior;
          }
          mi_x_full(i) = expected_score;
          mu(i) = expected_mu;
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(mi_cutpoints);
      REPORT(mi_state_probability);
      ADREPORT(beta_mi);
      ADREPORT(mi_cutpoints);
    }

    if (has_mi == 1 && mi_family == 3) {
      int n_state = mi_n_state;
      int n_coef = X_mi.cols();
      matrix<Type> mi_state_probability(mi_x.size(), n_state);
      vector<Type> mi_x_full(mi_x.size());
      matrix<Type> mi_log_prior(mi_x.size(), n_state);
      for (int i = 0; i < mi_x.size(); ++i) {
        vector<Type> eta_state(n_state);
        eta_state(0) = Type(0.0);
        for (int state = 1; state < n_state; ++state) {
          Type eta = Type(0.0);
          int offset = (state - 1) * n_coef;
          for (int col = 0; col < n_coef; ++col) {
            eta += X_mi(i, col) * beta_mi(offset + col);
          }
          eta_state(state) = eta;
        }
        Type max_eta = eta_state(0);
        for (int state = 1; state < n_state; ++state) {
          max_eta = CppAD::CondExpGt(eta_state(state), max_eta, eta_state(state), max_eta);
        }
        Type denom = Type(0.0);
        for (int state = 0; state < n_state; ++state) {
          denom += exp(eta_state(state) - max_eta);
        }
        Type log_denom = max_eta + log(denom);
        mi_x_full(i) = mi_x(i);
        for (int state = 0; state < n_state; ++state) {
          mi_log_prior(i, state) = eta_state(state) - log_denom;
          mi_state_probability(i, state) = exp(mi_log_prior(i, state));
        }
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        if (mi_observed(i) == 1) {
          int state = (int) asDouble(mi_x(i)) - 1;
          nll -= mi_log_prior(i, state);
        } else {
          vector<Type> log_terms(n_state);
          for (int state = 0; state < n_state; ++state) {
            Type state_fixed_mu = Type(0.0);
            int state_row = i * n_state + state;
            for (int col = 0; col < X_mi_state_mu.cols(); ++col) {
              state_fixed_mu += X_mi_state_mu(state_row, col) * beta_mu(col);
            }
            Type mu_state = mu(i) - fixed_mu(i) + state_fixed_mu;
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = observed_y(i) == 1 ?
              weights(i) * dnorm(y(i), mu_state, sigma_i, true) : Type(0.0);
            log_terms(state) = mi_log_prior(i, state) + log_y;
          }
          Type log_denom = log_terms(0);
          for (int state = 1; state < n_state; ++state) {
            log_denom = logspace_add(log_denom, log_terms(state));
          }
          nll -= log_denom;
          Type expected_score = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int state = 0; state < n_state; ++state) {
            Type posterior = exp(log_terms(state) - log_denom);
            mi_state_probability(i, state) = posterior;
            expected_score += Type(state + 1) * posterior;
            Type state_fixed_mu = Type(0.0);
            int state_row = i * n_state + state;
            for (int col = 0; col < X_mi_state_mu.cols(); ++col) {
              state_fixed_mu += X_mi_state_mu(state_row, col) * beta_mu(col);
            }
            expected_mu += (mu(i) - fixed_mu(i) + state_fixed_mu) * posterior;
          }
          mi_x_full(i) = expected_score;
          mu(i) = expected_mu;
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(mi_state_probability);
      ADREPORT(beta_mi);
    }

    if (has_mi == 1 && mi_family == 4) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_beta_mi = log_sigma_mi(0);
      Type sigma_beta_mi = exp(log_sigma_beta_mi);
      Type phi_beta_mi = exp(Type(-2.0) * log_sigma_beta_mi);
      Type beta_mi_eps = Type(1e-12);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        Type mu_raw = exp(drm_log_inv_logit(mi_eta(i)));
        mi_mean(i) = beta_mi_eps +
          (Type(1.0) - Type(2.0) * beta_mi_eps) * mu_raw;
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type alpha_i = mi_mean(i) * phi_beta_mi;
        Type beta_i = (Type(1.0) - mi_mean(i)) * phi_beta_mi;
        Type shape_floor = Type(1e-8);
        alpha_i = CppAD::CondExpLt(
          alpha_i,
          shape_floor,
          shape_floor,
          alpha_i
        );
        beta_i = CppAD::CondExpLt(
          beta_i,
          shape_floor,
          shape_floor,
          beta_i
        );
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density =
            lgamma(alpha_i + beta_i) -
            lgamma(alpha_i) -
            lgamma(beta_i) +
            (alpha_i - Type(1.0)) * log(x_i) +
            (beta_i - Type(1.0)) * log(Type(1.0) - x_i);
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              lgamma(alpha_i + beta_i) -
              lgamma(alpha_i) -
              lgamma(beta_i) +
              (alpha_i - Type(1.0)) * log(x_q) +
              (beta_i - Type(1.0)) * log(Type(1.0) - x_q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log(mi_quad_weights(q)) + log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              lgamma(alpha_i + beta_i) -
              lgamma(alpha_i) -
              lgamma(beta_i) +
              (alpha_i - Type(1.0)) * log(x_q) +
              (beta_i - Type(1.0)) * log(Type(1.0) - x_q);
            Type term = mi_quad_weights(q) * exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(sigma_beta_mi);
      REPORT(phi_beta_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_beta_mi);
    }

    if (has_mi == 1 && mi_family == 10) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_zob_mi = log_sigma_mi(0);
      Type sigma_zob_mi = exp(log_sigma_zob_mi);
      Type phi_zob_mi = exp(Type(-2.0) * log_sigma_zob_mi);
      Type eta_zoi_mi = beta_zoi(0);
      Type eta_coi_mi = beta_coi(0);
      Type log_zoi_mi = -logspace_add(Type(0.0), -eta_zoi_mi);
      Type log_one_minus_zoi_mi = -logspace_add(Type(0.0), eta_zoi_mi);
      Type log_coi_mi = -logspace_add(Type(0.0), -eta_coi_mi);
      Type log_one_minus_coi_mi = -logspace_add(Type(0.0), eta_coi_mi);
      Type zoi_mi = Type(1.0) / (Type(1.0) + exp(-eta_zoi_mi));
      Type coi_mi = Type(1.0) / (Type(1.0) + exp(-eta_coi_mi));
      Type beta_mi_eps = Type(1e-12);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        Type mu_raw = exp(drm_log_inv_logit(mi_eta(i)));
        mi_mean(i) = beta_mi_eps +
          (Type(1.0) - Type(2.0) * beta_mi_eps) * mu_raw;
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type alpha_i = mi_mean(i) * phi_zob_mi;
        Type beta_i = (Type(1.0) - mi_mean(i)) * phi_zob_mi;
        Type shape_floor = Type(1e-8);
        alpha_i = CppAD::CondExpLt(
          alpha_i,
          shape_floor,
          shape_floor,
          alpha_i
        );
        beta_i = CppAD::CondExpLt(
          beta_i,
          shape_floor,
          shape_floor,
          beta_i
        );
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density;
          if (asDouble(x_i) <= 0.0) {
            log_density = log_zoi_mi + log_one_minus_coi_mi;
          } else if (asDouble(x_i) >= 1.0) {
            log_density = log_zoi_mi + log_coi_mi;
          } else {
            log_density =
              log_one_minus_zoi_mi +
              lgamma(alpha_i + beta_i) -
              lgamma(alpha_i) -
              lgamma(beta_i) +
              (alpha_i - Type(1.0)) * log(x_i) +
              (beta_i - Type(1.0)) * log(Type(1.0) - x_i);
          }
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density;
            if (asDouble(x_q) <= 0.0) {
              log_density = log_zoi_mi + log_one_minus_coi_mi;
            } else if (asDouble(x_q) >= 1.0) {
              log_density = log_zoi_mi + log_coi_mi;
            } else {
              log_density =
                log_one_minus_zoi_mi +
                lgamma(alpha_i + beta_i) -
                lgamma(alpha_i) -
                lgamma(beta_i) +
                (alpha_i - Type(1.0)) * log(x_q) +
                (beta_i - Type(1.0)) * log(Type(1.0) - x_q);
            }
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log(mi_quad_weights(q)) + log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density;
            if (asDouble(x_q) <= 0.0) {
              log_density = log_zoi_mi + log_one_minus_coi_mi;
            } else if (asDouble(x_q) >= 1.0) {
              log_density = log_zoi_mi + log_coi_mi;
            } else {
              log_density =
                log_one_minus_zoi_mi +
                lgamma(alpha_i + beta_i) -
                lgamma(alpha_i) -
                lgamma(beta_i) +
                (alpha_i - Type(1.0)) * log(x_q) +
                (beta_i - Type(1.0)) * log(Type(1.0) - x_q);
            }
            Type term = mi_quad_weights(q) * exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(sigma_zob_mi);
      REPORT(phi_zob_mi);
      REPORT(zoi_mi);
      REPORT(coi_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_zob_mi);
      ADREPORT(beta_zoi);
      ADREPORT(beta_coi);
    }

    if (has_mi == 1 && mi_family == 12) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_betabinom_mi = log_sigma_mi(0);
      Type sigma_betabinom_mi = exp(log_sigma_betabinom_mi);
      Type phi_betabinom_mi = exp(Type(-2.0) * log_sigma_betabinom_mi);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_mean(i) = Type(1.0) / (Type(1.0) + exp(-mi_eta(i)));
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type alpha_i = mi_mean(i) * phi_betabinom_mi;
        Type beta_i = (Type(1.0) - mi_mean(i)) * phi_betabinom_mi;
        Type shape_floor = Type(1e-8);
        alpha_i = CppAD::CondExpLt(
          alpha_i,
          shape_floor,
          shape_floor,
          alpha_i
        );
        beta_i = CppAD::CondExpLt(
          beta_i,
          shape_floor,
          shape_floor,
          beta_i
        );
        Type n_i = mi_trials(i);
        if (mi_observed(i) == 1) {
          Type k_i = mi_successes(i);
          Type failure_i = n_i - k_i;
          Type log_density =
            lgamma(n_i + Type(1.0)) -
            lgamma(k_i + Type(1.0)) -
            lgamma(failure_i + Type(1.0)) +
            lgamma(phi_betabinom_mi) -
            lgamma(n_i + phi_betabinom_mi) +
            lgamma(k_i + alpha_i) -
            lgamma(alpha_i) +
            lgamma(failure_i + beta_i) -
            lgamma(beta_i);
          Type x_i = k_i / n_i;
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          int n_success = (int) asDouble(n_i);
          vector<Type> log_terms(n_success + 1);
          for (int k = 0; k <= n_success; ++k) {
            Type k_q = Type(k);
            Type failure_q = n_i - k_q;
            Type x_q = k_q / n_i;
            Type log_density =
              lgamma(n_i + Type(1.0)) -
              lgamma(k_q + Type(1.0)) -
              lgamma(failure_q + Type(1.0)) +
              lgamma(phi_betabinom_mi) -
              lgamma(n_i + phi_betabinom_mi) +
              lgamma(k_q + alpha_i) -
              lgamma(alpha_i) +
              lgamma(failure_q + beta_i) -
              lgamma(beta_i);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(k) = log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int k = 1; k <= n_success; ++k) {
            log_denom = logspace_add(log_denom, log_terms(k));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int k = 0; k <= n_success; ++k) {
            Type posterior = exp(log_terms(k) - log_denom);
            Type x_q = Type(k) / n_i;
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          mi_x_full(i) = mi_mean(i);
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(mi_mean);
      REPORT(sigma_betabinom_mi);
      REPORT(phi_betabinom_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_betabinom_mi);
    }

    if (has_mi == 1 && mi_family == 5) {
      vector<Type> mi_eta = X_mi * beta_mi;
      vector<Type> mi_lambda(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_lambda(i) = exp(mi_eta(i));
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type log_lambda_i = mi_eta(i);
        Type lambda_i = mi_lambda(i);
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density = x_i * log_lambda_i - lambda_i -
            lgamma(x_i + Type(1.0));
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density = x_q * log_lambda_i - lambda_i -
              lgamma(x_q + Type(1.0));
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density = x_q * log_lambda_i - lambda_i -
              lgamma(x_q + Type(1.0));
            Type term = exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(mi_lambda);
      ADREPORT(beta_mi);
    }

    if (has_mi == 1 && mi_family == 8) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_nbinom2_mi = log_sigma_mi(0);
      Type sigma_nbinom2_mi = exp(log_sigma_nbinom2_mi);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_mean(i) = exp(mi_eta(i));
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type log_mu_i = mi_eta(i);
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density =
            drm_nbinom2_log_density(
              x_i,
              log_mu_i,
              log_sigma_nbinom2_mi
            );
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              drm_nbinom2_log_density(
                x_q,
                log_mu_i,
                log_sigma_nbinom2_mi
              );
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              drm_nbinom2_log_density(
                x_q,
                log_mu_i,
                log_sigma_nbinom2_mi
              );
            Type term = exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(mi_mean);
      REPORT(sigma_nbinom2_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_nbinom2_mi);
    }

    if (has_mi == 1 && mi_family == 11) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_trunc_nbinom2_mi = log_sigma_mi(0);
      Type sigma_trunc_nbinom2_mi = exp(log_sigma_trunc_nbinom2_mi);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_positive_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_mean(i) = exp(mi_eta(i));
        Type log_p0 = drm_nbinom2_log_p0(
          mi_eta(i),
          log_sigma_trunc_nbinom2_mi
        );
        Type log_trunc_prob = drm_log1mexp(log_p0);
        mi_positive_mean(i) = mi_mean(i) / exp(log_trunc_prob);
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type log_mu_i = mi_eta(i);
        Type log_p0 = drm_nbinom2_log_p0(
          log_mu_i,
          log_sigma_trunc_nbinom2_mi
        );
        Type log_trunc_prob = drm_log1mexp(log_p0);
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density =
            drm_nbinom2_log_density(
              x_i,
              log_mu_i,
              log_sigma_trunc_nbinom2_mi
            ) -
            log_trunc_prob;
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              drm_nbinom2_log_density(
                x_q,
                log_mu_i,
                log_sigma_trunc_nbinom2_mi
              ) -
              log_trunc_prob;
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density =
              drm_nbinom2_log_density(
                x_q,
                log_mu_i,
                log_sigma_trunc_nbinom2_mi
              ) -
              log_trunc_prob;
            Type term = exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(mi_mean);
      REPORT(mi_positive_mean);
      REPORT(sigma_trunc_nbinom2_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_trunc_nbinom2_mi);
    }

    if (has_mi == 1 && mi_family == 6) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_lognormal_mi = log_sigma_mi(0);
      Type sigma_lognormal_mi = exp(log_sigma_lognormal_mi);
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_x.size(); ++i) {
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_x_i = log(x_i);
          Type log_density =
            dnorm(log_x_i, mi_eta(i), sigma_lognormal_mi, true) - log_x_i;
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type z_q = mi_quad_nodes(q);
            Type x_q = exp(mi_eta(i) + sigma_lognormal_mi * z_q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log(mi_quad_weights(q)) + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type z_q = mi_quad_nodes(q);
            Type x_q = exp(mi_eta(i) + sigma_lognormal_mi * z_q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type z_q = mi_quad_nodes(q);
            Type x_q = exp(mi_eta(i) + sigma_lognormal_mi * z_q);
            Type term = mi_quad_weights(q);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(sigma_lognormal_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_lognormal_mi);
    }

    if (has_mi == 1 && mi_family == 7) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_gamma_mi = log_sigma_mi(0);
      Type sigma_gamma_mi = exp(log_sigma_gamma_mi);
      Type shape_gamma_mi = exp(Type(-2.0) * log_sigma_gamma_mi);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_mean(i) = exp(mi_eta(i));
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type scale_i = mi_mean(i) * sigma_gamma_mi * sigma_gamma_mi;
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density =
            (shape_gamma_mi - Type(1.0)) * log(x_i) -
            x_i / scale_i -
            lgamma(shape_gamma_mi) -
            shape_gamma_mi * log(scale_i);
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type t_q = mi_quad_nodes(q);
            Type x_q = scale_i * t_q;
            Type log_prior =
              log(mi_quad_weights(q)) +
              (shape_gamma_mi - Type(1.0)) * log(t_q) -
              lgamma(shape_gamma_mi);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log_prior + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = scale_i * mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type t_q = mi_quad_nodes(q);
            Type x_q = scale_i * t_q;
            Type term =
              mi_quad_weights(q) *
              exp(
                (shape_gamma_mi - Type(1.0)) * log(t_q) -
                lgamma(shape_gamma_mi)
              );
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(sigma_gamma_mi);
      REPORT(shape_gamma_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_gamma_mi);
    }

    if (has_mi == 1 && mi_family == 9) {
      vector<Type> mi_eta = X_mi * beta_mi;
      Type log_sigma_tweedie_mi = log_sigma_mi(0);
      Type sigma_tweedie_mi = exp(log_sigma_tweedie_mi);
      Type phi_tweedie_mi = sigma_tweedie_mi * sigma_tweedie_mi;
      Type power_tweedie_mi = Type(1.5);
      vector<Type> mi_mean(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        mi_mean(i) = exp(mi_eta(i));
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        if (mi_observed(i) == 1) {
          Type x_i = mi_x(i);
          Type log_density = dtweedie(
            x_i,
            mi_mean(i),
            phi_tweedie_mi,
            power_tweedie_mi,
            true
          );
          nll -= log_density;
          mu(i) += beta_mu(mi_col) * (x_i - X_mu(i, mi_col));
        } else if (observed_y(i) == 1) {
          vector<Type> log_terms(mi_quad_nodes.size());
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density = dtweedie(
              x_q,
              mi_mean(i),
              phi_tweedie_mi,
              power_tweedie_mi,
              true
            );
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            Type sigma_i = sqrt(V_known(i) + exp(Type(2.0) * log_sigma(i)));
            Type log_y = weights(i) * dnorm(y(i), mu_q, sigma_i, true);
            log_terms(q) = log(mi_quad_weights(q)) + log_density + log_y;
          }
          Type log_denom = log_terms(0);
          for (int q = 1; q < mi_quad_nodes.size(); ++q) {
            log_denom = logspace_add(log_denom, log_terms(q));
          }
          nll -= log_denom;
          Type conditional_mean = Type(0.0);
          Type expected_mu = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type posterior = exp(log_terms(q) - log_denom);
            Type x_q = mi_quad_nodes(q);
            Type mu_q = mu(i) +
              beta_mu(mi_col) * (x_q - X_mu(i, mi_col));
            conditional_mean += x_q * posterior;
            expected_mu += mu_q * posterior;
          }
          mi_x_full(i) = conditional_mean;
          mu(i) = expected_mu;
        } else {
          Type prior_norm = Type(0.0);
          Type prior_mean = Type(0.0);
          for (int q = 0; q < mi_quad_nodes.size(); ++q) {
            Type x_q = mi_quad_nodes(q);
            Type log_density = dtweedie(
              x_q,
              mi_mean(i),
              phi_tweedie_mi,
              power_tweedie_mi,
              true
            );
            Type term = mi_quad_weights(q) * exp(log_density);
            prior_norm += term;
            prior_mean += x_q * term;
          }
          mi_x_full(i) = prior_mean / prior_norm;
          mu(i) += beta_mu(mi_col) * (mi_x_full(i) - X_mu(i, mi_col));
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(log_sigma_mi);
      REPORT(mi_mean);
      REPORT(sigma_tweedie_mi);
      REPORT(phi_tweedie_mi);
      REPORT(power_tweedie_mi);
      ADREPORT(beta_mi);
      ADREPORT(log_sigma_mi);
      ADREPORT(sigma_tweedie_mi);
    }

    // Guard the Gaussian scale against a runaway per-observation log-sigma.
    // See docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md.
    drm_softclamp_log_sigma(log_sigma, Type(-12.0), Type(12.0), Type(3.0));
    vector<Type> sigma = exp(log_sigma);
    vector<Type> obs_sigma = sqrt(V_known + sigma * sigma);

    if (V_known_type == 2) {
      int n = y.size();
      matrix<Type> Omega(n, n);
      for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
          Omega(i, j) = V_known_matrix(i, j);
        }
        Omega(i, i) += sigma(i) * sigma(i);
      }
      density::MVNORM_t<Type> neg_log_density(Omega);
      nll += neg_log_density(y - mu);
    } else {
      for (int i = 0; i < y.size(); ++i) {
        if (
          observed_y(i) == 1 &&
          !(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)
        ) {
          nll -= weights(i) * dnorm(y(i), mu(i), obs_sigma(i), true);
        }
      }
    }

    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(obs_sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      vector<Type> log_sd_mu_group(X_sd_mu.rows());
      vector<Type> sd_mu_group(X_sd_mu.rows());
      if (has_sd_mu_model == 1) {
        for (int g = 0; g < X_sd_mu.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_mu.cols(); ++k) {
            eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
          }
          log_sd_mu_group(g) = eta_sd;
          sd_mu_group(g) = exp(eta_sd);
        }
      }
      vector<Type> rho_mu_re(n_mu_re_cors);
      for (int j = 0; j < n_mu_re_cors; ++j) {
        rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
      if (has_sd_mu_model == 1) {
        REPORT(beta_sd_mu);
        REPORT(log_sd_mu_group);
        REPORT(sd_mu_group);
        ADREPORT(beta_sd_mu);
        ADREPORT(log_sd_mu_group);
        ADREPORT(sd_mu_group);
      }
      if (n_mu_re_cors > 0) {
        REPORT(eta_cor_mu);
        REPORT(rho_mu_re);
        ADREPORT(eta_cor_mu);
        ADREPORT(rho_mu_re);
      }
    }
    if (n_sigma_re_terms > 0) {
      vector<Type> sd_sigma_re = exp(log_sd_sigma);
      REPORT(u_sigma);
      REPORT(log_sd_sigma);
      REPORT(sd_sigma_re);
      ADREPORT(log_sd_sigma);
      ADREPORT(sd_sigma_re);
      if (n_mu_sigma_re_cors > 0) {
        vector<Type> rho_mu_sigma_re(n_mu_sigma_re_cors);
        for (int j = 0; j < n_mu_sigma_re_cors; ++j) {
          rho_mu_sigma_re(j) = Type(0.999999) * tanh(eta_cor_mu_sigma(j));
        }
        REPORT(eta_cor_mu_sigma);
        REPORT(rho_mu_sigma_re);
        ADREPORT(eta_cor_mu_sigma);
        ADREPORT(rho_mu_sigma_re);
      }
    }
    }
  } else if (model_type == 3) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_nu = X_nu * beta_nu;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> sigma = exp(log_sigma);
    vector<Type> nu = Type(2.0) + exp(eta_nu);
    for (int i = 0; i < y.size(); ++i) {
      Type z = (y(i) - mu(i)) / sigma(i);
      Type half = Type(0.5);
      Type log_density =
        lgamma(half * (nu(i) + Type(1.0))) -
        lgamma(half * nu(i)) -
        half * log(nu(i) * M_PI) -
        log_sigma(i) -
        half * (nu(i) + Type(1.0)) * log(Type(1.0) + z * z / nu(i));
      nll -= weights(i) * log_density;
    }
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(eta_nu);
    REPORT(nu);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_nu);
  } else if (model_type == 17) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_nu = X_nu * beta_nu;
    vector<Type> sigma = exp(log_sigma);
    vector<Type> nu = eta_nu;
    vector<Type> xi(y.size());
    vector<Type> omega(y.size());
    Type log_two = log(Type(2.0));
    Type sqrt_two_over_pi = sqrt(Type(2.0) / Type(M_PI));
    for (int i = 0; i < y.size(); ++i) {
      Type alpha = eta_nu(i);
      Type delta = alpha / sqrt(Type(1.0) + alpha * alpha);
      Type mean_shift = delta * sqrt_two_over_pi;
      Type variance_factor = Type(1.0) - mean_shift * mean_shift;
      omega(i) = sigma(i) / sqrt(variance_factor);
      xi(i) = mu(i) - omega(i) * mean_shift;
      Type z = (y(i) - xi(i)) / omega(i);
      Type skew_cdf = pnorm(alpha * z, Type(0.0), Type(1.0));
      Type log_density =
        log_two -
        log(omega(i)) +
        dnorm(z, Type(0.0), Type(1.0), true) +
        log(skew_cdf + Type(1e-300));
      nll -= weights(i) * log_density;
    }
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(eta_nu);
    REPORT(nu);
    REPORT(xi);
    REPORT(omega);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_nu);
  } else if (model_type == 4) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> sigma = exp(log_sigma);
    for (int i = 0; i < y.size(); ++i) {
      Type log_y = log(y(i));
      nll -= weights(i) * (dnorm(log_y, mu(i), sigma(i), true) - log_y);
    }
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 5) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          eta_mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    for (int i = 0; i < y.size(); ++i) {
      Type variance_multiplier = sigma(i) * sigma(i);
      Type shape = Type(1.0) / variance_multiplier;
      Type scale = mu(i) * variance_multiplier;
      Type log_density =
        (shape - Type(1.0)) * log(y(i)) -
        y(i) / scale -
        lgamma(shape) -
        shape * log(scale);
      nll -= weights(i) * log_density;
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 16) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_nu = X_nu * beta_nu;
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    vector<Type> phi(y.size());
    vector<Type> nu(y.size());
    for (int i = 0; i < y.size(); ++i) {
      phi(i) = sigma(i) * sigma(i);
      nu(i) = Type(1.0) + Type(1.0) / (Type(1.0) + exp(-eta_nu(i)));
      nll -= weights(i) * dtweedie(y(i), mu(i), phi(i), nu(i), true);
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(phi);
    REPORT(eta_nu);
    REPORT(nu);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_nu);
  } else if (model_type == 10) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          eta_mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> mu(y.size());
    Type beta_mu_eps = Type(1e-12);
    for (int i = 0; i < mu.size(); ++i) {
      Type mu_raw = exp(drm_log_inv_logit(eta_mu(i)));
      mu(i) = beta_mu_eps +
        (Type(1.0) - Type(2.0) * beta_mu_eps) * mu_raw;
    }
    vector<Type> sigma = exp(log_sigma);
    vector<Type> phi(y.size());
    vector<Type> alpha(y.size());
    vector<Type> beta_shape(y.size());
    Type beta_shape_floor = Type(1e-8);
    for (int i = 0; i < y.size(); ++i) {
      phi(i) = exp(Type(-2.0) * log_sigma(i));
      Type alpha_raw = mu(i) * phi(i);
      Type beta_raw = (Type(1.0) - mu(i)) * phi(i);
      alpha(i) = CppAD::CondExpLt(
        alpha_raw,
        beta_shape_floor,
        beta_shape_floor,
        alpha_raw
      );
      beta_shape(i) = CppAD::CondExpLt(
        beta_raw,
        beta_shape_floor,
        beta_shape_floor,
        beta_raw
      );
      Type log_density =
        lgamma(alpha(i) + beta_shape(i)) -
        lgamma(alpha(i)) -
        lgamma(beta_shape(i)) +
        (alpha(i) - Type(1.0)) * log(y(i)) +
        (beta_shape(i) - Type(1.0)) * log(Type(1.0) - y(i));
      nll -= weights(i) * log_density;
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(phi);
    REPORT(alpha);
    REPORT(beta_shape);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 15) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_zoi = X_zi * beta_zoi;
    vector<Type> eta_coi = X_nu * beta_coi;
    vector<Type> mu(y.size());
    Type beta_mu_eps = Type(1e-12);
    for (int i = 0; i < mu.size(); ++i) {
      Type mu_raw = exp(drm_log_inv_logit(eta_mu(i)));
      mu(i) = beta_mu_eps +
        (Type(1.0) - Type(2.0) * beta_mu_eps) * mu_raw;
    }
    vector<Type> sigma = exp(log_sigma);
    vector<Type> zoi = Type(1.0) / (Type(1.0) + exp(-eta_zoi));
    vector<Type> coi = Type(1.0) / (Type(1.0) + exp(-eta_coi));
    vector<Type> phi(y.size());
    vector<Type> alpha(y.size());
    vector<Type> beta_shape(y.size());
    Type beta_shape_floor = Type(1e-8);
    for (int i = 0; i < y.size(); ++i) {
      Type log_zoi = -logspace_add(Type(0.0), -eta_zoi(i));
      Type log_one_minus_zoi = -logspace_add(Type(0.0), eta_zoi(i));
      Type log_coi = -logspace_add(Type(0.0), -eta_coi(i));
      Type log_one_minus_coi = -logspace_add(Type(0.0), eta_coi(i));
      phi(i) = exp(Type(-2.0) * log_sigma(i));
      Type alpha_raw = mu(i) * phi(i);
      Type beta_raw = (Type(1.0) - mu(i)) * phi(i);
      alpha(i) = CppAD::CondExpLt(
        alpha_raw,
        beta_shape_floor,
        beta_shape_floor,
        alpha_raw
      );
      beta_shape(i) = CppAD::CondExpLt(
        beta_raw,
        beta_shape_floor,
        beta_shape_floor,
        beta_raw
      );
      if (asDouble(y(i)) <= 0.0) {
        nll -= weights(i) * (log_zoi + log_one_minus_coi);
        continue;
      }
      if (asDouble(y(i)) >= 1.0) {
        nll -= weights(i) * (log_zoi + log_coi);
        continue;
      }
      Type log_density =
        log_one_minus_zoi +
        lgamma(alpha(i) + beta_shape(i)) -
        lgamma(alpha(i)) -
        lgamma(beta_shape(i)) +
        (alpha(i) - Type(1.0)) * log(y(i)) +
        (beta_shape(i) - Type(1.0)) * log(Type(1.0) - y(i));
      nll -= weights(i) * log_density;
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(eta_zoi);
    REPORT(zoi);
    REPORT(eta_coi);
    REPORT(coi);
    REPORT(phi);
    REPORT(alpha);
    REPORT(beta_shape);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_zoi);
    ADREPORT(beta_coi);
  } else if (model_type == 14) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          eta_mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> mu = Type(1.0) / (Type(1.0) + exp(-eta_mu));
    vector<Type> sigma = exp(log_sigma);
    vector<Type> phi(y.size());
    vector<Type> alpha(y.size());
    vector<Type> beta_shape(y.size());
    for (int i = 0; i < y.size(); ++i) {
      Type failures = trials(i) - y(i);
      phi(i) = exp(Type(-2.0) * log_sigma(i));
      alpha(i) = mu(i) * phi(i);
      beta_shape(i) = (Type(1.0) - mu(i)) * phi(i);
      Type log_density =
        lgamma(trials(i) + Type(1.0)) -
        lgamma(y(i) + Type(1.0)) -
        lgamma(failures + Type(1.0)) +
        lgamma(phi(i)) -
        lgamma(trials(i) + phi(i)) +
        lgamma(y(i) + alpha(i)) -
        lgamma(alpha(i)) +
        lgamma(failures + beta_shape(i)) -
        lgamma(beta_shape(i));
      nll -= weights(i) * log_density;
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(phi);
    REPORT(alpha);
    REPORT(beta_shape);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 13) {
    vector<Type> mu = X_mu * beta_mu;
    vector<Type> cutpoints(theta_ord.size());
    if (theta_ord.size() > 0) {
      cutpoints(0) = theta_ord(0);
      for (int j = 1; j < theta_ord.size(); ++j) {
        cutpoints(j) = cutpoints(j - 1) + exp(theta_ord(j));
      }
    }
    int n_categories = theta_ord.size() + 1;
    for (int i = 0; i < y.size(); ++i) {
      int yi = (int) asDouble(y(i));
      Type log_prob;
      if (yi == 1) {
        log_prob = drm_log_inv_logit(cutpoints(0) - mu(i));
      } else if (yi == n_categories) {
        log_prob = drm_log1m_inv_logit(cutpoints(n_categories - 2) - mu(i));
      } else {
        Type upper = cutpoints(yi - 1) - mu(i);
        Type lower = cutpoints(yi - 2) - mu(i);
        log_prob = drm_log_inv_logit_diff(upper, lower);
      }
      nll -= weights(i) * log_prob;
    }
    REPORT(mu);
    REPORT(cutpoints);
    ADREPORT(beta_mu);
    ADREPORT(cutpoints);
  } else if (model_type == 6) {
    vector<Type> eta_mu = offset_mu + X_mu * beta_mu;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      vector<Type> sd_mu_group(X_sd_mu.rows());
      if (has_sd_mu_model == 1) {
        for (int g = 0; g < X_sd_mu.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_mu.cols(); ++k) {
            eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
          }
          sd_mu_group(g) = exp(eta_sd);
        }
      }
      vector<Type> rho_mu_re(n_mu_re_cors);
      for (int j = 0; j < n_mu_re_cors; ++j) {
        rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
      }
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          int cor_id = mu_re_cor_id(idx);
          int sd_row = mu_re_sd_row(idx);
          Type sd_current = sd_mu_re(mu_re_term(idx));
          if (sd_row >= 0) {
            sd_current = sd_mu_group(sd_row);
          }
          Type u_cond = u_mu(idx);
          if (cor_id >= 0 && mu_re_pos(idx) == 1) {
            Type rho = rho_mu_re(cor_id);
            int pair_idx = mu_re_pair_index(idx);
            u_cond = rho * u_mu(pair_idx) +
              sqrt(Type(1.0) - rho * rho) * u_mu(idx);
          }
          eta_mu(i) += mu_re_value(i, j) * sd_current * u_cond;
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      if (n_mu_re_cors > 0) {
        REPORT(eta_cor_mu);
        REPORT(rho_mu_re);
      }
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
      if (n_mu_re_cors > 0) {
        ADREPORT(eta_cor_mu);
        ADREPORT(rho_mu_re);
      }
    }
    if (has_phylo_mu == 1) {
      int n_phylo = Q_phylo.rows();
      int q_phylo = log_sd_phylo.size();
      for (int i = 0; i < y.size(); ++i) {
        Type phylo_effect = Type(0.0);
        for (int k = 0; k < q_phylo; ++k) {
          int effect_index = k * n_phylo + phylo_mu_node_index(i);
          phylo_effect += phylo_mu_value(i, k) * u_phylo(effect_index);
        }
        eta_mu(i) += phylo_effect;
      }
      Type quadratic = Type(0.0);
      for (int k = 0; k < q_phylo; ++k) {
        vector<Type> effect_k(n_phylo);
        for (int j = 0; j < n_phylo; ++j) {
          effect_k(j) = u_phylo(k * n_phylo + j);
        }
        vector<Type> Q_u = Q_phylo * effect_k;
        Type quadratic_k = Type(0.0);
        for (int j = 0; j < n_phylo; ++j) {
          quadratic_k += effect_k(j) * Q_u(j);
        }
        quadratic += quadratic_k;
        nll += Type(0.5) * (
          Type(n_phylo) * log(Type(2.0) * M_PI) +
          Type(2.0) * Type(n_phylo) * log_sd_phylo(k) -
          log_det_Q_phylo +
          exp(Type(-2.0) * log_sd_phylo(k)) * quadratic_k
        );
      }
      REPORT(u_phylo);
      REPORT(log_sd_phylo);
      REPORT(quadratic);
      ADREPORT(log_sd_phylo);
      vector<Type> sd_phylo = exp(log_sd_phylo);
      REPORT(sd_phylo);
      ADREPORT(sd_phylo);
    }
    if (has_mi == 1 && mi_family == 1) {
      vector<Type> mi_eta = X_mi * beta_mi;
      vector<Type> mi_probability(mi_eta.size());
      vector<Type> mi_x_full(mi_x.size());
      for (int i = 0; i < mi_eta.size(); ++i) {
        Type log_p1 = -logspace_add(Type(0.0), -mi_eta(i));
        mi_probability(i) = exp(log_p1);
        mi_x_full(i) = mi_x(i);
      }
      for (int i = 0; i < mi_x.size(); ++i) {
        Type log_p1 = -logspace_add(Type(0.0), -mi_eta(i));
        Type log_p0 = -logspace_add(Type(0.0), mi_eta(i));
        if (mi_observed(i) == 1) {
          nll -= mi_x(i) * log_p1 + (Type(1.0) - mi_x(i)) * log_p0;
          eta_mu(i) += beta_mu(mi_col) * (mi_x(i) - X_mu(i, mi_col));
        } else {
          Type eta1 = eta_mu(i) +
            beta_mu(mi_col) * (Type(1.0) - X_mu(i, mi_col));
          Type eta0 = eta_mu(i) +
            beta_mu(mi_col) * (Type(0.0) - X_mu(i, mi_col));
          Type log_y1 = observed_y(i) == 1 ?
            weights(i) * dpois(y(i), exp(eta1), true) : Type(0.0);
          Type log_y0 = observed_y(i) == 1 ?
            weights(i) * dpois(y(i), exp(eta0), true) : Type(0.0);
          Type log_denom = logspace_add(log_p1 + log_y1, log_p0 + log_y0);
          nll -= log_denom;
          Type posterior_p1 = exp(log_p1 + log_y1 - log_denom);
          mi_probability(i) = posterior_p1;
          mi_x_full(i) = posterior_p1;
          Type expected_mu =
            posterior_p1 * exp(eta1) +
            (Type(1.0) - posterior_p1) * exp(eta0);
          eta_mu(i) = log(expected_mu);
        }
      }
      REPORT(mi_x_full);
      REPORT(beta_mi);
      REPORT(mi_probability);
      ADREPORT(beta_mi);
    }
    vector<Type> mu = exp(eta_mu);
    for (int i = 0; i < y.size(); ++i) {
      if (!(has_mi == 1 && mi_family != 0 && mi_observed(i) == 0)) {
        nll -= weights(i) * dpois(y(i), mu(i), true);
      }
    }
    REPORT(eta_mu);
    REPORT(mu);
    ADREPORT(beta_mu);
  } else if (model_type == 8) {
    vector<Type> eta_mu = offset_mu + X_mu * beta_mu;
    vector<Type> eta_zi = X_zi * beta_zi;
    vector<Type> mu = exp(eta_mu);
    vector<Type> zi = Type(1.0) / (Type(1.0) + exp(-eta_zi));
    for (int i = 0; i < y.size(); ++i) {
      Type log_zi = -logspace_add(Type(0.0), -eta_zi(i));
      Type log_one_minus_zi = -logspace_add(Type(0.0), eta_zi(i));
      if (asDouble(y(i)) == 0.0) {
        nll -= weights(i) * logspace_add(log_zi, log_one_minus_zi - mu(i));
      } else {
        nll -= weights(i) * (log_one_minus_zi + dpois(y(i), mu(i), true));
      }
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(eta_zi);
    REPORT(zi);
    ADREPORT(beta_mu);
    ADREPORT(beta_zi);
  } else if (model_type == 7) {
    vector<Type> eta_mu = offset_mu + X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      vector<Type> sd_mu_group(X_sd_mu.rows());
      if (has_sd_mu_model == 1) {
        for (int g = 0; g < X_sd_mu.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_mu.cols(); ++k) {
            eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
          }
          sd_mu_group(g) = exp(eta_sd);
        }
      }
      vector<Type> rho_mu_re(n_mu_re_cors);
      for (int j = 0; j < n_mu_re_cors; ++j) {
        rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
      }
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          int cor_id = mu_re_cor_id(idx);
          int sd_row = mu_re_sd_row(idx);
          Type sd_current = sd_mu_re(mu_re_term(idx));
          if (sd_row >= 0) {
            sd_current = sd_mu_group(sd_row);
          }
          Type u_cond = u_mu(idx);
          if (cor_id >= 0 && mu_re_pos(idx) == 1) {
            Type rho = rho_mu_re(cor_id);
            int pair_idx = mu_re_pair_index(idx);
            u_cond = rho * u_mu(pair_idx) +
              sqrt(Type(1.0) - rho * rho) * u_mu(idx);
          }
          eta_mu(i) += mu_re_value(i, j) * sd_current * u_cond;
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      if (n_mu_re_cors > 0) {
        REPORT(eta_cor_mu);
        REPORT(rho_mu_re);
      }
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
      if (n_mu_re_cors > 0) {
        ADREPORT(eta_cor_mu);
        ADREPORT(rho_mu_re);
      }
    }
    if (has_phylo_mu == 1) {
      int n_phylo = Q_phylo.rows();
      int q_phylo = log_sd_phylo.size();
      for (int i = 0; i < y.size(); ++i) {
        Type phylo_effect = Type(0.0);
        for (int k = 0; k < q_phylo; ++k) {
          int effect_index = k * n_phylo + phylo_mu_node_index(i);
          phylo_effect += phylo_mu_value(i, k) * u_phylo(effect_index);
        }
        eta_mu(i) += phylo_effect;
      }
      Type quadratic = Type(0.0);
      for (int k = 0; k < q_phylo; ++k) {
        vector<Type> effect_k(n_phylo);
        for (int j = 0; j < n_phylo; ++j) {
          effect_k(j) = u_phylo(k * n_phylo + j);
        }
        vector<Type> Q_u = Q_phylo * effect_k;
        Type quadratic_k = Type(0.0);
        for (int j = 0; j < n_phylo; ++j) {
          quadratic_k += effect_k(j) * Q_u(j);
        }
        quadratic += quadratic_k;
        nll += Type(0.5) * (
          Type(n_phylo) * log(Type(2.0) * M_PI) +
          Type(2.0) * Type(n_phylo) * log_sd_phylo(k) -
          log_det_Q_phylo +
          exp(Type(-2.0) * log_sd_phylo(k)) * quadratic_k
        );
      }
      REPORT(u_phylo);
      REPORT(log_sd_phylo);
      REPORT(quadratic);
      ADREPORT(log_sd_phylo);
      vector<Type> sd_phylo = exp(log_sd_phylo);
      REPORT(sd_phylo);
      ADREPORT(sd_phylo);
    }
    if (n_sigma_re_terms > 0) {
      vector<Type> sd_sigma_re = exp(log_sd_sigma);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_sigma_re_terms; ++j) {
          int idx = sigma_re_index(i, j);
          log_sigma(i) +=
            sigma_re_value(i, j) * sd_sigma_re(sigma_re_term(idx)) *
            u_sigma(idx);
        }
      }
      for (int j = 0; j < u_sigma.size(); ++j) {
        nll -= dnorm(u_sigma(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_sigma);
      REPORT(log_sd_sigma);
      REPORT(sd_sigma_re);
      ADREPORT(log_sd_sigma);
      ADREPORT(sd_sigma_re);
    }
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    for (int i = 0; i < y.size(); ++i) {
      Type log_density = drm_nbinom2_log_density(y(i), eta_mu(i), log_sigma(i));
      nll -= weights(i) * log_density;
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 11) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      for (int i = 0; i < y.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          eta_mu(i) +=
            mu_re_value(i, j) * sd_mu_re(mu_re_term(idx)) * u_mu(idx);
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
    }
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    vector<Type> trunc_prob(y.size());
    vector<Type> positive_mean(y.size());
    for (int i = 0; i < y.size(); ++i) {
      Type log_density = drm_nbinom2_log_density(y(i), eta_mu(i), log_sigma(i));
      Type log_p0 = drm_nbinom2_log_p0(eta_mu(i), log_sigma(i));
      Type log_trunc_prob = drm_log1mexp(log_p0);
      trunc_prob(i) = exp(log_trunc_prob);
      positive_mean(i) = mu(i) / trunc_prob(i);
      nll -= weights(i) * (log_density - log_trunc_prob);
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(trunc_prob);
    REPORT(positive_mean);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
  } else if (model_type == 12) {
    vector<Type> eta_mu = X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_hu = X_zi * beta_zi;
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    vector<Type> hu = Type(1.0) / (Type(1.0) + exp(-eta_hu));
    vector<Type> trunc_prob(y.size());
    vector<Type> positive_mean(y.size());
    vector<Type> fitted_mean(y.size());
    for (int i = 0; i < y.size(); ++i) {
      Type log_hu = -logspace_add(Type(0.0), -eta_hu(i));
      Type log_one_minus_hu = -logspace_add(Type(0.0), eta_hu(i));
      Type log_density = drm_nbinom2_log_density(y(i), eta_mu(i), log_sigma(i));
      int yi = (int) asDouble(y(i));
      Type log_p0 = drm_nbinom2_log_p0(eta_mu(i), log_sigma(i));
      Type log_trunc_prob = drm_log1mexp(log_p0);
      trunc_prob(i) = exp(log_trunc_prob);
      positive_mean(i) = mu(i) / trunc_prob(i);
      fitted_mean(i) = (Type(1.0) - hu(i)) * positive_mean(i);
      if (yi == 0) {
        nll -= weights(i) * log_hu;
      } else {
        nll -= weights(i) * (log_one_minus_hu + log_density - log_trunc_prob);
      }
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(eta_hu);
    REPORT(hu);
    REPORT(trunc_prob);
    REPORT(positive_mean);
    REPORT(fitted_mean);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_zi);
  } else if (model_type == 9) {
    vector<Type> eta_mu = offset_mu + X_mu * beta_mu;
    vector<Type> log_sigma = X_sigma * beta_sigma;
    vector<Type> eta_zi = X_zi * beta_zi;
    vector<Type> mu = exp(eta_mu);
    vector<Type> sigma = exp(log_sigma);
    vector<Type> zi = Type(1.0) / (Type(1.0) + exp(-eta_zi));
    for (int i = 0; i < y.size(); ++i) {
      Type log_density = drm_nbinom2_log_density(y(i), eta_mu(i), log_sigma(i));
      int yi = (int) asDouble(y(i));
      Type log_zi = -logspace_add(Type(0.0), -eta_zi(i));
      Type log_one_minus_zi = -logspace_add(Type(0.0), eta_zi(i));
      if (yi == 0) {
        nll -= weights(i) * logspace_add(log_zi, log_one_minus_zi + log_density);
      } else {
        nll -= weights(i) * (log_one_minus_zi + log_density);
      }
    }
    REPORT(eta_mu);
    REPORT(mu);
    REPORT(log_sigma);
    REPORT(sigma);
    REPORT(eta_zi);
    REPORT(zi);
    ADREPORT(beta_mu);
    ADREPORT(beta_sigma);
    ADREPORT(beta_zi);
  } else if (model_type == 2) {
    vector<Type> mu1 = X_mu1 * beta_mu1;
    vector<Type> mu2 = X_mu2 * beta_mu2;
    vector<Type> log_sigma1 = X_sigma1 * beta_sigma1;
    vector<Type> log_sigma2 = X_sigma2 * beta_sigma2;
    vector<Type> eta_rho12 = X_rho12 * beta_rho12;
    vector<Type> rho12 = Type(0.99999999) * tanh(eta_rho12);

    if (n_re_cov_blocks > 0) {
      int n_re_cov_qgt2_blocks = 0;
      for (int b = 0; b < n_re_cov_blocks; ++b) {
        if (re_cov_block_size(b) > 2) {
          n_re_cov_qgt2_blocks += 1;
        }
      }
      if (n_re_cov_qgt2_blocks > 0) {
        int theta_offset = 0;
        int sd_offset = 0;
        int u_offset = 0;
        int rho_offset = 0;
        vector<Type> sd_re_cov(log_sd_re_cov.size());
        for (int j = 0; j < log_sd_re_cov.size(); ++j) {
          sd_re_cov(j) = exp(log_sd_re_cov(j));
        }
        vector<Type> rho_re_cov(theta_re_cov.size());
        matrix<Type> re_cov_contribution(
          re_cov_member_design_value.rows(),
          re_cov_member_design_value.cols()
        );
        re_cov_contribution.setZero();

        for (int b = 0; b < n_re_cov_blocks; ++b) {
          int block_size = re_cov_block_size(b);
          int n_groups = re_cov_block_group_count(b);
          int member_start = re_cov_block_member_start(b);
          int pair_start = re_cov_block_pair_start(b);
          int n_pairs = block_size * (block_size - 1) / 2;
          if (block_size <= 2) {
            continue;
          }

          vector<Type> theta_block(n_pairs);
          for (int p = 0; p < n_pairs; ++p) {
            theta_block(p) = theta_re_cov(theta_offset + p);
          }
          density::UNSTRUCTURED_CORR_t<Type> re_cov_density(theta_block);
          matrix<Type> re_cov_corr = re_cov_density.cov();
          vector<Type> sd_block(block_size);
          for (int m = 0; m < block_size; ++m) {
            sd_block(m) = sd_re_cov(sd_offset + m);
          }
          for (int p = 0; p < n_pairs; ++p) {
            int from = re_cov_pair_from_member(pair_start + p);
            int to = re_cov_pair_to_member(pair_start + p);
            rho_re_cov(rho_offset + p) = re_cov_corr(from, to);
          }

          for (int g = 0; g < n_groups; ++g) {
            vector<Type> z(block_size);
            for (int m = 0; m < block_size; ++m) {
              z(m) = u_re_cov(u_offset + g * block_size + m);
            }
            vector<Type> latent = density::VECSCALE(
              re_cov_density,
              sd_block
            ).sqrt_cov_scale(z);
            for (int m = 0; m < block_size; ++m) {
              int member_col = member_start + m;
              for (int i = 0; i < y1.size(); ++i) {
                if (re_cov_member_latent_index(i, member_col) == g) {
                  Type contribution =
                    re_cov_member_design_value(i, member_col) * latent(m);
                  re_cov_contribution(i, member_col) = contribution;
                  int dpar_code = re_cov_member_dpar(member_col);
                  if (dpar_code == 2) {
                    mu1(i) += contribution;
                  } else if (dpar_code == 3) {
                    mu2(i) += contribution;
                  } else if (dpar_code == 4) {
                    log_sigma1(i) += contribution;
                  } else if (dpar_code == 5) {
                    log_sigma2(i) += contribution;
                  }
                }
              }
            }
          }

          theta_offset += n_pairs;
          sd_offset += block_size;
          u_offset += n_groups * block_size;
          rho_offset += n_pairs;
        }
        for (int j = 0; j < u_re_cov.size(); ++j) {
          nll -= dnorm(u_re_cov(j), Type(0.0), Type(1.0), true);
        }
        if (theta_re_cov.size() > 0) {
          REPORT(u_re_cov);
          REPORT(log_sd_re_cov);
          REPORT(sd_re_cov);
          REPORT(theta_re_cov);
          REPORT(rho_re_cov);
          REPORT(re_cov_contribution);
          ADREPORT(log_sd_re_cov);
          ADREPORT(sd_re_cov);
          ADREPORT(theta_re_cov);
          ADREPORT(rho_re_cov);
        }
      }
    }

    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      vector<Type> sd_mu_group(X_sd_mu.rows());
      if (has_sd_mu_model == 1) {
        for (int g = 0; g < X_sd_mu.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_mu.cols(); ++k) {
            eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
          }
          sd_mu_group(g) = exp(eta_sd);
        }
      }
      vector<Type> rho_mu_re(n_mu_re_cors);
      for (int j = 0; j < n_mu_re_cors; ++j) {
        rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
      }
      vector<Type> rho_mu_group(X_cor_mu.rows());
      if (has_cor_mu_model == 1) {
        for (int g = 0; g < X_cor_mu.rows(); ++g) {
          Type eta_cor = Type(0.0);
          for (int k = 0; k < X_cor_mu.cols(); ++k) {
            eta_cor += X_cor_mu(g, k) * beta_cor_mu(k);
          }
          rho_mu_group(g) = Type(0.999999) * tanh(eta_cor);
        }
      }
      for (int i = 0; i < y1.size(); ++i) {
        for (int j = 0; j < n_mu_re_terms; ++j) {
          int idx = mu_re_index(i, j);
          int cor_id = mu_re_cor_id(idx);
          int sd_row = mu_re_sd_row(idx);
          Type sd_current = sd_mu_re(mu_re_term(idx));
          if (sd_row >= 0) {
            sd_current = sd_mu_group(sd_row);
          }
          Type u_cond = u_mu(idx);
          if (cor_id >= 0 && mu_re_pos(idx) == 1) {
            int pair_idx = mu_re_pair_index(idx);
            Type rho = rho_mu_re(cor_id);
            if (has_cor_mu_model == 1 && pair_idx >= 0) {
              rho = rho_mu_group(pair_idx);
            }
            u_cond = rho * u_mu(pair_idx) + sqrt(Type(1.0) - rho * rho) * u_mu(idx);
          }
          int dpar_id = mu_re_dpar(idx);
          if (dpar_id == 0) {
            mu1(i) += mu_re_value(i, j) * sd_current * u_cond;
          } else if (dpar_id == 1) {
            mu2(i) += mu_re_value(i, j) * sd_current * u_cond;
          }
        }
      }
      for (int j = 0; j < u_mu.size(); ++j) {
        nll -= dnorm(u_mu(j), Type(0.0), Type(1.0), true);
      }
    }

    if (n_sigma_re_terms > 0) {
      vector<Type> sd_sigma_re = exp(log_sd_sigma);
      vector<Type> rho_sigma_re(n_sigma_re_cors);
      for (int j = 0; j < n_sigma_re_cors; ++j) {
        rho_sigma_re(j) = Type(0.999999) * tanh(eta_cor_sigma(j));
      }
      vector<Type> rho_mu_sigma_re(n_mu_sigma_re_cors);
      for (int j = 0; j < n_mu_sigma_re_cors; ++j) {
        rho_mu_sigma_re(j) = Type(0.999999) * tanh(eta_cor_mu_sigma(j));
      }
      for (int i = 0; i < y1.size(); ++i) {
        for (int j = 0; j < n_sigma_re_terms; ++j) {
          int idx = sigma_re_index(i, j);
          Type u_cond = u_sigma(idx);
          int cor_id = sigma_re_cor_id(idx);
          if (cor_id >= 0) {
            Type rho = rho_sigma_re(cor_id);
            int pair_idx = sigma_re_pair_index(idx);
            u_cond = rho * u_sigma(pair_idx) + sqrt(Type(1.0) - rho * rho) * u_sigma(idx);
          }
          int cross_cor_id = sigma_re_cross_cor(idx);
          if (cross_cor_id >= 0) {
            Type rho = rho_mu_sigma_re(cross_cor_id);
            int mu_idx = sigma_re_cross_mu(idx);
            u_cond = rho * u_mu(mu_idx) + sqrt(Type(1.0) - rho * rho) * u_cond;
          }
          int dpar_id = sigma_re_dpar(idx);
          if (dpar_id == 0) {
            log_sigma1(i) += sigma_re_value(i, j) * sd_sigma_re(sigma_re_term(idx)) * u_cond;
          } else if (dpar_id == 1) {
            log_sigma2(i) += sigma_re_value(i, j) * sd_sigma_re(sigma_re_term(idx)) * u_cond;
          }
        }
      }
      for (int j = 0; j < u_sigma.size(); ++j) {
        nll -= dnorm(u_sigma(j), Type(0.0), Type(1.0), true);
      }
    }

    if (has_phylo_mu == 1) {
      int n_phylo = Q_phylo.rows();
      int q_phylo = log_sd_phylo.size();
      bool has_phylo_cor_model = has_cor_mu_model == 2;
      vector<Type> sd_phylo = exp(log_sd_phylo);
      vector<Type> sd_phylo_group(X_sd_phylo.rows());
      vector<Type> log_sd_phylo_group(X_sd_phylo.rows());
      if (has_sd_phylo_model == 1) {
        for (int g = 0; g < X_sd_phylo.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_phylo.cols(); ++k) {
            eta_sd += X_sd_phylo(g, k) *
              beta_sd_mu(sd_phylo_beta_offset + k);
          }
          log_sd_phylo_group(g) = eta_sd;
          sd_phylo_group(g) = exp(eta_sd);
        }
      }
      for (int i = 0; i < y1.size(); ++i) {
        int node = phylo_mu_node_index(i);
        Type phylo_effect1 = u_phylo(node);
        Type phylo_effect2 = u_phylo(n_phylo + node);
        if (has_phylo_cor_model && q_phylo == 2) {
          Type eta_cor = Type(0.0);
          for (int k = 0; k < X_cor_mu.cols(); ++k) {
            eta_cor += X_cor_mu(node, k) * beta_cor_mu(k);
          }
          Type rho_node = Type(0.999999) * tanh(eta_cor);
          Type c_node = sqrt((Type(1.0) + rho_node) / Type(2.0));
          Type d_node = sqrt((Type(1.0) - rho_node) / Type(2.0));
          Type z1 = u_phylo(node);
          Type z2 = u_phylo(n_phylo + node);
          phylo_effect1 = sd_phylo(0) * (c_node * z1 + d_node * z2);
          phylo_effect2 = sd_phylo(1) * (c_node * z1 - d_node * z2);
        } else if (has_sd_phylo_model == 1 && q_phylo == 2) {
          int row1 = phylo_mu_sd_row(node);
          int row2 = phylo_mu_sd_row(n_phylo + node);
          if (row1 >= 0) {
            phylo_effect1 *= sd_phylo_group(row1);
          } else {
            phylo_effect1 *= sd_phylo(0);
          }
          if (row2 >= 0) {
            phylo_effect2 *= sd_phylo_group(row2);
          } else {
            phylo_effect2 *= sd_phylo(1);
          }
        }
        mu1(i) += phylo_effect1;
        mu2(i) += phylo_effect2;
        if (q_phylo > 2) {
          log_sigma1(i) += u_phylo(2 * n_phylo + node);
          log_sigma2(i) += u_phylo(3 * n_phylo + node);
        }
      }
      if (q_phylo == 2) {
        Type rho_phylo = Type(0.999999) * tanh(eta_cor_phylo);
        vector<Type> u1(n_phylo);
        vector<Type> u2(n_phylo);
        for (int j = 0; j < n_phylo; ++j) {
          u1(j) = u_phylo(j);
          u2(j) = u_phylo(n_phylo + j);
        }
        vector<Type> Q_u1 = Q_phylo * u1;
        vector<Type> Q_u2 = Q_phylo * u2;
        Type q11 = Type(0.0);
        Type q12 = Type(0.0);
        Type q22 = Type(0.0);
        for (int j = 0; j < n_phylo; ++j) {
          q11 += u1(j) * Q_u1(j);
          q12 += u1(j) * Q_u2(j);
          q22 += u2(j) * Q_u2(j);
        }
        if (has_phylo_cor_model) {
          vector<Type> eta_phylo_group(X_cor_mu.rows());
          vector<Type> rho_phylo_group(X_cor_mu.rows());
          for (int g = 0; g < X_cor_mu.rows(); ++g) {
            eta_phylo_group(g) = Type(0.0);
            for (int k = 0; k < X_cor_mu.cols(); ++k) {
              eta_phylo_group(g) += X_cor_mu(g, k) * beta_cor_mu(k);
            }
            rho_phylo_group(g) = Type(0.999999) * tanh(eta_phylo_group(g));
          }
          Type quadratic_phylo = q11 + q22;
          nll += Type(0.5) * (
            Type(2 * n_phylo) * log(Type(2.0) * M_PI) -
            Type(2.0) * log_det_Q_phylo +
            quadratic_phylo
          );
          REPORT(eta_phylo_group);
          REPORT(rho_phylo_group);
          REPORT(quadratic_phylo);
          ADREPORT(rho_phylo_group);
        } else {
          Type one_minus_rho2 = Type(1.0) - rho_phylo * rho_phylo;
          Type inv11;
          Type inv22;
          Type inv12;
          Type log_det_cov;
          if (has_sd_phylo_model == 1) {
            inv11 = Type(1.0) / one_minus_rho2;
            inv22 = Type(1.0) / one_minus_rho2;
            inv12 = -rho_phylo / one_minus_rho2;
            log_det_cov = log(one_minus_rho2);
          } else {
            Type sd1 = sd_phylo(0);
            Type sd2 = sd_phylo(1);
            inv11 = Type(1.0) / (sd1 * sd1 * one_minus_rho2);
            inv22 = Type(1.0) / (sd2 * sd2 * one_minus_rho2);
            inv12 = -rho_phylo / (sd1 * sd2 * one_minus_rho2);
            log_det_cov = Type(2.0) * log_sd_phylo(0) +
              Type(2.0) * log_sd_phylo(1) +
              log(one_minus_rho2);
          }
          Type quadratic_phylo = inv11 * q11 + Type(2.0) * inv12 * q12 + inv22 * q22;
          nll += Type(0.5) * (
            Type(2 * n_phylo) * log(Type(2.0) * M_PI) +
            Type(n_phylo) * log_det_cov -
            Type(2.0) * log_det_Q_phylo +
            quadratic_phylo
          );
          REPORT(eta_cor_phylo);
          REPORT(rho_phylo);
          REPORT(quadratic_phylo);
          ADREPORT(eta_cor_phylo);
          ADREPORT(rho_phylo);
        }
      } else {
        matrix<Type> effect(n_phylo, q_phylo);
        for (int j = 0; j < q_phylo; ++j) {
          for (int i = 0; i < n_phylo; ++i) {
            effect(i, j) = u_phylo(j * n_phylo + i);
          }
        }
        matrix<Type> quadratic_matrix(q_phylo, q_phylo);
        quadratic_matrix.setZero();
        for (int b = 0; b < q_phylo; ++b) {
          vector<Type> effect_b(n_phylo);
          for (int i = 0; i < n_phylo; ++i) {
            effect_b(i) = effect(i, b);
          }
          vector<Type> Q_effect_b = Q_phylo * effect_b;
          for (int a = 0; a < q_phylo; ++a) {
            for (int i = 0; i < n_phylo; ++i) {
              quadratic_matrix(a, b) += effect(i, a) * Q_effect_b(i);
            }
          }
        }
        if (phylo_mu_n_blocks > 1) {
          matrix<Type> phylo_q4_corr(q_phylo, q_phylo);
          matrix<Type> phylo_q4_covariance(q_phylo, q_phylo);
          phylo_q4_corr.setZero();
          phylo_q4_covariance.setZero();
          for (int a = 0; a < q_phylo; ++a) {
            phylo_q4_corr(a, a) = Type(1.0);
            phylo_q4_covariance(a, a) = sd_phylo(a) * sd_phylo(a);
          }
          Type quadratic_phylo = Type(0.0);
          Type log_det_covariance = Type(0.0);
          int theta_pos = 0;
          for (int block = 0; block < phylo_mu_n_blocks; ++block) {
            int first = -1;
            int second = -1;
            int block_size = 0;
            for (int endpoint = 0; endpoint < q_phylo; ++endpoint) {
              if (phylo_mu_block_id(endpoint) == block) {
                if (block_size == 0) {
                  first = endpoint;
                } else if (block_size == 1) {
                  second = endpoint;
                }
                block_size += 1;
              }
            }
            if (block_size == 1) {
              Type sd1 = sd_phylo(first);
              Type block_quadratic =
                quadratic_matrix(first, first) / (sd1 * sd1);
              log_det_covariance += Type(2.0) * log_sd_phylo(first);
              quadratic_phylo += block_quadratic;
              nll += Type(0.5) * (
                Type(n_phylo) * log(Type(2.0) * M_PI) +
                Type(n_phylo) * Type(2.0) * log_sd_phylo(first) -
                log_det_Q_phylo +
                block_quadratic
              );
            } else if (block_size == 2) {
              Type rho_block = Type(0.999999) * tanh(theta_phylo(theta_pos));
              theta_pos += 1;
              Type one_minus_rho2 =
                Type(1.0) - rho_block * rho_block;
              Type sd1 = sd_phylo(first);
              Type sd2 = sd_phylo(second);
              Type log_det_block =
                Type(2.0) * log_sd_phylo(first) +
                Type(2.0) * log_sd_phylo(second) +
                log(one_minus_rho2);
              Type inv11 = Type(1.0) / (sd1 * sd1 * one_minus_rho2);
              Type inv22 = Type(1.0) / (sd2 * sd2 * one_minus_rho2);
              Type inv12 = -rho_block / (sd1 * sd2 * one_minus_rho2);
              Type block_quadratic =
                inv11 * quadratic_matrix(first, first) +
                Type(2.0) * inv12 * quadratic_matrix(first, second) +
                inv22 * quadratic_matrix(second, second);
              phylo_q4_corr(first, second) = rho_block;
              phylo_q4_corr(second, first) = rho_block;
              phylo_q4_covariance(first, second) = sd1 * rho_block * sd2;
              phylo_q4_covariance(second, first) = sd1 * rho_block * sd2;
              log_det_covariance += log_det_block;
              quadratic_phylo += block_quadratic;
              nll += Type(0.5) * (
                Type(2 * n_phylo) * log(Type(2.0) * M_PI) +
                Type(n_phylo) * log_det_block -
                Type(2.0) * log_det_Q_phylo +
                block_quadratic
              );
            }
          }
          REPORT(theta_phylo);
          REPORT(phylo_q4_corr);
          REPORT(phylo_q4_covariance);
          REPORT(quadratic_phylo);
          REPORT(log_det_covariance);
          REPORT(quadratic_matrix);
          ADREPORT(theta_phylo);
        } else {
          density::UNSTRUCTURED_CORR_t<Type> phylo_q4_density(theta_phylo);
          matrix<Type> phylo_q4_corr = phylo_q4_density.cov();
          matrix<Type> phylo_q4_covariance(q_phylo, q_phylo);
          for (int a = 0; a < q_phylo; ++a) {
            for (int b = 0; b < q_phylo; ++b) {
              phylo_q4_covariance(a, b) =
                sd_phylo(a) * phylo_q4_corr(a, b) * sd_phylo(b);
            }
          }
          matrix<Type> covariance_inverse = phylo_q4_covariance.inverse();
          Type log_det_covariance = log(phylo_q4_covariance.determinant());
          Type quadratic_phylo = Type(0.0);
          for (int a = 0; a < q_phylo; ++a) {
            for (int b = 0; b < q_phylo; ++b) {
              quadratic_phylo += covariance_inverse(a, b) * quadratic_matrix(a, b);
            }
          }
          nll += Type(0.5) * (
            Type(n_phylo * q_phylo) * log(Type(2.0) * M_PI) +
            Type(n_phylo) * log_det_covariance -
            Type(q_phylo) * log_det_Q_phylo +
            quadratic_phylo
          );
          REPORT(theta_phylo);
          REPORT(phylo_q4_corr);
          REPORT(phylo_q4_covariance);
          REPORT(quadratic_phylo);
          ADREPORT(theta_phylo);
        }
      }
      REPORT(u_phylo);
      REPORT(log_sd_phylo);
      REPORT(sd_phylo);
      if (has_sd_phylo_model == 1) {
        REPORT(log_sd_phylo_group);
        REPORT(sd_phylo_group);
        ADREPORT(log_sd_phylo_group);
        ADREPORT(sd_phylo_group);
      }
      ADREPORT(log_sd_phylo);
      ADREPORT(sd_phylo);
      if (penalize_phylo == 1) {
        phylo_penalty = drm_phylo_penalty_value(
          log_sd_phylo, q_phylo, eta_cor_phylo, theta_phylo,
          phylo_sd_penalty_rate, phylo_cor_penalty_sd);
        nll += phylo_penalty;
        REPORT(phylo_penalty);
      }
    }

    // Guard the bivariate Gaussian scales against runaway per-observation
    // log-sigma (e.g. a scale-side phylogenetic field; Ayumi's q4 "Model E").
    // See docs/design/170-sigma-phylo-conditioning-and-logsigma-clamp.md.
    drm_softclamp_log_sigma(log_sigma1, Type(-12.0), Type(12.0), Type(3.0));
    drm_softclamp_log_sigma(log_sigma2, Type(-12.0), Type(12.0), Type(3.0));
    vector<Type> sigma1 = exp(log_sigma1);
    vector<Type> sigma2 = exp(log_sigma2);

    if (V_known_type == 2) {
      int n = y1.size();
      int m = 2 * n;
      vector<Type> y_stack(m);
      vector<Type> mu_stack(m);
      matrix<Type> Omega(m, m);
      for (int r = 0; r < m; ++r) {
        for (int c = 0; c < m; ++c) {
          Omega(r, c) = V_known_matrix(r, c);
        }
      }
      for (int i = 0; i < n; ++i) {
        int i1 = 2 * i;
        int i2 = i1 + 1;
        Type cov12 = rho12(i) * sigma1(i) * sigma2(i);
        y_stack(i1) = y1(i);
        y_stack(i2) = y2(i);
        mu_stack(i1) = mu1(i);
        mu_stack(i2) = mu2(i);
        Omega(i1, i1) += sigma1(i) * sigma1(i);
        Omega(i2, i2) += sigma2(i) * sigma2(i);
        Omega(i1, i2) += cov12;
        Omega(i2, i1) += cov12;
      }
      density::MVNORM_t<Type> neg_log_density(Omega);
      nll += neg_log_density(y_stack - mu_stack);
    } else {
      Type log2pi = log(Type(2.0) * M_PI);
      for (int i = 0; i < y1.size(); ++i) {
        if (observed_y1(i) == 1 && observed_y2(i) == 1) {
          Type z1 = (y1(i) - mu1(i)) / sigma1(i);
          Type z2 = (y2(i) - mu2(i)) / sigma2(i);
          Type one_minus_rho2 = Type(1.0) - rho12(i) * rho12(i);
          Type row_nll = log2pi + log_sigma1(i) + log_sigma2(i);
          row_nll += Type(0.5) * log(one_minus_rho2);
          row_nll += Type(0.5) * (z1 * z1 - Type(2.0) * rho12(i) * z1 * z2 + z2 * z2) / one_minus_rho2;
          nll += weights(i) * row_nll;
        } else if (observed_y1(i) == 1) {
          Type z1 = (y1(i) - mu1(i)) / sigma1(i);
          Type row_nll = Type(0.5) * log2pi + log_sigma1(i);
          row_nll += Type(0.5) * z1 * z1;
          nll += weights(i) * row_nll;
        } else if (observed_y2(i) == 1) {
          Type z2 = (y2(i) - mu2(i)) / sigma2(i);
          Type row_nll = Type(0.5) * log2pi + log_sigma2(i);
          row_nll += Type(0.5) * z2 * z2;
          nll += weights(i) * row_nll;
        }
      }
    }

    REPORT(mu1);
    REPORT(mu2);
    REPORT(log_sigma1);
    REPORT(log_sigma2);
    REPORT(sigma1);
    REPORT(sigma2);
    REPORT(eta_rho12);
    REPORT(rho12);
    ADREPORT(beta_mu1);
    ADREPORT(beta_mu2);
    ADREPORT(beta_sigma1);
    ADREPORT(beta_sigma2);
    ADREPORT(beta_rho12);
    if (n_mu_re_terms > 0) {
      vector<Type> sd_mu_re = exp(log_sd_mu);
      vector<Type> log_sd_mu_group(X_sd_mu.rows());
      vector<Type> sd_mu_group(X_sd_mu.rows());
      if (has_sd_mu_model == 1) {
        for (int g = 0; g < X_sd_mu.rows(); ++g) {
          Type eta_sd = Type(0.0);
          for (int k = 0; k < X_sd_mu.cols(); ++k) {
            eta_sd += X_sd_mu(g, k) * beta_sd_mu(k);
          }
          log_sd_mu_group(g) = eta_sd;
          sd_mu_group(g) = exp(eta_sd);
        }
      }
      vector<Type> rho_mu_re(n_mu_re_cors);
      for (int j = 0; j < n_mu_re_cors; ++j) {
        rho_mu_re(j) = Type(0.999999) * tanh(eta_cor_mu(j));
      }
      vector<Type> rho_mu_group(X_cor_mu.rows());
      if (has_cor_mu_model == 1) {
        for (int g = 0; g < X_cor_mu.rows(); ++g) {
          Type eta_cor = Type(0.0);
          for (int k = 0; k < X_cor_mu.cols(); ++k) {
            eta_cor += X_cor_mu(g, k) * beta_cor_mu(k);
          }
          rho_mu_group(g) = Type(0.999999) * tanh(eta_cor);
        }
      }
      REPORT(u_mu);
      REPORT(log_sd_mu);
      REPORT(sd_mu_re);
      ADREPORT(log_sd_mu);
      ADREPORT(sd_mu_re);
      if (has_sd_mu_model == 1) {
        REPORT(beta_sd_mu);
        REPORT(log_sd_mu_group);
        REPORT(sd_mu_group);
        ADREPORT(beta_sd_mu);
        ADREPORT(log_sd_mu_group);
        ADREPORT(sd_mu_group);
      }
      if (n_mu_re_cors > 0) {
        REPORT(eta_cor_mu);
        REPORT(rho_mu_re);
        ADREPORT(eta_cor_mu);
        ADREPORT(rho_mu_re);
      }
      if (has_cor_mu_model == 1) {
        REPORT(beta_cor_mu);
        REPORT(rho_mu_group);
        ADREPORT(beta_cor_mu);
        ADREPORT(rho_mu_group);
      }
    }
    if (n_sigma_re_terms > 0) {
      vector<Type> sd_sigma_re = exp(log_sd_sigma);
      REPORT(u_sigma);
      REPORT(log_sd_sigma);
      REPORT(sd_sigma_re);
      ADREPORT(log_sd_sigma);
      ADREPORT(sd_sigma_re);
      if (n_sigma_re_cors > 0) {
        vector<Type> rho_sigma_re(n_sigma_re_cors);
        for (int j = 0; j < n_sigma_re_cors; ++j) {
          rho_sigma_re(j) = Type(0.999999) * tanh(eta_cor_sigma(j));
        }
        REPORT(eta_cor_sigma);
        REPORT(rho_sigma_re);
        ADREPORT(eta_cor_sigma);
        ADREPORT(rho_sigma_re);
      }
      if (n_mu_sigma_re_cors > 0) {
        vector<Type> rho_mu_sigma_re(n_mu_sigma_re_cors);
        for (int j = 0; j < n_mu_sigma_re_cors; ++j) {
          rho_mu_sigma_re(j) = Type(0.999999) * tanh(eta_cor_mu_sigma(j));
        }
        REPORT(eta_cor_mu_sigma);
        REPORT(rho_mu_sigma_re);
        ADREPORT(eta_cor_mu_sigma);
        ADREPORT(rho_mu_sigma_re);
      }
    }
  }

  return nll;
}
