#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#. Run a hedonic (sales) experiment
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Set Experiment Setup to use

  exp <- 'exp_20'

 # Read in experiment object
  exp_ <- readRDS(file=file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

  ## Load libraries

  library(tidyverse)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

  ## Load custom functions  
  source(file.path(getwd(), 'irf', 'scripts', 'wrapper_function.R'))

### Run analysis for each submarket -----------------------------------------------------------------

  ## All King County

  exp_obj$sms <- 'all'

  
  
  # Five Year
  hed_obj <- hedWrapper(exp_obj = exp_,)

  saveRDS(hed_obj, file = file.path(getwd(), 'data', exp_$name, paste0('hed_results_obj.RDS')))
  
  rm(hed_obj)
  gc()
  
  ### Submarket
  
  subm <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
            'O', 'P', 'Q', 'R', 'S')
  
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  he_subm_ <- list()
  
  for (i in subm){
    
    x_obj <- exp_
    
    ss_ids <- x_obj$hed_df %>%
      dplyr::filter(submarket == x) %>%
      dplyr::select(trans_id)
    
    x_obj$rt_df <- x_obj$rt_df %>%
      dplyr::filter(trans_id1 %in% ss_ids$trans_id)
    x_obj$hed_df <- x_obj$hed_df %>%
      dplyr::filter(trans_id %in% ss_ids$trans_id)
    he_ <- hedWrapper(exp_obj = x_obj)
    he_$subm <- x
    he_subm_[[i]] <- he_
  }
  
  saveRDS(he_subm_, file = file.path(getwd(), 'data', exp_$name, paste0('he_subm_results_obj.RDS')))
  
  
  
   