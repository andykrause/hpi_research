#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Extract and Compile all results
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Load libraries

  library(tidyverse)
  library(kingCoData)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

 ## Load custom functions  

 source(file.path(getwd(), 'functions', 'wrapper_function.R'))

  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  
 ## Set Class:Approach Mapping

 class_df <- data.frame(class = c('agg', 'agg', 'tme', 'tme', 'tme', 'imp', 'imp'),
                        approach = c('med', 'psf', 'hem', 'rtm', 'nnm', 'hei', 'rfi'))
 
 ## Set Colors
 color_df <- data.frame(approach = c('med', 'psf', 'hem', 'rtm', 'nnm', 'hei', 'rfi'),
                        colorx = c('navy', 'dodgerblue', 'red', 'orange4', 'orange', 
                                   'green4', 'limegreen'))

### Extract Index Data ---------------------------------------------------------------------

 ## Read in all indexes
  indexes_ <- list(med = readRDS(file.path(getwd(), 'data', 'exp_10', 'med_index.RDS')),
                   psf = readRDS(file.path(getwd(), 'data', 'exp_10', 'psf_index.RDS')),
                   hem = readRDS(file.path(getwd(), 'data', 'exp_10', 'hem_index.RDS')),
                   rtm = readRDS(file.path(getwd(), 'data', 'exp_10', 'rtm_index.RDS')),
                   nnm = readRDS(file.path(getwd(), 'data', 'exp_10', 'nn_index.RDS')),
                   hei = readRDS(file.path(getwd(), 'data', 'exp_10', 'hei_index.RDS')),
                   rfi = readRDS(file.path(getwd(), 'data', 'exp_10', 'rfi_index.RDS')))

  ## Convert to a data.frame
  index_df <- indexes2df(index_list = indexes_,
                         time_length = 10) %>%
    dplyr::select(-class) %>%
    dplyr::mutate(approach = ifelse(approach == 'agg', 'med', approach)) %>%
    dplyr::mutate(approach = ifelse(approach == 'hed', 'hem', approach)) %>%
    dplyr::mutate(approach = ifelse(approach == 'rt', 'rtm', approach)) %>%
    dplyr::mutate(approach = ifelse(approach == 'nn', 'nnm', approach)) %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::select(class, method = approach, time_period, month, index, MoM,
                  trend, seasonal, remainder, time)

  ## Save
  
  saveRDS(index_df,
          file = file.path(getwd(), 'data', 'exp_10', 'results_index.RDS'))

### Extract Series Data --------------------------------------------------------------

  ## Load the Raw series data
  series_ <- list(med = readRDS(file.path(getwd(), 'data', 'exp_10', 'med_series.RDS')),
                  psf = readRDS(file.path(getwd(), 'data', 'exp_10', 'psf_series.RDS')),
                  hem = readRDS(file.path(getwd(), 'data', 'exp_10', 'hem_series.RDS')),
                  rtm = readRDS(file.path(getwd(), 'data', 'exp_10', 'rtm_series.RDS')),
                  nnm = readRDS(file.path(getwd(), 'data', 'exp_10', 'nn_series.RDS')),
                  hei = readRDS(file.path(getwd(), 'data', 'exp_10', 'hei_series.RDS')),
                  rfi = readRDS(file.path(getwd(), 'data', 'exp_10', 'rfi_series.RDS')))

  ## Approaches
  
  approaches <- names(series_)
 
  ## Create a blank list of all the results
  
  seriesres_ <- list()

#### Series Revisions --------------------
  
  seriesres_$rev_df <- purrr::map2(.x = series_,
                                   .y = approaches,
                                   .f = function(x, y){
                                      data.frame(approach = y,
                                      median = x$revision$median,
                                      mean = x$revision$mean,
                                      abs_median = x$revision$abs_median,
                                      abs_mean = x$revision$abs_mean)
                                    }) %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(2:5, round, 3)) %>%
    dplyr::select(class, method = approach, median, abs_median, mean, abs_mean)
  
#### Absolute Accr (Repeat Trans) --------
  
  seriesres_$abs_df <- 
    purrr::map2(.x = series_,
                .y = approaches,
                .f = function(x, y){
                    x$pr_accuracy %>%
                      dplyr::mutate(approach = y)}) %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(3, round, 0)) %>%
    dplyr::mutate(across(4:5, round, 3)) %>%
    dplyr::select(class, method = approach, pair_id, pred_period, rt_price, pred=pred_price,
                  error, log_error)  

#### Rel accr (AVM Adj) --------
  seriesres_$rel_df <- 
    purrr::map2(.x = series_,
                .y = approaches,
                .f = function(x, y){
                   x$rel_accuracy %>%
                     dplyr::mutate(approach = y)}) %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(3, round, 0)) %>%
    dplyr::mutate(across(6, round, 3)) %>%
    dplyr::select(class, method = approach, trans_id, trans_period, 
                  price, pred=prediction, type, error)

  ## Save
  saveRDS(seriesres_,
          file = file.path(getwd(), 'data', 'exp_10', 'results_series.RDS'))
  
    
### By Submarket -------------------------------------------------------------------------  
  
  ## Load raw data
  subm_ <- list(med = readRDS(file.path(getwd(), 'data', 'exp_10', 'med_submarket.RDS')),
                psf = readRDS(file.path(getwd(), 'data', 'exp_10', 'psf_submarket.RDS')),
                hem = readRDS(file.path(getwd(), 'data', 'exp_10', 'hem_submarket.RDS')),
                nnm = readRDS(file.path(getwd(), 'data', 'exp_10', 'nnm_submarket.RDS')),
                rtm = readRDS(file.path(getwd(), 'data', 'exp_10', 'rtm_submarket.RDS')),
                hei = readRDS(file.path(getwd(), 'data', 'exp_10', 'hei_submarket.RDS')),
                rfi = readRDS(file.path(getwd(), 'data', 'exp_10', 'rfi_submarket.RDS')))
  
  ## Approaches
  
  approaches <- names(subm_)
  subms <- names(table(exp_$hed_df$submarket))
  
  ## Create a blank list of all the results
  
  submres_ <- list()
  
  ## Extract indexes
  x_ <- list()
  for (i in approaches){
    xx <- subm_[[i]]$index
    purrr::map2(.x = xx,
                .y = subms,
                .f = function(x, y){
                 data.frame(time_period = x$period,
                            month = x$name,
                            index = as.numeric(x$value),
                            subm = y)}) %>%
      dplyr::bind_rows() %>%
      dplyr::mutate(approach = i) -> x_[[i]]
  }
  submres_$index_df <- x_ %>% dplyr::bind_rows()
  
  ## Extract STL  
  x_ <- list()
  for (i in approaches){
    xx <- subm_[[i]]$stl
    xx$approach <- i
    xx$subm <- sort(rep(subms, 120))
    x_[[i]] <- xx
  }
  submres_$stl_df <- x_ %>% dplyr::bind_rows()
  
  ## Extract Revisions
  x_ <- list()
  for (i in approaches){
    xx <- subm_[[i]]$revision
    xx$approach <- i
    xx$subm <- subms
    x_[[i]] <- xx
  }
  submres_$rev_df <- x_ %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(1:4, round, 3)) %>%
    dplyr::select(class, method = approach, median, abs_median, mean, abs_mean)
  
  ## Absolute Accuracy
  x_ <- list()
  for (i in approaches){
    xx <- as.data.frame(subm_[[i]]$absacc)
    xx$approach <- i
    xx <- xx %>%
      dplyr::left_join(., 
                       exp_$rt_df %>% dplyr::select(pair_id, trans_id2),
                       by = 'pair_id') %>%
      dplyr::left_join(., 
                       exp_$hed_df %>% dplyr::select(trans_id2 = trans_id, submarket),
                       by = 'trans_id2')
    x_[[i]] <- xx
  }
  submres_$abs_df <- x_ %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(3, round, 0)) %>%
    dplyr::mutate(across(4:5, round, 3)) %>%
    dplyr::select(class, method = approach, submarket, pair_id, pred_period, rt_price, 
                  pred=pred_price, error, log_error)  
  
  ## Relative Accuracy
  x_ <- list()
  for (i in approaches){
    xx <- as.data.frame(subm_[[i]]$relacc)
    xx$approach <- i
    xx <- xx %>%
      dplyr::left_join(., 
                       exp_$hed_df %>% dplyr::select(trans_id, submarket),
                       by = 'trans_id')
    x_[[i]] <- xx
  }
  submres_$rel_df <- x_ %>% 
    dplyr::bind_rows() %>%
    dplyr::left_join(., class_df, by = 'approach') %>%
    dplyr::mutate(across(3, round, 0)) %>%
    dplyr::mutate(across(6, round, 3)) %>%
    dplyr::select(class, submarket, method = approach, trans_id, trans_period, 
                  price, pred=prediction, type, error)
  
  ## Save
  saveRDS(submres_,
          file = file.path(getwd(), 'data', 'exp_10', 'results_submarket.RDS'))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  
 