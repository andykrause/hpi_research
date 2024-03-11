#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, median index analyses
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Load libraries

  library(tidyverse)
  library(kingCoData)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

 ## Load custom functions  
  
  source(file.path(getwd(), 'functions', 'wrapper_function.R'))

### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

### Base Index + Series -----------
  
  #### Med Index -----
  med_index <- aggIndex(trans_df = exp_$hed_df,
                        estimator = 'median') %>%
    ind2stl(.)
  
  med_index$model$approach <- 'agg'
  med_index$model$class <- 'agg'
  
  #### Med Series -----------
  
  med_series <- createSeries(hpi_obj = med_index,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE) %>%
    suppressWarnings()
  
  med_series <- calcRevision(series_obj = med_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  #### Accuracy ----------
  
  med_series <- calcSeriesAccuracy(series_obj = med_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  med_series <- calculateRelAccr(med_series,
                                 exp_)
  
  #### Write out -----------
  
  saveRDS(med_index,
          file = file.path(getwd(), 'data', 'exp_10', 'med_index.RDS'))
  saveRDS(med_series,
          file = file.path(getwd(), 'data', 'exp_10', 'med_series.RDS'))
  
### Submarketing -----------------------------------------------------------------------------------  

  exp_$sms <- 'submarket'
  exp_$partition <- names(table(exp_$hed_df$submarket))
  exp_$partition_field <- 'submarket'
  exp_$ind_var <- c('grade', 'age', 'sqft', 'beds', 'baths', 'sqft_lot', 'use', 
                    'latitude', 'longitude')
  
  #### Estimate All ------------
  
  med_subm_ <- purrr::map(.x = exp_$partition,
                          .f = aggWrapper,
                          exp_obj = exp_)
  
  med_sub_obj <- unwrapPartitions(med_subm_)
  
  #### Write Out -----------------
  
  saveRDS(med_sub_obj,
          file = file.path(getwd(), 'data', 'exp_10', 'med_submarket.RDS'))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  
  
# ### Sampling Differences
#   