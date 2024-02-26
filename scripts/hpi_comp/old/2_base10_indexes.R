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
  
### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  py_df <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_results_py.csv'))
  
  # Set Parameters
  vol_window <- 3
  
  ## Create imputation data set
  uni_df <- homes_df %>%
    dplyr::sample_frac(., .1)
  
### Aggregate Indexes ----------------------------------------------------------------  

  #### Agg Index -----
  med_index <- aggIndex(trans_df = exp_$hed_df,
                        estimator = 'median') %>%
    ind2stl(.)
  med_index$model$approach <- 'median_price'
  med_index$model$class <- 'agg'
  
  #### PPSF Index -----
  ppsf_index <- aggIndex(trans_df = exp_$hed_df,
                         estimator = 'median',
                         price_field = 'ppsf') %>%
    ind2stl(.)
  ppsf_index$model$approach <- 'median_ppsf'
  ppsf_index$model$class <- 'agg'
  
### Extraction Indexes ---------------------------------------------------------------------  
  
  #### RT Index -----
  rt_index <- rtIndex(trans_df = exp_$rt_df,
                      estimator = 'robust',
                      log_dep = TRUE,
                      max_period = max(exp_$rt_df$period_2)) %>%
    ind2stl(.)
  rt_index$model$class <- 'tme'
  
  #### Hed Index -----
  hed_index <- hedIndex(trans_df = exp_$hed_df,
                        estimator = 'robust',
                        log_dep = TRUE,
                        dep_var = 'price',
                        ind_var = exp_$ind_var,
                        trim_model = TRUE,
                        max_period = max(exp_$hed_df$trans_period),
                        smooth = FALSE)%>%
    ind2stl(.)
  hed_index$model$class <- 'tme'
  
  #### NN Index -----
  nn_index <- structure(
    list(data = NULL,
    model = list(estimator = 'znn',
                                mod_spec = NULL,
                                approach = 'nn', 
                                log_dup = TRUE,
                                coefficents =  py_df %>%
                                  dplyr::filter(time == 10 & model == 'nn') %>%
                                  dplyr::select(time_period = time,
                                                coefficient = value) %>%
                                  dplyr::mutate(coefficient = (coefficient / 100) - 1)),
                   index = list(name = med_index$index$name,
                                period = med_index$index$period,
                                value = ts(py_df %>%
                                             dplyr::filter(time == 10 & model == 'nn') %>%
                                             dplyr::select(value) %>%
                                             unlist() %>%
                                             as.numeric(), 1, 120),
                                imputed = rep(0, 120))),
    class = 'hpi') %>%
    ind2stl(.)
  nn_index$model$class <- 'tme'
  
### Imputation Indexes ---------------------------------------------------------------------  
  
  #### Hed Index -----
  hedimp_index <- hedIndex(trans_df = exp_$hed_df,
                   estimator = 'impute',
                   log_dep = TRUE,
                   dep_var = 'price',
                   ind_var = exp_$ind_var,
                   trim_model = TRUE,
                   max_period = max(exp_$hed_df$trans_period),
                   smooth = FALSE,
                   sim_df = exp_$hed_df %>%
                     dplyr::filter(submarket != 'H')) %>%
    ind2stl(.)
  hedimp_index$model$approach <- 'ols_imp'
  hedimp_index$model$class <- 'imp'
  
  #### RF Index -----
  rfimp_index <- rfIndex(trans_df = exp_$hed_df,
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
                always.split.variables = 
                  exp_$rf_par$always_split_variables,
                sim_df = uni_df)%>%
    ind2stl(.)
  rfimp_index$model$approach <- 'rf_imp'
  rfimp_index$model$class <- 'imp'
  
### Extract and Save ---------------------------------------------------------------------  
  
 ## Extract all index objects  
  
  idx <- ls()[grepl('_index', ls())]
  indexes_ <- list()
  index_names <- lapply(idx, function(x) {strsplit(x, '_')[1]}) %>%
    unlist()
  index_names <- index_names[index_names != 'index']
  
  for (i in 1:length(idx)){
    indexes_[[i]] <- get(idx[i])
  }
  names(indexes_) <- index_names
  
  # Into a data.frame
  index_df <- indexes2df(index_list = indexes_,
                         time_length = 10)
  
  # Add Sample Label
  index_df$sample <- 'full'
  
  # Save index data.frame
  saveRDS(index_df,
          file = file.path(getwd(), 'data', 'exp_10', 'indexes_df.RDS'))
  
  # Save Indexes
  saveRDS(indexes_,
          file = file.path(getwd(), 'data', 'exp_10', 'indexes.RDS'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~