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

### Base Index -----------
  
  #### Agg Index -----
  rtm_index <- rtIndex(trans_df = exp_$rt_df,
                       estimator = 'robust') %>%
    ind2stl(.)
  
  rtm_series <- createSeries(hpi_obj = rtm_index,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE) %>%
    suppressWarnings()

  rtm_series <- calcRevision(series_obj = rtm_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  rtm_series <- calcSeriesAccuracy(series_obj = rtm_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  rtm_series <- calculateRelAccr(rtm_series,
                                 exp_,
                                 model_class = 'lm')

  saveRDS(rtm_index,
          file = file.path(getwd(), 'data', 'exp_10', 'rtm_index.RDS'))
  saveRDS(rtm_series,
          file = file.path(getwd(), 'data', 'exp_10', 'rtm_series.RDS'))
  
### Submarketing -----------------------------------------------------------------------------------  
  
  exp_$sms <- 'submarket'
  exp_$partition <- names(table(exp_$hed_df$submarket))
  exp_$partition_field <- 'submarket'
  exp_$ind_var <- c('grade', 'age', 'sqft', 'beds', 'baths', 'sqft_lot')
  
  rtm_subm_ <- purrr::map(.x = exp_$partition,
                          .f = rtWrapper,
                          exp_obj = exp_)
  
  rtm_sub_obj <- unwrapPartitions(rtm_subm_)
  
  saveRDS(rtm_sub_obj,
          file = file.path(getwd(), 'data', 'exp_10', 'rtm_submarket.RDS'))
  
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