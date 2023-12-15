#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#. Set up experiment hyper parameters and data sets
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Load libraries
  library(tidyverse)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

  ## Load Raw Data
  sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))

### Create Standard Experiments (Those with different time coverage) -------------------------------  
  
  ## Set Experiment guidelines

  time_ranges <- c(5, 10, 20)
  sms <- c('county', 'submarket')
  periodicity <- 'monthly'
  ind_var <- c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths', 
               'latitude', 'longitude', 'submarket')
  train_per <- .2
  ntrees <- 200
  sim_per <- .05
  
  # For each desired time range, build data
  for (tr in time_ranges){
  
    cat('Building Experiment Object for time = ', tr, '\n\n')
    
    # Set up Experiment Control Object
    exp_obj <- list(
      name = paste0('exp_', tr),
      time = tr,
      start_date = as.Date(paste0(2022 - tr, '-01-01')),
      sms = sms,
      periodicity = periodicity,
      train_period = round(tr * train_per, 0),
      ind_var = ind_var,
      sim_per = .05,
      ntrees = ntrees
    )
    
    # Check for directory, create if not present
    if(!file.exists(file.path(getwd(), 'data', exp_obj$name))){
      dir.create(file.path(getwd(), 'data', exp_obj$name))
    }
    
    ## Create Data
    
    # Repeat Trans
    exp_obj$rt_df <- 
      rtCreateTrans(trans_df = sales_df %>%
                       dplyr::filter(sale_date >= exp_obj$start_date),
                    prop_id = 'pinx',
                    trans_id = 'sale_id',
                    price = 'sale_price',
                    date = 'sale_date',
                    periodicity = exp_obj$periodicity,
                    seq_only = TRUE,
                    min_period_dist = exp_obj$train_period)
    
    # Hedonic
    exp_obj$hed_df <- 
      hedCreateTrans(trans_df = sales_df %>%
                               dplyr::filter(sale_date >= exp_obj$start_date),
                    prop_id = 'pinx',
                    trans_id = 'sale_id',
                    price = 'sale_price',
                    date = 'sale_date',
                    periodicity = exp_obj$periodicity)
    
     # Write Data
    saveRDS(exp_, file = file.path(getwd(), 'data', exp_$name, paste0('exp_obj.RDS')))
    
  }

### Any Custom experiments ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  
  # To Come
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
