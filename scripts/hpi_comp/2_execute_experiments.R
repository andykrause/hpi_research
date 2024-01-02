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

### All King County @ 5 Years ----------------------------------------------------------------------  

  # Set Experiment Setup to use
  exp <- 'exp_5'

  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
 ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
  models <- 'rf'
  partition <- 'all'
  
  exp_$partition <- partition
  exp_$min_bucket <- 5
  exp_$always_split_variables <- 'trans_period'
  exp_$ntrees <- 100
  exp_$sim_per <- .01
  
  ## Loop through models
  for(mod in models){
   
    
    cat('------', mod, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = 'all')
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  

### All King County @ 10 Years ----------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
  models <- c('rf')
  partition <- 'all'
  
  exp_$partition <- partition
  exp_$min_bucket <- 5
  exp_$always_split_variables <- 'trans_period'
  exp_$ntrees <- 100
  exp_$sim_per <- .01
  
  ## Loop through models
  for(mod in models){
    
    cat('------', exp_$model, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = 'all')
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
  
### All King County @ 20 Years ----------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_20'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
  partition <- 'all'
  
  exp_$partition <- partition
  
  ## Loop through models
  for(mod in models){
    
    cat('------', exp_$model, '---', exp_$time, '---', exp_$partition, '-----------------\n')
    exp_$model <- mod
    results_obj <- expWrapper(exp_obj = exp_,
                              partition = 'all')
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition, '_results.RDS')))
  }
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
### Subarkets @ 5 Years ----------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_5'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
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
                              exp_obj = exp_)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
    
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
### Subarkets @ 10 Years ----------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
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
                              exp_obj = exp_)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  
### Subarkets @ 20 Years ----------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_20'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  ## Run analysis for each submarket -
  
  models <- c('rt', 'hed', 'rf')
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
                              exp_obj = exp_)
    
    cat('.Saving Results\n')
    saveRDS(results_obj, 
            file = file.path(getwd(), 'data', exp_$name, 
                             paste0(exp_$model, '_', exp_$partition_field, '_results.RDS')))
  }
  
  