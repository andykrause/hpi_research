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
  hei_index <- hedIndex(trans_df = exp_$hed_df,
                        estimator = 'impute',
                        log_dep = TRUE,
                        dep_var = 'price',
                        ind_var = exp_$ind_var,
                        trim_model = TRUE,
                        max_period = max(exp_$hed_df$trans_period),
                        smooth = FALSE,
                        sim_df = uni_df) %>%
    ind2stl(.)
  
  hei_index$model$class <- 'imp'
  hei_index$model$approach <- 'hed'
  
  hei_series <- createSeries(hpi_obj = hei_index,
                                train_period = exp_$train_period,
                                max_period = max(exp_$hed_df$trans_period),
                                smooth = TRUE, 
                                slim = TRUE,
                                sim_df = uni_df) %>%
    suppressWarnings()
  
  hei_series <- calcRevision(series_obj = hei_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  hei_series <- calcSeriesAccuracy(series_obj = hei_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  hei_series <- calculateRelAccr(hei_series,
                                 exp_)
  hei_index$model$approach <- 'hei'
  
  saveRDS(hei_index,
          file = file.path(getwd(), 'data', 'exp_10', 'hei_index.RDS'))
  saveRDS(hei_series,
          file = file.path(getwd(), 'data', 'exp_10', 'hei_series.RDS'))
  
    
### Submarketing -----------------------------------------------------------------------------------  

  exp_$sms <- 'submarket'
  exp_$partition <- names(table(exp_$hed_df$submarket))
  exp_$partition_field <- 'submarket'
  exp_$ind_var <- c('grade', 'age', 'sqft', 'beds', 'baths', 'sqft_lot', 'use', 
                    'latitude', 'longitude')
  
  hei_subm_ <- purrr::map(.x = exp_$partition,
                          .f = hedWrapper,
                          exp_obj = exp_,
                          estimator = 'impute',
                          sim_df = uni_df)
  
  hei_sub_obj <- unwrapPartitions(hei_subm_)
  
  saveRDS(hei_sub_obj,
          file = file.path(getwd(), 'data', 'exp_10', 'hei_submarket.RDS'))
  
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