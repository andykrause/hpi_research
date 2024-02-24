#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, series only results
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

  # Data
  homes_df <- readRDS(file = file.path(getwd(), 'data', 'kinghomes_df.RDS'))
  indexes_ <- readRDS(file.path(getwd(), 'data', exp, 'indexes.RDS'))
  py_rawser <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_results_py_nn_10year_series.csv'))
  
### Set Parameters ------------------------------------------------------------------------------  
  
  # Set Parameters
  vol_window <- 3
  
  ## Create imputation data set
  uni_df <- homes_df %>%
    dplyr::sample_frac(., .1)
  
### Aggregate Series ----------------------------------------------------------------  
  
  indexes_$med$model$approach <- 'agg'
  med_series <- createSeries(hpi_obj = indexes_$med,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE) %>%
  suppressWarnings()

  indexes_$ppsf$model$approach <- 'agg'
  ppsf_series <- createSeries(hpi_obj = indexes_$ppsf,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE,
                             price_field = 'ppsf') %>%
    suppressWarnings()
  
### TME Series ---------------------------------------------------------------------------------  
  
  hed_series <- createSeries(hpi_obj = indexes_$hed,
                              train_period = exp_$train_period,
                              max_period = max(exp_$hed_df$trans_period),
                              smooth = TRUE, 
                              slim = TRUE) %>%
    suppressWarnings()
  
  rt_series <- createSeries(hpi_obj = indexes_$rt,
                             train_period = exp_$train_period,
                             max_period = max(exp_$hed_df$trans_period),
                             smooth = TRUE, 
                             slim = TRUE) %>%
    suppressWarnings()
  
  nn_series <- structure(
    list(data = data.frame(),
         hpis = rfimp_series$hpis),
    class = 'serieshpi')
  
  tp <- unique(py_rawser$train_period)
  tpi <- tp - (min(tp) - 1)  
  for (i in tpi){
    nn_df <- py_rawser %>%
      dplyr::filter(train_period == tp[i]) %>%
      dplyr::arrange(period)
    
    nn_series$hpis[[i]]$index$value <- ts(nn_df$value)
  }
  
### Imputation Series -------------------------------------------------------------------------  
  
  indexes_$hedimp$model$approach <- 'hed'
  hedimp_series <- createSeries(hpi_obj = indexes_$hedimp,
                            train_period = exp_$train_period,
                            max_period = max(exp_$hed_df$trans_period),
                            smooth = TRUE, 
                            slim = TRUE,
                            sim_df = exp_$hed_df %>%
                              dplyr::filter(submarket != 'H')) %>%
    suppressWarnings()
  
  indexes_$rfimp$model$approach <- 'rf'
  rfimp_series <- createSeries(hpi_obj = indexes_$rfimp,
                                train_period = exp_$train_period,
                                max_period = max(exp_$hed_df$trans_period),
                                smooth = TRUE, 
                                slim = TRUE,
                                sim_df = exp_$hed_df) %>%
    suppressWarnings()
  
### Calculate Revisions ---------------------------------------------------------------  
  
  ## Agg
  
  med_series <- calcRevision(series_obj = med_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  ppsf_series <- calcRevision(series_obj = ppsf_series,
                              in_place = TRUE,
                              in_place_name = 'revision')
  hed_series <- calcRevision(series_obj = hed_series,
                              in_place = TRUE,
                              in_place_name = 'revision')
  rt_series <- calcRevision(series_obj = rt_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  nn_series <- calcRevision(series_obj = nn_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  hedimp_series <- calcRevision(series_obj = hedimp_series,
                                in_place = TRUE,
                                in_place_name = 'revision')
  rfimp_series <- calcRevision(series_obj = rfimp_series,
                               in_place = TRUE,
                               in_place_name = 'revision')
  
 ## Calculate Absolute Accuracy  
  
  med_series <- calcSeriesAccuracy(series_obj = med_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  ppsf_series <- calcSeriesAccuracy(series_obj = ppsf_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  hed_series <- calcSeriesAccuracy(series_obj = hed_series,
                                    test_method = 'forecast',
                                    test_type = 'rt',
                                    pred_df = exp_$rt_df,
                                    smooth = FALSE,
                                    in_place = TRUE,
                                    in_place_name = 'pr_accuracy')
  rt_series <- calcSeriesAccuracy(series_obj = rt_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  nn_series <- calcSeriesAccuracy(series_obj = nn_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  hedimp_series <- calcSeriesAccuracy(series_obj = hedimp_series,
                                      test_method = 'forecast',
                                      test_type = 'rt',
                                      pred_df = exp_$rt_df,
                                      smooth = FALSE,
                                      in_place = TRUE,
                                      in_place_name = 'pr_accuracy')
  rfimp_series <- calcSeriesAccuracy(series_obj = rfimp_series,
                                     test_method = 'forecast',
                                     test_type = 'rt',
                                     pred_df = exp_$rt_df,
                                     smooth = FALSE,
                                     in_place = TRUE,
                                     in_place_name = 'pr_accuracy')
  
  
  med_series <- calculateRelAccr(med_series,
                                 exp_)
  ppsf_series <- calculateRelAccr(ppsf_series,
                                  exp_)
  
  hed_series <- calculateRelAccr(hed_series,
                                  exp_)
  rt_series <- calculateRelAccr(rt_series,
                                 exp_)
  nn_series <- calculateRelAccr(nn_series,
                                exp_)
  hedimp_series <- calculateRelAccr(hedimp_series,
                                    exp_)
  rfimp_series <- calculateRelAccr(rfimp_series,
                                   exp_)
  
  
  
  
  