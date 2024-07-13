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

### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  nnindex_df <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_nn_results_py.csv'))
  py_rawser <- read.csv(file = file.path(getwd(), 'data', exp, 
                                         'exp_nn_series_results_py.csv'))
  #sub_rawser <- read.csv(file = file.path(getwd(), 'data', exp, 
  #                                       'exp_nn_series_submarkets_local_results_py.csv'))
  sub_rawser <- read.csv(file = file.path(getwd(), 'data', exp, 
                                         'exp_nn_series_submarkets_global_results_py.csv'))
  
  
  # Read in the median index and series to get general structure of existing indexes
  med_index <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'med_index.RDS'))
  med_series <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'med_series.RDS'))
  
### Neural Index ----------------------------------------------------------------  

  #### NN Index -----
  nn_index <- structure(
    list(data = NULL,
    model = list(estimator = 'znn',
                                mod_spec = NULL,
                                approach = 'nn', 
                                log_dup = TRUE,
                                coefficents =  nnindex_df %>%
                                  dplyr::filter(time == 10 & model == 'nn') %>%
                                  dplyr::select(time_period = time,
                                                coefficient = value) %>%
                                  dplyr::mutate(coefficient = (coefficient / 100) - 1)),
                   index = list(name = med_index$index$name,
                                period = med_index$index$period,
                                value = ts(nnindex_df %>%
                                             dplyr::filter(time == 10 & model == 'nn') %>%
                                             dplyr::select(value) %>%
                                             unlist() %>%
                                             as.numeric(), 1, 120),
                                imputed = rep(0, 120))),
    class = 'hpi') %>%
    ind2stl(.)
  nn_index$model$class <- 'tme'

### Series
  
  nn_series <- structure(
    list(data = data.frame(),
         hpis = med_series$hpis),
    class = 'serieshpi')
  
  tp <- unique(py_rawser$train_period)
  tpi <- tp - (min(tp) - 1)  
  for (i in tpi){
    nn_df <- py_rawser %>%
      dplyr::filter(train_period == tp[i]) %>%
      dplyr::arrange(period)
    
    nn_series$hpis[[i]]$index$value <- ts(nn_df$value)
  }
  
  nn_series <- calcRevision(series_obj = nn_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  nn_series <- calcSeriesAccuracy(series_obj = nn_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  nn_series <- calculateRelAccr(nn_series,
                                exp_)
  
  #### Write out -----------
  
  saveRDS(nn_index,
          file = file.path(getwd(), 'data', 'exp_10', 'nn_index.RDS'))
  saveRDS(nn_series,
          file = file.path(getwd(), 'data', 'exp_10', 'nn_series.RDS'))

### Submarkets --------------    
  
  subms <- split(sub_rawser, sub_rawser$partition)
  ss <- names(subms)
  for (i in 1:length(ss)){ss[i] <- gsub('submarket_', '', ss[i])}
  subms_ <- list()
  exp_$partition_field <- 'submarket'
  
  for (j in 1:length(subms)){
    
    partition <- names(subms)[j]
    partition <- gsub('submarket_', '', partition)
    cat('Submarket:', partition, '\n\n')
    
    exp_obj <- dataFilter(exp_, partition)
    
    
    x_series <- subms[[j]]
    nn_series <- structure(
      list(data = data.frame(),
           hpis = med_series$hpis),
      class = 'serieshpi')
    
    tp <- unique(x_series$train_period)
    tpi <- tp - (min(tp) - 1)  
    nn_index <- NULL
    for (i in tpi){
      nn_df <- x_series %>%
        dplyr::filter(train_period == tp[i]) %>%
        dplyr::arrange(period)
      
      nn_series$hpis[[i]]$index$value <- ts(nn_df$value)
      if (i == max(tpi)){
        nn_index <- nn_series$hpis[[i]]
        nn_stl <- ind2stl(nn_index)$stl
        nn_index <- nn_index$index
      }
    }
    
    nn_series <- calcRevision(series_obj = nn_series,
                              in_place = TRUE,
                              in_place_name = 'revision')
    nn_series <- calcSeriesAccuracy(series_obj = nn_series,
                                    test_method = 'forecast',
                                    test_type = 'rt',
                                    pred_df = exp_obj$rt_df,
                                    smooth = FALSE,
                                    in_place = TRUE,
                                    in_place_name = 'pr_accuracy')
    nn_hedaccr <- list()
    for (ti in 1:(length(nn_series$hpis)-1)) {
      nn_hedaccr[[ti]] <- getHedFitAccuracy(nn_series$hpis[[ti]],
                                             exp_obj)
    }
    nn_series$hed_praccr <- dplyr::bind_rows(nn_hedaccr)
    subms_[[j]] <- list(index = nn_index,
                        stl = nn_stl,
                        series = nn_series)
        
  }
  
  nnm_sub_ <- list()
  
  nnm_sub_$index <- purrr::map(.x = subms_,
                               .f = function(x){
                                 x$index
                               })
  
  nnm_sub_$stl <- purrr::map(.x = subms_,
                             .f = function(x){
                               x$stl
                             }) %>%
    dplyr::bind_rows()
  
  nnm_sub_$revision <- 
    purrr::map(.x = subms_,
               .f = function(x){
                 data.frame(median = x$series$revision$median,
                            mean = x$series$revision$mean,
                            abs_median = x$series$revision$abs_median,
                            abs_mean = x$series$revision$abs_mean)}) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(submarket = ss)
  
  
  nnm_sub_$absacc <- purrr::map(.x = subms_,
                                .f = function(x){
                                  x$series$pr_accuracy
                                }) %>%
    dplyr::bind_rows()
  
  nnm_sub_$relacc <- purrr::map(.x = subms_,
                                .f = function(x){
                                  x$series$hed_praccr
                                }) %>%
    dplyr::bind_rows()
  
  saveRDS(nnm_sub_,
          file = file.path(getwd(), 'data', 'exp_10', 'nnm_submarket.RDS'))
  
  
  
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~