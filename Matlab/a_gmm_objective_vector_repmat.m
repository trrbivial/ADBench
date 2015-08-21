% Generated by ADiMat 0.6.0-4975
% © 2001-2008 Andre Vehreschild <vehreschild@sc.rwth-aachen.de>
% © 2009-2015 Johannes Willkomm <johannes@johannes-willkomm.de>
% TU Darmstadt, 64289 Darmstadt, Germany
% Visit us on the web at http://www.adimat.de/
% Report bugs to adimat-users@lists.sc.informatik.tu-darmstadt.de
%
%                             DISCLAIMER
% 
% ADiMat was prepared as part of an employment at the Institute for Scientific Computing,
% RWTH Aachen University, Germany and at the Institute for Scientific Computing,
% TU Darmstadt, Germany and is provided AS IS. 
% NEITHER THE AUTHOR(S), THE GOVERNMENT OF THE FEDERAL REPUBLIC OF GERMANY
% NOR ANY AGENCY THEREOF, NOR THE RWTH AACHEN UNIVERSITY, NOT THE TU DARMSTADT,
% INCLUDING ANY OF THEIR EMPLOYEES OR OFFICERS, MAKES ANY WARRANTY, EXPRESS OR IMPLIED,
% OR ASSUMES ANY LEGAL LIABILITY OR RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS,
% OR USEFULNESS OF ANY INFORMATION OR PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE
% WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.
%
% Parameters:
%  - dependents=err
%  - independents=alphas, means, inv_cov_factors
%  - inputEncoding=ISO-8859-1
%
% Functions in this file: a_gmm_objective_vector_repmat, rec_gmm_objective_vector_repmat,
%  ret_gmm_objective_vector_repmat, a_log_wishart_prior, rec_log_wishart_prior,
%  ret_log_wishart_prior, log_wishart_prior, log_gamma_distrib,
%  a_logsumexp_repmat, rec_logsumexp_repmat, ret_logsumexp_repmat
%

function [a_alphas a_means a_inv_cov_factors nr_err] = a_gmm_objective_vector_repmat(alphas, means, inv_cov_factors, x, hparams, a_err)
% GMM_OBJECTIVE  Evaluate GMM negative log likelihood for one point
%             ALPHAS 
%                1 x k vector of logs of mixture weights (unnormalized), so
%                weights = exp(log_alphas)/sum(exp(log_alphas))
%             MEANS
%                d x k matrix of component means
%             INV_COV_FACTORS 
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
%             X 
%               are data points (d x n vector)
%             HPARAMS
%                [gamma, m] wishart distribution parameters
%         Output ERR is the sum of errors over all points
%      To generate params given covariance C:
%           L = inv(chol(C,'lower'));
%           inv_cov_factor = [log(diag(L)); L(au_tril_indices(d,-1))]
   tmpca1 = 0;
   tmpca2 = 0;
   tmpca3 = 0;
   tmpca4 = 0;
   tmpda1 = 0;
   tmplia1 = 0;
   Lparams = 0;
   logLdiag = 0;
   Q = 0;
   mahal = 0;
   d = size(x, 1);
   k = size(alphas, 2);
   n = size(x, 2);
   lower_triangle_indices = tril(ones(d, d), -1) ~= 0;
   lse = zeros(k, n, 'like', alphas);
   tmpfra1_2 = k;
   for ik=1 : tmpfra1_2
      adimat_push1(Lparams);
      Lparams = inv_cov_factors(:, ik);
      adimat_push1(logLdiag);
      logLdiag = Lparams(1 : d);
      adimat_push1(tmpca1);
      tmpca1 = exp(logLdiag);
      adimat_push1(Q);
      Q = diag(tmpca1);
      adimat_push1(tmpda1);
      tmpda1 = d + 1;
      adimat_push1(tmplia1);
      tmplia1 = Lparams(tmpda1 : end);
      adimat_push_index1(Q, lower_triangle_indices);
      Q(lower_triangle_indices) = tmplia1;
      adimat_push1(tmpca2);
      tmpca2 = repmat(means(:, ik), 1, n);
      adimat_push1(tmpca1);
      tmpca1 = x - tmpca2;
      adimat_push1(mahal);
      mahal = Q * tmpca1;
      adimat_push1(tmpca4);
      tmpca4 = mahal .^ 2;
      adimat_push1(tmpca3);
      tmpca3 = sum(tmpca4, 1);
      adimat_push1(tmpca2);
      tmpca2 = 0.5 * tmpca3;
      adimat_push1(tmpca1);
      tmpca1 = sum(logLdiag);
      adimat_push1(tmplia1);
      tmplia1 = alphas(ik) + tmpca1 - tmpca2;
      adimat_push_index2(lse, ik, ':');
      lse(ik, :) = tmplia1;
   end
   adimat_push1(tmpfra1_2);
   constant = -n * d * 0.5 * log(2 * pi);
   adimat_push1(tmpca4);
   tmpca4 = rec_logsumexp_repmat(alphas);
   adimat_push1(tmpca3);
   tmpca3 = n * tmpca4;
   adimat_push1(tmpca2);
   tmpca2 = rec_logsumexp_repmat(lse);
   adimat_push1(tmpca1);
   tmpca1 = sum(tmpca2);
   err = constant + tmpca1 - tmpca3;
   adimat_push1(tmpca1);
   tmpca1 = rec_log_wishart_prior(hparams, d, inv_cov_factors);
   adimat_push1(err);
   err = err + tmpca1;
   nr_err = err;
   [a_lse a_Lparams a_logLdiag a_Q a_mahal a_tmpca1 a_tmpca2 a_tmpca3 a_tmpca4 a_tmplia1 a_alphas a_means a_inv_cov_factors] = a_zeros(lse, Lparams, logLdiag, Q, mahal, tmpca1, tmpca2, tmpca3, tmpca4, tmplia1, alphas, means, inv_cov_factors);
   if nargin < 6
      a_err = a_zeros1(err);
   end
   err = adimat_pop1;
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_err));
   tmpsa1 = a_err;
   a_err = a_zeros1(err);
   a_err = adimat_adjsum(a_err, adimat_adjred(err, tmpsa1));
   [tmpadjc3] = ret_log_wishart_prior(a_tmpca1);
   tmpca1 = adimat_pop1;
   a_inv_cov_factors = adimat_adjsum(a_inv_cov_factors, tmpadjc3);
   a_tmpca1 = a_zeros1(tmpca1);
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_err));
   a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjred(tmpca3, -a_err));
   tmpca1 = adimat_pop1;
   a_tmpca2 = adimat_adjsum(a_tmpca2, a_sum(a_tmpca1, tmpca2));
   a_tmpca1 = a_zeros1(tmpca1);
   [tmpadjc1] = ret_logsumexp_repmat(a_tmpca2);
   tmpca2 = adimat_pop1;
   a_lse = adimat_adjsum(a_lse, tmpadjc1);
   a_tmpca2 = a_zeros1(tmpca2);
   tmpca3 = adimat_pop1;
   a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjmultr(tmpca4, n, a_tmpca3));
   a_tmpca3 = a_zeros1(tmpca3);
   [tmpadjc1] = ret_logsumexp_repmat(a_tmpca4);
   tmpca4 = adimat_pop1;
   a_alphas = adimat_adjsum(a_alphas, tmpadjc1);
   a_tmpca4 = a_zeros1(tmpca4);
   tmpfra1_2 = adimat_pop1;
   for ik=fliplr(1 : tmpfra1_2)
      lse = adimat_pop_index2(lse, ik, ':');
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_lse(ik, :))));
      a_lse = a_zeros_index2(a_lse, lse, ik, ':');
      tmplia1 = adimat_pop1;
      a_alphas(ik) = adimat_adjsum(a_alphas(ik), adimat_adjred(alphas(ik), a_tmplia1));
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_tmplia1));
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmplia1));
      a_tmplia1 = a_zeros1(tmplia1);
      tmpca1 = adimat_pop1;
      a_logLdiag = adimat_adjsum(a_logLdiag, a_sum(a_tmpca1, logLdiag));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjmultr(tmpca3, 0.5, a_tmpca2));
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_tmpca4 = adimat_adjsum(a_tmpca4, a_sum(a_tmpca3, tmpca4, 1));
      a_tmpca3 = a_zeros1(tmpca3);
      tmpca4 = adimat_pop1;
      a_mahal = adimat_adjsum(a_mahal, adimat_adjred(mahal, 2 .* mahal.^1 .* a_tmpca4));
      a_tmpca4 = a_zeros1(tmpca4);
      mahal = adimat_pop1;
      a_Q = adimat_adjsum(a_Q, adimat_adjmultl(Q, a_mahal, tmpca1));
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, Q, a_mahal));
      a_mahal = a_zeros1(mahal);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_means(:, ik) = adimat_adjsum(a_means(:, ik), a_repmat(a_tmpca2, means(:, ik), 1, n));
      a_tmpca2 = a_zeros1(tmpca2);
      Q = adimat_pop_index1(Q, lower_triangle_indices);
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_Q(lower_triangle_indices))));
      a_Q = a_zeros_index1(a_Q, Q, lower_triangle_indices);
      tmplia1 = adimat_pop1;
      a_Lparams(tmpda1 : end) = adimat_adjsum(a_Lparams(tmpda1 : end), a_tmplia1);
      a_tmplia1 = a_zeros1(tmplia1);
      [tmpda1 Q] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, a_diag(a_Q, tmpca1));
      a_Q = a_zeros1(Q);
      tmpca1 = adimat_pop1;
      a_logLdiag = adimat_adjsum(a_logLdiag, exp(logLdiag) .* a_tmpca1);
      a_tmpca1 = a_zeros1(tmpca1);
      logLdiag = adimat_pop1;
      a_Lparams(1 : d) = adimat_adjsum(a_Lparams(1 : d), a_logLdiag);
      a_logLdiag = a_zeros1(logLdiag);
      Lparams = adimat_pop1;
      a_inv_cov_factors(:, ik) = adimat_adjsum(a_inv_cov_factors(:, ik), a_Lparams);
      a_Lparams = a_zeros1(Lparams);
   end
end

function err = rec_gmm_objective_vector_repmat(alphas, means, inv_cov_factors, x, hparams)
   tmpca1 = 0;
   tmpca2 = 0;
   tmpca3 = 0;
   tmpca4 = 0;
   tmpda1 = 0;
   tmplia1 = 0;
   Lparams = 0;
   logLdiag = 0;
   Q = 0;
   mahal = 0;
   d = size(x, 1);
   k = size(alphas, 2);
   n = size(x, 2);
   lower_triangle_indices = tril(ones(d, d), -1) ~= 0;
   lse = zeros(k, n, 'like', alphas);
   tmpfra1_2 = k;
   for ik=1 : tmpfra1_2
      adimat_push1(Lparams);
      Lparams = inv_cov_factors(:, ik);
      adimat_push1(logLdiag);
      logLdiag = Lparams(1 : d);
      adimat_push1(tmpca1);
      tmpca1 = exp(logLdiag);
      adimat_push1(Q);
      Q = diag(tmpca1);
      adimat_push1(tmpda1);
      tmpda1 = d + 1;
      adimat_push1(tmplia1);
      tmplia1 = Lparams(tmpda1 : end);
      adimat_push_index1(Q, lower_triangle_indices);
      Q(lower_triangle_indices) = tmplia1;
      adimat_push1(tmpca2);
      tmpca2 = repmat(means(:, ik), 1, n);
      adimat_push1(tmpca1);
      tmpca1 = x - tmpca2;
      adimat_push1(mahal);
      mahal = Q * tmpca1;
      adimat_push1(tmpca4);
      tmpca4 = mahal .^ 2;
      adimat_push1(tmpca3);
      tmpca3 = sum(tmpca4, 1);
      adimat_push1(tmpca2);
      tmpca2 = 0.5 * tmpca3;
      adimat_push1(tmpca1);
      tmpca1 = sum(logLdiag);
      adimat_push1(tmplia1);
      tmplia1 = alphas(ik) + tmpca1 - tmpca2;
      adimat_push_index2(lse, ik, ':');
      lse(ik, :) = tmplia1;
   end
   adimat_push1(tmpfra1_2);
   constant = -n * d * 0.5 * log(2 * pi);
   adimat_push1(tmpca4);
   tmpca4 = rec_logsumexp_repmat(alphas);
   adimat_push1(tmpca3);
   tmpca3 = n * tmpca4;
   adimat_push1(tmpca2);
   tmpca2 = rec_logsumexp_repmat(lse);
   adimat_push1(tmpca1);
   tmpca1 = sum(tmpca2);
   err = constant + tmpca1 - tmpca3;
   adimat_push1(tmpca1);
   tmpca1 = rec_log_wishart_prior(hparams, d, inv_cov_factors);
   adimat_push1(err);
   err = err + tmpca1;
   adimat_push(d, k, n, lower_triangle_indices, lse, ik, Lparams, logLdiag, Q, mahal, constant, tmpca1, tmpca2, tmpca3, tmpca4, tmpda1, tmplia1, err, alphas, means, inv_cov_factors);
   if nargin > 3
      adimat_push1(x);
   end
   if nargin > 4
      adimat_push1(hparams);
   end
   adimat_push1(nargin);
end

function [a_alphas a_means a_inv_cov_factors] = ret_gmm_objective_vector_repmat(a_err)
   tmpnargin = adimat_pop1;
   if tmpnargin > 4
      hparams = adimat_pop1;
   end
   if tmpnargin > 3
      x = adimat_pop1;
   end
   [inv_cov_factors means alphas err tmplia1 tmpda1 tmpca4 tmpca3 tmpca2 tmpca1 constant mahal Q logLdiag Lparams ik lse lower_triangle_indices n k d] = adimat_pop;
   [a_lse a_Lparams a_logLdiag a_Q a_mahal a_tmpca1 a_tmpca2 a_tmpca3 a_tmpca4 a_tmplia1 a_alphas a_means a_inv_cov_factors] = a_zeros(lse, Lparams, logLdiag, Q, mahal, tmpca1, tmpca2, tmpca3, tmpca4, tmplia1, alphas, means, inv_cov_factors);
   if nargin < 1
      a_err = a_zeros1(err);
   end
   err = adimat_pop1;
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_err));
   tmpsa1 = a_err;
   a_err = a_zeros1(err);
   a_err = adimat_adjsum(a_err, adimat_adjred(err, tmpsa1));
   [tmpadjc3] = ret_log_wishart_prior(a_tmpca1);
   tmpca1 = adimat_pop1;
   a_inv_cov_factors = adimat_adjsum(a_inv_cov_factors, tmpadjc3);
   a_tmpca1 = a_zeros1(tmpca1);
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_err));
   a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjred(tmpca3, -a_err));
   tmpca1 = adimat_pop1;
   a_tmpca2 = adimat_adjsum(a_tmpca2, a_sum(a_tmpca1, tmpca2));
   a_tmpca1 = a_zeros1(tmpca1);
   [tmpadjc1] = ret_logsumexp_repmat(a_tmpca2);
   tmpca2 = adimat_pop1;
   a_lse = adimat_adjsum(a_lse, tmpadjc1);
   a_tmpca2 = a_zeros1(tmpca2);
   tmpca3 = adimat_pop1;
   a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjmultr(tmpca4, n, a_tmpca3));
   a_tmpca3 = a_zeros1(tmpca3);
   [tmpadjc1] = ret_logsumexp_repmat(a_tmpca4);
   tmpca4 = adimat_pop1;
   a_alphas = adimat_adjsum(a_alphas, tmpadjc1);
   a_tmpca4 = a_zeros1(tmpca4);
   tmpfra1_2 = adimat_pop1;
   for ik=fliplr(1 : tmpfra1_2)
      lse = adimat_pop_index2(lse, ik, ':');
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_lse(ik, :))));
      a_lse = a_zeros_index2(a_lse, lse, ik, ':');
      tmplia1 = adimat_pop1;
      a_alphas(ik) = adimat_adjsum(a_alphas(ik), adimat_adjred(alphas(ik), a_tmplia1));
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_tmplia1));
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmplia1));
      a_tmplia1 = a_zeros1(tmplia1);
      tmpca1 = adimat_pop1;
      a_logLdiag = adimat_adjsum(a_logLdiag, a_sum(a_tmpca1, logLdiag));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjmultr(tmpca3, 0.5, a_tmpca2));
      a_tmpca2 = a_zeros1(tmpca2);
      tmpca3 = adimat_pop1;
      a_tmpca4 = adimat_adjsum(a_tmpca4, a_sum(a_tmpca3, tmpca4, 1));
      a_tmpca3 = a_zeros1(tmpca3);
      tmpca4 = adimat_pop1;
      a_mahal = adimat_adjsum(a_mahal, adimat_adjred(mahal, 2 .* mahal.^1 .* a_tmpca4));
      a_tmpca4 = a_zeros1(tmpca4);
      mahal = adimat_pop1;
      a_Q = adimat_adjsum(a_Q, adimat_adjmultl(Q, a_mahal, tmpca1));
      a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, Q, a_mahal));
      a_mahal = a_zeros1(mahal);
      tmpca1 = adimat_pop1;
      a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
      a_tmpca1 = a_zeros1(tmpca1);
      tmpca2 = adimat_pop1;
      a_means(:, ik) = adimat_adjsum(a_means(:, ik), a_repmat(a_tmpca2, means(:, ik), 1, n));
      a_tmpca2 = a_zeros1(tmpca2);
      Q = adimat_pop_index1(Q, lower_triangle_indices);
      a_tmplia1 = adimat_adjsum(a_tmplia1, adimat_adjred(tmplia1, adimat_adjreshape(tmplia1, a_Q(lower_triangle_indices))));
      a_Q = a_zeros_index1(a_Q, Q, lower_triangle_indices);
      tmplia1 = adimat_pop1;
      a_Lparams(tmpda1 : end) = adimat_adjsum(a_Lparams(tmpda1 : end), a_tmplia1);
      a_tmplia1 = a_zeros1(tmplia1);
      [tmpda1 Q] = adimat_pop;
      a_tmpca1 = adimat_adjsum(a_tmpca1, a_diag(a_Q, tmpca1));
      a_Q = a_zeros1(Q);
      tmpca1 = adimat_pop1;
      a_logLdiag = adimat_adjsum(a_logLdiag, exp(logLdiag) .* a_tmpca1);
      a_tmpca1 = a_zeros1(tmpca1);
      logLdiag = adimat_pop1;
      a_Lparams(1 : d) = adimat_adjsum(a_Lparams(1 : d), a_logLdiag);
      a_logLdiag = a_zeros1(logLdiag);
      Lparams = adimat_pop1;
      a_inv_cov_factors(:, ik) = adimat_adjsum(a_inv_cov_factors(:, ik), a_Lparams);
      a_Lparams = a_zeros1(Lparams);
   end
end

function [a_inv_cov_factors nr_out] = a_log_wishart_prior(hparams, p, inv_cov_factors, a_out)
% LOG_WISHART_PRIOR  
%               HPARAMS = [gamma m]
%               P data dimension
%             INV_COV_FACTORS
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
   gamma = hparams(1);
   m = hparams(2);
   n = p + m + 1;
   tmpda9 = p + 1;
   tmpca8 = inv_cov_factors(tmpda9 : end, :) .^ 2;
   tmpca7 = sum(tmpca8, 1);
   tmpca6 = exp(inv_cov_factors(1 : p, :));
   tmpca5 = tmpca6 .^ 2;
   tmpca4 = sum(tmpca5, 1);
   tmpca3 = tmpca4 + tmpca7;
   tmpda2 = gamma ^ 2;
   tmpda1 = 0.5 * tmpda2;
   term1 = tmpda1 * tmpca3;
   tmpca1 = sum(inv_cov_factors(1 : p, :), 1);
   term2 = m * tmpca1;
   C = n*p*(log(gamma) - 0.5*log(2)) - log_gamma_distrib(0.5 * n, p);
   adimat_push1(tmpca1);
   tmpca1 = term1 - term2 - C;
   out = sum(tmpca1);
   nr_out = out;
   [a_term1 a_term2 a_tmpca1 a_tmpca3 a_tmpca4 a_tmpca5 a_tmpca6 a_tmpca7 a_tmpca8 a_inv_cov_factors] = a_zeros(term1, term2, tmpca1, tmpca3, tmpca4, tmpca5, tmpca6, tmpca7, tmpca8, inv_cov_factors);
   if nargin < 4
      a_out = a_zeros1(out);
   end
   a_tmpca1 = adimat_adjsum(a_tmpca1, a_sum(a_out, tmpca1));
   tmpca1 = adimat_pop1;
   a_term1 = adimat_adjsum(a_term1, adimat_adjred(term1, a_tmpca1));
   a_term2 = adimat_adjsum(a_term2, adimat_adjred(term2, -a_tmpca1));
   a_tmpca1 = a_zeros1(tmpca1);
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, m, a_term2));
   a_inv_cov_factors(1 : p, :) = adimat_adjsum(a_inv_cov_factors(1 : p, :), a_sum(a_tmpca1, inv_cov_factors(1 : p, :), 1));
   a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjmultr(tmpca3, tmpda1, a_term1));
   a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjred(tmpca4, a_tmpca3));
   a_tmpca7 = adimat_adjsum(a_tmpca7, adimat_adjred(tmpca7, a_tmpca3));
   a_tmpca5 = adimat_adjsum(a_tmpca5, a_sum(a_tmpca4, tmpca5, 1));
   a_tmpca6 = adimat_adjsum(a_tmpca6, adimat_adjred(tmpca6, 2 .* tmpca6.^1 .* a_tmpca5));
   a_inv_cov_factors(1 : p, :) = adimat_adjsum(a_inv_cov_factors(1 : p, :), exp(inv_cov_factors(1 : p, :)) .* a_tmpca6);
   a_tmpca8 = adimat_adjsum(a_tmpca8, a_sum(a_tmpca7, tmpca8, 1));
   a_inv_cov_factors(tmpda9 : end, :) = adimat_adjsum(a_inv_cov_factors(tmpda9 : end, :), adimat_adjred(inv_cov_factors(tmpda9 : end, :), 2 .* inv_cov_factors(tmpda9 : end, :).^1 .* a_tmpca8));
end

function out = rec_log_wishart_prior(hparams, p, inv_cov_factors)
   gamma = hparams(1);
   m = hparams(2);
   n = p + m + 1;
   tmpda9 = p + 1;
   tmpca8 = inv_cov_factors(tmpda9 : end, :) .^ 2;
   tmpca7 = sum(tmpca8, 1);
   tmpca6 = exp(inv_cov_factors(1 : p, :));
   tmpca5 = tmpca6 .^ 2;
   tmpca4 = sum(tmpca5, 1);
   tmpca3 = tmpca4 + tmpca7;
   tmpda2 = gamma ^ 2;
   tmpda1 = 0.5 * tmpda2;
   term1 = tmpda1 * tmpca3;
   tmpca1 = sum(inv_cov_factors(1 : p, :), 1);
   term2 = m * tmpca1;
   C = n*p*(log(gamma) - 0.5*log(2)) - log_gamma_distrib(0.5 * n, p);
   adimat_push1(tmpca1);
   tmpca1 = term1 - term2 - C;
   out = sum(tmpca1);
   adimat_push(gamma, m, n, term1, term2, C, tmpca1, tmpca3, tmpca4, tmpca5, tmpca6, tmpca7, tmpca8, tmpda1, tmpda2, tmpda9, out, hparams, p, inv_cov_factors);
end

function a_inv_cov_factors = ret_log_wishart_prior(a_out)
   [inv_cov_factors p hparams out tmpda9 tmpda2 tmpda1 tmpca8 tmpca7 tmpca6 tmpca5 tmpca4 tmpca3 tmpca1 C term2 term1 n m gamma] = adimat_pop;
   [a_term1 a_term2 a_tmpca1 a_tmpca3 a_tmpca4 a_tmpca5 a_tmpca6 a_tmpca7 a_tmpca8 a_inv_cov_factors] = a_zeros(term1, term2, tmpca1, tmpca3, tmpca4, tmpca5, tmpca6, tmpca7, tmpca8, inv_cov_factors);
   if nargin < 1
      a_out = a_zeros1(out);
   end
   a_tmpca1 = adimat_adjsum(a_tmpca1, a_sum(a_out, tmpca1));
   tmpca1 = adimat_pop1;
   a_term1 = adimat_adjsum(a_term1, adimat_adjred(term1, a_tmpca1));
   a_term2 = adimat_adjsum(a_term2, adimat_adjred(term2, -a_tmpca1));
   a_tmpca1 = a_zeros1(tmpca1);
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjmultr(tmpca1, m, a_term2));
   a_inv_cov_factors(1 : p, :) = adimat_adjsum(a_inv_cov_factors(1 : p, :), a_sum(a_tmpca1, inv_cov_factors(1 : p, :), 1));
   a_tmpca3 = adimat_adjsum(a_tmpca3, adimat_adjmultr(tmpca3, tmpda1, a_term1));
   a_tmpca4 = adimat_adjsum(a_tmpca4, adimat_adjred(tmpca4, a_tmpca3));
   a_tmpca7 = adimat_adjsum(a_tmpca7, adimat_adjred(tmpca7, a_tmpca3));
   a_tmpca5 = adimat_adjsum(a_tmpca5, a_sum(a_tmpca4, tmpca5, 1));
   a_tmpca6 = adimat_adjsum(a_tmpca6, adimat_adjred(tmpca6, 2 .* tmpca6.^1 .* a_tmpca5));
   a_inv_cov_factors(1 : p, :) = adimat_adjsum(a_inv_cov_factors(1 : p, :), exp(inv_cov_factors(1 : p, :)) .* a_tmpca6);
   a_tmpca8 = adimat_adjsum(a_tmpca8, a_sum(a_tmpca7, tmpca8, 1));
   a_inv_cov_factors(tmpda9 : end, :) = adimat_adjsum(a_inv_cov_factors(tmpda9 : end, :), adimat_adjred(inv_cov_factors(tmpda9 : end, :), 2 .* inv_cov_factors(tmpda9 : end, :).^1 .* a_tmpca8));
end

function out = log_wishart_prior(hparams, p, inv_cov_factors)
% LOG_WISHART_PRIOR  
%               HPARAMS = [gamma m]
%               P data dimension
%             INV_COV_FACTORS
%                (d*(d+1)/2) x k matrix, parametrizing 
%                lower triangular square roots of inverse covariances
%                log of diagonal is first d params
   gamma = hparams(1);
   m = hparams(2);
   n = p + m + 1;
   tmpda9 = p + 1;
   tmpca8 = inv_cov_factors(tmpda9 : end, :) .^ 2;
   tmpca7 = sum(tmpca8, 1);
   tmpca6 = exp(inv_cov_factors(1 : p, :));
   tmpca5 = tmpca6 .^ 2;
   tmpca4 = sum(tmpca5, 1);
   tmpca3 = tmpca4 + tmpca7;
   tmpda2 = gamma ^ 2;
   tmpda1 = 0.5 * tmpda2;
   term1 = tmpda1 * tmpca3;
   tmpca1 = sum(inv_cov_factors(1 : p, :), 1);
   term2 = m * tmpca1;
   C = n*p*(log(gamma) - 0.5*log(2)) - log_gamma_distrib(0.5 * n, p);
   tmpca1 = term1 - term2 - C;
   out = sum(tmpca1);
end

function out = log_gamma_distrib(a, p)
   out = log(pi ^ (0.25 * p * (p - 1)));
   for j=1 : p
      out = out + gammaln(a + 0.5*(1 - j));
   end
end

function [a_x nr_out] = a_logsumexp_repmat(x, a_out)
% LOGSUMEXP  Compute log(sum(exp(x))) stably.
%               X is k x n
%               OUT is 1 x n
   mx = max(x);
   tmpda3 = size(x, 1);
   tmpca2 = repmat(mx, tmpda3, 1);
   tmpca1 = x - tmpca2;
   emx = exp(tmpca1);
   semx = sum(emx);
   adimat_push1(tmpca1);
   tmpca1 = log(semx);
   out = tmpca1 + mx;
   nr_out = out;
   [a_mx a_emx a_semx a_tmpca1 a_tmpca2 a_x] = a_zeros(mx, emx, semx, tmpca1, tmpca2, x);
   if nargin < 2
      a_out = a_zeros1(out);
   end
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_out));
   a_mx = adimat_adjsum(a_mx, adimat_adjred(mx, a_out));
   tmpca1 = adimat_pop1;
   a_semx = adimat_adjsum(a_semx, a_tmpca1 ./ semx);
   a_tmpca1 = a_zeros1(tmpca1);
   a_emx = adimat_adjsum(a_emx, a_sum(a_semx, emx));
   a_tmpca1 = adimat_adjsum(a_tmpca1, exp(tmpca1) .* a_emx);
   a_x = adimat_adjsum(a_x, adimat_adjred(x, a_tmpca1));
   a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
   a_mx = adimat_adjsum(a_mx, a_repmat(a_tmpca2, mx, tmpda3, 1));
   a_x = adimat_adjsum(a_x, adimat_max1(x, a_mx));
end

function out = rec_logsumexp_repmat(x)
   mx = max(x);
   tmpda3 = size(x, 1);
   tmpca2 = repmat(mx, tmpda3, 1);
   tmpca1 = x - tmpca2;
   emx = exp(tmpca1);
   semx = sum(emx);
   adimat_push1(tmpca1);
   tmpca1 = log(semx);
   out = tmpca1 + mx;
   adimat_push(mx, emx, semx, tmpca1, tmpca2, tmpda3, out, x);
end

function a_x = ret_logsumexp_repmat(a_out)
   [x out tmpda3 tmpca2 tmpca1 semx emx mx] = adimat_pop;
   [a_mx a_emx a_semx a_tmpca1 a_tmpca2 a_x] = a_zeros(mx, emx, semx, tmpca1, tmpca2, x);
   if nargin < 1
      a_out = a_zeros1(out);
   end
   a_tmpca1 = adimat_adjsum(a_tmpca1, adimat_adjred(tmpca1, a_out));
   a_mx = adimat_adjsum(a_mx, adimat_adjred(mx, a_out));
   tmpca1 = adimat_pop1;
   a_semx = adimat_adjsum(a_semx, a_tmpca1 ./ semx);
   a_tmpca1 = a_zeros1(tmpca1);
   a_emx = adimat_adjsum(a_emx, a_sum(a_semx, emx));
   a_tmpca1 = adimat_adjsum(a_tmpca1, exp(tmpca1) .* a_emx);
   a_x = adimat_adjsum(a_x, adimat_adjred(x, a_tmpca1));
   a_tmpca2 = adimat_adjsum(a_tmpca2, adimat_adjred(tmpca2, -a_tmpca1));
   a_mx = adimat_adjsum(a_mx, a_repmat(a_tmpca2, mx, tmpda3, 1));
   a_x = adimat_adjsum(a_x, adimat_max1(x, a_mx));
end
