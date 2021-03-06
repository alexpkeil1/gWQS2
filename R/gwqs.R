#' Fitting Weighted Quantile Sum regression models
#'
#' Fits Weighted Quantile Sum (WQS) regressions for continuous or binomial outcomes.
#'
#' @param formula An object of class \code{formula} specifying the relationship to be tested. If no
#' covariates are being tested specify \code{y ~ NULL}.
#' @param mix_name A character vector listing the variables contributing to a mixture effect.
#' @param data The \code{data.frame} containing the variables to be included in the model.
#' @param q An \code{integer} to specify how mixture variables will be ranked, e.g. in quartiles
#' (\code{q = 4}), deciles (\code{q = 10}), or percentiles (\code{q = 100}). If \code{q = NULL} then
#' the values of the mixture variables are taken (these must be standardized).
#' @param validation Percentage of the dataset to be used to validate the model. If
#' \code{validation = 0} then the test dataset is used as validation dataset too.
#' @param valid_var A character value containing the name of the variable that identifies the validation
#' and the training dataset. You previously need to create a variable in the dataset which is equal to 1
#' for the observations you want to include in the validation dataset and equal to 0 for the observation
#' you want to include in the training dataset. Assign \code{valid_var = NULL} if you want to let the
#' function create the validation and training dataset by itself.
#' @param b Number of bootstrap samples used in parameter estimation.
#' @param b1_pos A logical value that determines whether weights are derived from models where the beta
#' values were positive or negative.
#' @param b1_constr A logial value that determines whether to apply positive (if \code{b1_pos = TRUE}) or
#' negative (if \code{b1_pos = FALSE}) constraints in the optimization function for the weight estimation.
#' @param family A character value, if equal to \code{"gaussian"} a linear model is implemented, if
#' equal to \code{"binomial"} a logistic model is implemented.
#' @param seed An \code{integer} value to fix the seed, if it is equal to NULL no seed is chosen.
#' @param wqs2 A logical value indicating whether a quadratic term should be included in the model
#' (\code{wqs2 = TRUE}) or not (\code{wqs2 = FALSE}).
#' @param plots A logical value indicating whether plots should be generated with the output
#' (\code{plots = TRUE}) or not (\code{plots = FALSE}).
#' @param tables A logical value indicating whether tables should be generated in the directory
#' with the output (\code{tables = TRUE}) or not (\code{tables = FALSE}). A preview of the estimates
#' of the final weights is generated in the Viewer Pane
#'
#' @details
#' \code{gWQS} uses the \code{glm2} function in the \bold{glm2} package to fit the model. The
#' \code{glm2} package is a modified version of the \code{\link[stats]{glm}} function provided and
#' documented in the stats package.\cr
#'
#' The \code{\link[Rsolnp]{solnp}} optimization function is used to estimate the weights in each
#' bootstrap sample.
#'
#' The \code{seed} argument  specifies a fixed seed through the \code{\link[base]{set.seed}} function.\cr
#'
#' The \code{wqs2} argument includes a quadratic mixture effect in the linear model. In order to test
#' the significance of this term an Analysis of Variance is executed through the
#' \code{\link[stats]{anova}} function.\cr
#'
#' The \code{plots} argument produces two figures through the \code{\link[ggplot2]{ggplot}} function.\cr
#'
#' @return \code{gwqs} return the results of the WQS regression as well as many other objects and datasets.
#'
#' \item{fit}{A \code{glm2} object that summarizes the output of the WQS model, reflecting either a
#' linear or logistic regression depending on how the \code{family} parameter was specified
#' (respectively, \code{"gaussian"} or \code{"binomial"}). The summary function can be used to call and
#' print fit data.}
#' \item{conv}{Indicates whether the solver has converged (0) or not (1 or 2).}
#' \item{wb1pm}{Matrix of estimated weights, mixture effect parameter estimates and the associated
#' p-values estimated for each bootstrap iteration.}
#' \item{y_adj}{Vector containing the y values (dependent variable) adjusted for the residuals of a
#' fitted model adjusted for covariates.}
#' \item{wqs}{Vector containing the wqs index for each subject.}
#' \item{index_b}{List of vectors containing the \code{rownames} of the subjects included in each
#' bootstrap dataset.}
#' \item{data_t}{\code{data.frame} containing the subjects used to estimate the weights in each
#' bootstrap.}
#' \item{data_v}{\code{data.frame} containing the subjects used to estimate the parameters of the final
#' model.}
#' \item{final_weights}{\code{data.frame} containing the final weights associated to each chemical.}
#' \item{fit_2}{It is the same as fit, but it containes the results of the regression with the wqs
#' quadratic term. If \code{wqs2 = FALSE}, NULL is returned.}
#' \item{aov}{Analysis of variance table to test the significance of the wqs quadratic term in the
#' model. If \code{wqs2 = FALSE}, NULL is returned.}
#'
#' @author
#' Stefano Renzetti, Paul Curtin, Allan C Just, Ghalib Bello, Chris Gennings
#'
#' @references
#' Carrico C, Gennings C, Wheeler D, Factor-Litvak P. Characterization of a weighted quantile sum
#' regression for highly correlated data in a risk analysis setting. J Biol Agricul Environ Stat.
#' 2014:1-21. ISSN: 1085-7117. DOI: 10.1007/ s13253-014-0180-3.
#' \url{http://dx.doi.org/10.1007/s13253-014-0180-3}.\cr
#'
#' Czarnota J, Gennings C, Colt JS, De Roos AJ, Cerhan JR, Severson RK, Hartge P, Ward MH,
#' Wheeler D. 2015. Analysis of environmental chemical mixtures and non-Hodgkin lymphoma risk in the
#' NCI-SEER NHL study. Environmental Health Perspectives, DOI:10.1289/ehp.1408630.\cr
#'
#' Czarnota J, Gennings C, Wheeler D. 2015. Assessment of weighted quantile sum regression for modeling
#' chemical mixtures and cancer risk. Cancer Informatics,
#' 2015:14(S2) 159-171 DOI: 10.4137/CIN.S17295.\cr
#'
#' @examples
#' # we save the names of the mixture variables in the variable "toxic_chems"
#' toxic_chems = c("log_LBX074LA", "log_LBX099LA", "log_LBX105LA", "log_LBX118LA",
#' "log_LBX138LA", "log_LBX153LA", "log_LBX156LA", "log_LBX157LA", "log_LBX167LA",
#' "log_LBX170LA", "log_LBX180LA", "log_LBX187LA", "log_LBX189LA", "log_LBX194LA",
#' "log_LBX196LA", "log_LBX199LA", "log_LBXD01LA", "log_LBXD02LA", "log_LBXD03LA",
#' "log_LBXD04LA", "log_LBXD05LA", "log_LBXD07LA", "log_LBXF01LA", "log_LBXF02LA",
#' "log_LBXF03LA", "log_LBXF04LA", "log_LBXF05LA", "log_LBXF06LA", "log_LBXF07LA",
#' "log_LBXF08LA", "log_LBXF09LA", "log_LBXPCBLA", "log_LBXTCDLA", "log_LBXHXCLA")
#'
#' # To run a linear model and save the results in the variable "results". This linear model
#' # (family="Gaussian") will rank/standardize variables in quartiles (q = 4), perform a
#' # 40/60 split of the data for training/validation (validation = 0.6), and estimate weights
#' # over 5 bootstrap samples (b = 3). Weights will be derived from mixture effect
#' # parameters that are positive (b1_pos = TRUE). A unique seed was specified (seed = 2016) so
#' # this model will be reproducible, and plots describing the variable weights and linear
#' # relationship will be generated as output (plots = TRUE). In the end tables describing the
#' # weights values and the model parameters with the respectively statistics are generated in
#' # the viewer window
#' results = gwqs(y ~ NULL, mix_name = toxic_chems, data = wqs_data, q = 4, validation = 0.6,
#'                b = 2, b1_pos = TRUE, b1_constr = FALSE, family = "gaussian", seed = 2016,
#'                wqs2 = FALSE, plots = TRUE, tables = TRUE)
#'
#' # to test the significance of the covariates
#' summary(results$fit)
#'
#' @import ggplot2
#' @import Rsolnp
#' @import tableHTML
#'
#' @importFrom stats lm model.matrix na.omit na.omit glm gaussian binomial resid coef anova quantile
#'
#' @export

gwqs <- function(formula, mix_name, data, q = 4, validation = 0.6, valid_var = NULL, b = 100,
                 b1_pos = TRUE, b1_constr = FALSE, family = "gaussian", seed = NULL, wqs2 = FALSE,
                 plots = FALSE, tables = FALSE){

  # Checking function
  .check.function(formula, mix_name, data, q, validation, valid_var, b, b1_pos, family, seed, wqs2,
                  plots, tables)

  y_name = all.vars(formula)[1]
  covrts = as.matrix(model.matrix(formula, data)[, -1])
  covrts = covrts[match(rownames(data), rownames(covrts)),]
  covrts = as.data.frame(covrts)
  if(dim(covrts)[2] == 1) names(covrts) = all.vars(formula)[-1]
  cov_name = names(covrts)
  data = as.data.frame(data)
  if (is.null(valid_var)) data_f = as.data.frame(suppressWarnings(cbind(data[, c(y_name, mix_name), drop = FALSE], covrts)))
  else data_f = as.data.frame(cbind(data[, c(y_name, mix_name), drop = FALSE], covrts,
                                    data[, valid_var, drop = FALSE]))
  data_f = na.omit(data_f)

  set.seed(seed)

  # defining quantile variables
  if (is.null(q)) {
    q_name = mix_name
  }
  else {
    data_f = quantile_f(data_f, mix_name, q)
    q_name = paste(mix_name, "q", sep = "_")
  }

  # splitting the dataset
  if (is.null(valid_var)){
    splt = split_f(data_f, validation, seed)
    data_t = splt$data_t
    data_v = splt$data_v
  }
  else {
    unique_valid_var = unique(unlist(data_f[, valid_var, drop = FALSE]))
    if (identical(unique_valid_var[order(unique_valid_var)], c(0, 1))){
      data_t = data_f[data_f[, valid_var] == 0,]
      data_v = data_f[data_f[, valid_var] == 1,]
    }
    else stop("valid_var values must be 0 and 1")
  }

  # parameters estimation and model fitting
  par_model = par.modl.est(data_t, y_name, q_name, cov_name, b, b1_pos, b1_constr, family, seed)

  wght_matrix = par_model$wght_matrix
  b1 = par_model$b1
  conv = par_model$conv
  p_val = par_model$p_val
  index_b = par_model$index_b

  # estimate mean weight for each component (exclude weights from iterations with failed convergence)
  wb1pm <- as.data.frame(cbind(wght_matrix, b1, p_val))
  names(wb1pm) = c(mix_name, "b1", "p_val")

  if (b1_pos) {
    mean_weight = colMeans(wb1pm[wb1pm$b1 > 0 & conv!=2, mix_name, drop = FALSE])
    if (dim(wb1pm[wb1pm$b1 > 0 & conv!=2, mix_name, drop = FALSE])[1] == 0)
      stop("There are no positive b1 in the bootstrapped models")
  }
  else {
    mean_weight = colMeans(wb1pm[wb1pm$b1 < 0 & conv!=2, mix_name, drop = FALSE])
    if (dim(wb1pm[wb1pm$b1 < 0 & conv!=2, mix_name, drop = FALSE])[1] == 0)
      stop("There are no negative b1 in the bootstrapped models")
  }

  # fit the final model with the estimated weights
  wqs_model = model.fit(data_v[, q_name, drop = FALSE], data_v[, y_name, drop = FALSE], mean_weight, family,
                        data_v[, cov_name, drop = FALSE], wqs2)

  if (dim(covrts)[2] == 0) y_adj = data_v[, y_name, drop = FALSE]
  else {
    y = as.matrix(data_v[, y_name, drop = FALSE])
    x = as.matrix(data_v[, cov_name, drop = FALSE])
    if (family == "gaussian") {
      fit = glm(y ~ x, family = gaussian(link = "identity"))
      y_adj = mean(as.matrix(data_v[, y_name, drop = FALSE])) + fit$residuals
    }
    else if (family == "binomial") {
      fit = glm(y ~ x, family = binomial(link = "logit"))
      y_adj = resid(fit, type = "pearson")
    }
  }

  # Plots
  data_plot = data.frame(mix_name, mean_weight)
  data_plot = data_plot[order(data_plot$mean_weight),]
  pos = match(data_plot$mix_name, sort(mix_name))
  data_plot$mix_name = factor(data_plot$mix_name, levels(data_plot$mix_name)[pos])

  y_adj_wqs_df = as.data.frame(cbind(y_adj, wqs_model$wqs))
  names(y_adj_wqs_df) = c("y_adj", "wqs")

  if (plots == TRUE) plots(data_plot, y_adj_wqs_df, q, mix_name, mean_weight)

  data_plot = data_plot[order(data_plot$mean_weight, decreasing = TRUE),]
  y_adj = as.numeric(unlist(y_adj))
  wqs_index = as.numeric(unlist(wqs_model$wqs))

  # Tables
  if (tables == TRUE) tables(data_plot, wqs_model$m_f, wqs_model$m_f2, wqs_model$aov)

  # creating the list of elements to return
  results = list(wqs_model$m_f, conv, wb1pm, y_adj, wqs_index, index_b, data_t, data_v,
                 data_plot, wqs_model$m_f2, wqs_model$aov)
  names(results) = c("fit", "conv", "wb1pm", "y_adj", "wqs", "index_b", "data_t", "data_v",
                     "final_weights", "fit_2", "aov")

  return(results)
}

