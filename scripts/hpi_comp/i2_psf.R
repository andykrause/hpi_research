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
  
### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

### Base Index + Series -----------
  
  #### PSF Index -----
  psf_index <- aggIndex(trans_df = exp_$hed_df,
                        estimator = 'median',
                        price_field = 'ppsf') %>%
    ind2stl(.)
  
  psf_index$model$approach <- 'agg'
  psf_index$model$class <- 'agg'
  
  #### PSF Series ------------
  
  psf_series <- createSeries(hpi_obj = psf_index,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE,
                             price_field = 'ppsf') %>%
    suppressWarnings()
  
  psf_series <- calcRevision(series_obj = psf_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  #### Accuracy ---------
  
  psf_series <- calcSeriesAccuracy(series_obj = psf_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  psf_series <- calculateRelAccr(psf_series,
                                 exp_,
                                 model_class = 'lm')

  #### Write Out -----------
  
  saveRDS(psf_index,
          file = file.path(getwd(), 'data', 'exp_10', 'psf_index.RDS'))
  saveRDS(psf_series,
          file = file.path(getwd(), 'data', 'exp_10', 'psf_series.RDS'))
  
### Submarketing -----------------------------------------------------------------------------------  
  
  exp_$sms <- 'submarket'
  exp_$partition <- names(table(exp_$hed_df$submarket))
  exp_$partition_field <- 'submarket'
  exp_$ind_var <- c('grade', 'age', 'sqft', 'beds', 'baths', 'sqft_lot')
  
  #### Create Index and Series ----------
  psf_subm_ <- purrr::map(.x = subm,
                          .f = aggWrapper,
                          exp_obj = exp_,
                          price_field = 'ppsf')
  
  psf_sub_obj <- unwrapPartitions(psf_subm_)
  
  #### Write Out ----------------
  saveRDS(psf_sub_obj,
          file = file.path(getwd(), 'data', 'exp_10', 'psf_submarket.RDS'))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
# ### Sampling Differences
#   