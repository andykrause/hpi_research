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
  nnindex_df <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_results_py.csv'))
  py_rawser <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_results_py_nn_10year_series.csv'))
  
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
  
  
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~