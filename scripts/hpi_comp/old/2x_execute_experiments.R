#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run experiments, save raw outputs
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  ## Load libraries

  library(tidyverse)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

  ## Load custom functions  
  source(file.path(getwd(), 'functions', 'wrapper_function.R'))

### 5 Year Time Frame ------------------------------------------------------------------------------  

  # Set Experiment Setup to use
  exp <- 'exp_5'

  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

  # Set Models
  models <- c('rt', 'hed', 'rf')
  
#### Full County ------------------------------------------
  
  exp_$partition <- 'all'
  
  ## Loop through models
  for(mod in models){
   
    cat('------', mod, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = exp_$partition, 
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }

#### By Submarket -----------------------------------------
  
  exp_$partition_field <- 'submarket'
  partitions <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
                  'O', 'P', 'Q', 'R', 'S')
  
  # Update ind var to not use submarket
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  ## Loop through models
  for(mod in models){
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition_field, '-----------------\n')
    exp_$model <- mod
    results_obj <- purrr::map(.x = partitions,
                              .f = expWrapper,
                              exp_obj = exp_,
                              estimator = 'base', 
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
  
#### By Area -----------------------------------------
  
  area_df <- exp_$hed_df %>%
    dplyr::group_by(area) %>%
    dplyr::summarize(area_count = dplyr::n()) %>%
    dplyr::mutate(area_label = ifelse(area_count > 700, as.numeric(area), 0))
  
  exp_$hed_df <- exp_$hed_df %>%
    dplyr::left_join(., area_df, by = 'area')
  
  # exp_$rt_df <- exp_$rt_df %>%
  #   dplyr::left_join(., exp_$hed_df %>%
  #                      dplyr::select(trans_id, area_label), 
  #                    by = c('trans_id1' = 'trans_id'))
  # 
  # 
  exp_$partition_field <- 'area_label'
  partitions <- area_df$area_label
  
  # Update ind var to not use submarket
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  ## Loop through models
  for(mod in models){
    
    exp_$model <- mod
    cat('------', mod, '---', exp_$time, '---', exp_$partition_field, '-----------------\n')
    results_obj <- purrr::map(.x = partitions,
                              .f = expWrapper,
                              exp_obj = exp_,
                              estimator = 'base',
                              index_only = FALSE) %>%
      suppressWarnings()
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
  
### 10 Year Time Frame ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  # Set Models
  models <- c('rt', 'hed', 'rf')
  
#### Full County ------------------------------------------
  
  exp_$partition <- 'all'
  
  ## Loop through models
  for(mod in models){
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = exp_$partition, 
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }
  
#### By Submarket -----------------------------------------
  
  exp_$partition_field <- 'submarket'
  partitions <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
                  'O', 'P', 'Q', 'R', 'S')
  
  # Update ind var to not use submarket
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  ## Loop through models
  for(mod in models){
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition_field, '-----------------\n')
    exp_$model <- mod
    results_obj <- purrr::map(.x = partitions,
                              .f = expWrapper,
                              exp_obj = exp_,
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
  
### 20 Year Time Frame ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_20'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  # Set Models
  models <- c('rt', 'hed', 'rf')
  
#### Full County ------------------------------------------
  
  exp_$partition <- 'all'
  
  ## Loop through models
  for(mod in models){
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = exp_$partition, 
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }
  
#### By Submarket -----------------------------------------
  
  exp_$partition_field <- 'submarket'
  partitions <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
                  'O', 'P', 'Q', 'R', 'S')
  
  # Update ind var to not use submarket
  exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                   'latitude', 'longitude')
  
  ## Loop through models
  for(mod in models){
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition_field, '-----------------\n')
    exp_$model <- mod
    results_obj <- purrr::map(.x = partitions,
                              .f = expWrapper,
                              exp_obj = exp_,
                              index_only = FALSE)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  