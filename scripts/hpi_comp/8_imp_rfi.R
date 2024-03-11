#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, aggregate index analyses
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Load libraries

  library(tidyverse)
  library(kingCoData)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

 ## Load custom functions  
  source(file.path(getwd(), 'functions', 'wrapper_function.R'))
  #source(file.path(getwd(), 'functions', 'oldWrappers.R'))
  
### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

  ## Create imputation data set
  homes_df <- readRDS(file = file.path(getwd(), 'data', 'kinghomes_df.RDS'))
  set.seed(1)
  uni_df <- homes_df %>%
    dplyr::sample_frac(., .25)
  
  
### Base Index -----------
  
  #### Agg Index -----
  rfi_index <- rfIndex(trans_df = exp_$hed_df,
                         estimator = 'chain',
                         log_dep = TRUE,
                         dep_var = 'price',
                         ind_var = exp_$ind_var,
                         trim_model = TRUE,
                         ntrees = exp_$rf_par$ntrees,
                         #sim_per = exp_$rf_par$sim_per,
                         max_period = max(exp_$hed_df$trans_period),
                         smooth = FALSE,
                         min.bucket = exp_$rf_par$min_bucket,
                         always.split.variables = 
                           exp_$rf_par$always_split_variables,
                         sim_df = uni_df)%>%
    ind2stl(.)
  
  rfi_index$model$class <- 'imp'
  rfi_index$model$approach <- 'rf'
  
  rfi_series <- createSeries(hpi_obj = rfi_index,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE,
                             sim_df = uni_df) %>%
    suppressWarnings()
  
  rfi_series <- calcRevision(series_obj = rfi_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  rfi_series <- calcSeriesAccuracy(series_obj = rfi_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  rfi_series <- calculateRelAccr(rfi_series,
                                 exp_)
  
  rfi_index$model$approach <- 'rfi'
  saveRDS(rfi_index,
          file = file.path(getwd(), 'data', 'exp_10', 'rfi_index.RDS'))
  saveRDS(rfi_series,
          file = file.path(getwd(), 'data', 'exp_10', 'rfi_series.RDS'))
  
    
### Submarketing -----------------------------------------------------------------------------------  

  exp_$sms <- 'submarket'
  exp_$partition <- names(table(exp_$hed_df$submarket))
  exp_$partition_field <- 'submarket'
  exp_$ind_var <- c('grade', 'age', 'sqft', 'beds', 'baths', 'sqft_lot', 'use', 
                    'latitude', 'longitude')
  
  rfi_subm_ <- purrr::map(.x = exp_$partition,
                          .f = rfWrapper,
                          exp_obj = exp_,
                          estimator = 'chain',
                          sim_df = uni_df)
  
  rfi_sub_obj <- unwrapPartitions(rfi_subm_)
  
  saveRDS(rfi_sub_obj,
          file = file.path(getwd(), 'data', 'exp_10', 'rfi_submarket.RDS'))
  
# ### Sampling Differences ----------------
#   
#   
# ### Extract these out and Save ------------------------  
#   
#   index_df <- indexes2df(index_list = list(med_index),
#                          time_length = 10)
#   -- Write this out at agg_base_index
#   -- med_base_vol (ind)
#   -- med_base_series
#   -- med_base_Rev
#   -- med_base_accr (combine both here with a flag)
#   -- 
#   
#   