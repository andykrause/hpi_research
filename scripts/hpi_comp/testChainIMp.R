#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, index only results
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Load libraries

library(tidyverse)
library(kingCoData)
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Load custom functions  
source(file.path(getwd(), 'functions', 'wrapper_function.R'))

# Data
homes_df <- readRDS(file = file.path(getwd(), 'data', 'kinghomes_df.RDS'))


periodOverPeriod <- function(index_obj){
  index_obj$index$PoP <- c(0, (index_obj$index$value[-1] / 
                                 index_obj$index$value[-length(index_obj$index$value)]) -1)
  index_obj
}  

# Set Experiment Setup to use
exp <- 'exp_5'

# Read in experiment object (includes pre-filtered data)
exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

 
rfIndex(trans_df = exp_$hed_df,
        estimator = 'chain',
        log_dep = TRUE,
        dep_var = 'price',
        ind_var = exp_$ind_var,
        trim_model = TRUE,
        ntrees = exp_$rf_par$ntrees,
        sim_per = exp_$rf_par$sim_per,
        max_period = max(exp_$hed_df$trans_period),
        smooth = FALSE,
        min.bucket = exp_$rf_par$min_bucket) -> chain

rfIndex(trans_df = exp_$hed_df,
        estimator = 'chain',
        log_dep = TRUE,
        dep_var = 'price',
        ind_var = exp_$ind_var,
        trim_model = TRUE,
        ntrees = exp_$rf_par$ntrees,
        sim_per = exp_$rf_par$sim_per,
        max_period = max(exp_$hed_df$trans_period),
        smooth = FALSE,
        min.bucket = exp_$rf_par$min_bucket,
        sim_df = homes_df) -> chainx

rfIndex(trans_df = exp_$hed_df,
        estimator = 'pdp',
        log_dep = TRUE,
        dep_var = 'price',
        ind_var = exp_$ind_var,
        trim_model = TRUE,
        ntrees = exp_$rf_par$ntrees,
        sim_per = exp_$rf_par$sim_per,
        max_period = max(exp_$hed_df$trans_period),
        smooth = FALSE,
        min.bucket = exp_$rf_par$min_bucket,
        always.split.variables = 
          exp_$rf_par$always_split_variables) -> pdp






# 
# 
# rf_df <- exp_$hed_df
# rf_spec <- as.formula(log(price) ~ sqft + age + submarket)
# ntrees = 50
# seed = 1
# 
# chainModel(estimate = 'chain', rf_df = exp_$hed_df, rf_spec = rf_spec)
# 
# chainModel <- function(estimator,
#                        rf_df,
#                        rf_spec,
#                        ntrees = 200,
#                        seed = 1,
#                        ...){
#   
#   # Split data
#   data_ <- split(rf_df, rf_df$trans_period)
#   
#   # Models
#   rf_ <- purrr::map(.x = data_,
#                     .f = ranger::ranger,
#                     formula = rf_spec,
#                     num.trees = ntrees,
#                     seed = seed)#,
#                     #...)
#   
#   # Get Simulation DF
#   sim_df <- rfSimDf(rf_df = rf_df,
#                     seed = seed,
#                     ...)
#   
#   # Get simulation observations
#   pred_ <- purrr::map(.x = rf_,
#                       .f = predict,
#                       data = sim_df)
#   
#   # Add 'coefficients'
#   log_dep <- ifelse(grepl('log', rf_spec[2]), TRUE, FALSE)
#   
#   if(log_dep){
#     
#     pred_ <- purrr::map(.x = pred_,
#                        .f = function(x) exp(x$predictions))
#   }
#   
#   coefs <- purrr::map(.x = pred_,
#                       .f = function(x) mean(x)) %>%
#       unlist()
#   
#   coefs <- (coefs / coefs[1]) - 1
#   
#   rf_model <- list()  
#   rf_model$model <- rf_
#   rf_model$pred <- preds_
#   rf_model$coefficients <- data.frame(time = 1:max(rf_df$trans_period),
#                                       coefficient = coefs)
#   
#   # Structure and return
#   structure(rf_model, class = c('rfmodel', class(rf_model)))
# }
# 
