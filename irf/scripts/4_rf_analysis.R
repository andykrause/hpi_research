library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

source(file.path(getwd(), 'irf', 'scripts', 'wrapper_function.R'))

exp = 'exp_5'
exp_ <- readRDS(file=file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

## All King County

  # Five Year
  rf_5 <- rfWrapper(exp_obj = exp_,
                    sim_per = .05,
                    ntrees = 100,
                    estimator = 'pdp')

  saveRDS(rf_5, file = file.path(getwd(), 'data', exp_$name, paste0('rf_results_obj.RDS')))
  
  rm(rf_5)
  gc()
  
  ### Submarket
  
  subm <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
            'O', 'P', 'Q', 'R', 'S')
  
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  rf_subm_ <- list()
  
  for (i in subm){
    
    x_obj <- exp_
    
    ss_ids <- x_obj$hed_df %>%
      dplyr::filter(submarket == x) %>%
      dplyr::select(trans_id)
    
    x_obj$rt_df <- x_obj$rt_df %>%
      dplyr::filter(trans_id1 %in% ss_ids$trans_id)
    x_obj$hed_df <- x_obj$hed_df %>%
      dplyr::filter(trans_id %in% ss_ids$trans_id)
    rf_ <- rfWrapper(exp_obj = x_obj)
    rf_$subm <- x
    rf_subm_[[i]] <- rf_
  }
  
  saveRDS(rf_subm_, file = file.path(getwd(), 'data', exp_$name, paste0('rf_subm_results_obj.RDS')))
  
  