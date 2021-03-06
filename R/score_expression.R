#' Unevaluated prediction expressions for models
#'
#' Generate an unevaluated call corresponding to the predict step of the passed
#' model. The call represents the response function of the linear predictor in terms
#' of elementary functions on the underlying column names, and is suitable for
#' direct translation into SQL.
#'
#' @section Warning:
#' The Binomial models in glmboost return coefficients which are 1/2 the coefficients
#' fit by a call to glm(..., family=binomial(...)), because the response variable is
#' internally recoded to -1 and +1. sqlscore multiplies the returned coefficients by 2
#' to put them back on the same scale as glm, and adds the glmboost offset to the
#' intercept before multiplying.
#
#' @param mod A supported model object.
#' @param response The name of a custom response function to apply to the linear predictor.
#'
#' @return An unevaluated R call object representing the response function of the linear predictor.
#'
#' @rdname score_expression
#'
#' @examples
#' # A Gaussian GLM including factors
#' mod <- glm(Sepal.Length ~ Sepal.Width + Petal.Length + Petal.Width + Species,
#'            data=datasets::iris)
#' score_expression(mod)
#'
#' # A binomial GLM - linear predictor is unaffected
#' mod <- glm(Sepal.Length > 5.0 ~ Sepal.Width + Petal.Length + Petal.Width + Species,
#'            data=datasets::iris, family=binomial("logit"))
#' score_expression(mod)
#'
#' #With a hand-specified response function
#' score_expression(mod, response="probit")
#'
#' #With formula operators
#' x <- matrix(rnorm(100*20),100,20)
#' colnames(x) <- sapply(1:20, function(x) paste0("X", as.character(x)))
#' x <- as.data.frame(x)
#' mod <- glm(X2 ~ X3 + X5 + X15*X8, data=x)
#' score_expression(mod)
#'
#' @export
score_expression <-
function(mod, response=NULL)
{
  #If we've been requested to use a particular response function by name,
  #generate a call to it and return that. This lets you use a
  #custom sql function or DB features (e.g., probit) that a) don't
  #have portable sql names, and that b) we can't express in closed form
  #in terms of elementary functions.
  if(!is.null(response))
  {
    lp <- linpred(mod)
    return(as.call(list(as.symbol(response), lp)))
  }

  #Otherwise, let's figure out what the response should be. If it
  #should be something we can't generate in closed form, stop
  #and suggest using a sql function and the response argument.
  lp <- linpred(mod)
  lnk <- linkfun(mod)

  return(lnk(lp))
}
