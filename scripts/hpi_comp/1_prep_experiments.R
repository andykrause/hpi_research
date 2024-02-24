#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Set up experiment hyper parameters and data sets
#
#.  -- Script that creates an experiment input object for each scenario
#.  -- it also creates a directory for saving results for each experiment scenario
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Load libraries
  library(tidyverse)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

  ## Load Raw Data
  sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))

### Create Standard Experiments (Those with different time coverage) -------------------------------  
  
  ## Set Experiment parameters

  # For all models
  terminal_year <- 2024
  time_ranges <- c(5, 10, 20)
  sms <- c('county', 'submarket')
  periodicity <- 'monthly'
  train_per <- .2
  
  # For HED/RF
  ind_var <- c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths', 
               'latitude', 'longitude', 'submarket')
  
  # For RF Only
  rf_par <- list(
    ntrees = 200,
    sim_per = .10,
    min_bucket = 5,
    always_split_variables = 'trans_period'
  )
  
  # For each desired time range, build data
  for (tr in time_ranges){
  
    cat('Building Experiment Object for time = ', tr, '\n\n')
    
    # Set up Experiment Control Object
    exp_obj <- list(
      name = paste0('exp_', tr),
      time = tr,
      start_date = as.Date(paste0(terminal_year - tr, '-01-01')),
      sms = sms,
      periodicity = periodicity,
      train_period = round(tr * ifelse(periodicity == 'monthly', 12, 52) * train_per, 0),
      ind_var = ind_var,
      rf_par = rf_par
    )
    
    # Check for directory, create if not present
    if(!file.exists(file.path(getwd(), 'data', exp_obj$name))){
      dir.create(file.path(getwd(), 'data', exp_obj$name))
    }
    
    ## Create Data
    
    # Repeat Transaction Data
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
    
    # Hedonic Data
    exp_obj$hed_df <- 
      hedCreateTrans(trans_df = sales_df %>%
                               dplyr::filter(sale_date >= exp_obj$start_date),
                    prop_id = 'pinx',
                    trans_id = 'sale_id',
                    price = 'sale_price',
                    date = 'sale_date',
                    periodicity = exp_obj$periodicity) %>%
      dplyr::mutate(ppsf = round(price / sqft, 0))
    
     # Write Data
    saveRDS(exp_obj, file = file.path(getwd(), 'data', exp_obj$name, paste0('exp_obj.RDS')))
    
  }

### Create 10 Year Sampling experiments ------------------------------------------------------------
 
  exp <- 'exp_10'
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
#### 50% missing ----------------
 
  seed = 1
  
  exp50_ <- exp_
  x50 <- exp50_$hed_df %>%
    dplyr::group_by(submarket, trans_period) %>%
    dplyr::sample_frac(., .5) %>%
    dplyr::ungroup()
  exp50_$hed_df <- exp50_$hed_df %>%
    dplyr::filter(trans_id %in% x50$trans_id)
  
  exp50_$rt_df <-
    rtCreateTrans(trans_df = exp50_$hed_df,
                  prop_id = 'prop_id',
                  trans_id = 'trans_id',
                  price = 'price',
                  date = 'trans_date',
                  periodicity = exp50_$periodicity,
                  seq_only = TRUE,
                  min_period_dist = exp50_$train_period)
  
  saveRDS(exp50_, file = file.path(getwd(), 'data', exp_obj$name, paste0('exp_s50_obj.RDS')))

#### 25% Missing -------------------
  
  seed <- 1
  exp25_ <- exp_
  x25 <- exp25_$hed_df %>%
    dplyr::group_by(submarket, trans_period) %>%
    dplyr::sample_frac(., .25) %>%
    dplyr::ungroup()
  exp25_$hed_df <- exp25_$hed_df %>%
    dplyr::filter(trans_id %in% x25$trans_id)
  
  exp25_$rt_df <-
    rtCreateTrans(trans_df = exp25_$hed_df,
                  prop_id = 'prop_id',
                  trans_id = 'trans_id',
                  price = 'price',
                  date = 'trans_date',
                  periodicity = exp25_$periodicity,
                  seq_only = TRUE,
                  min_period_dist = exp25_$train_period)
  
  saveRDS(exp25_, file = file.path(getwd(), 'data', exp_obj$name, paste0('exp_s25_obj.RDS')))
  
#### 10% Gap -----------------
  
  seed <- 1
  expG10_ <- exp_
  expG10_$hed_df <-
    expG10_$hed_df %>%
    dplyr::mutate(ppsf = round(price / sqft, 0),
                  trans_year = as.numeric(substr(trans_date, 1, 4)))
  
  bef_df <- 
    expG10_$hed_df %>% dplyr::filter(trans_year < 2019)
  aft_df <-   
    expG10_$hed_df %>% dplyr::filter(trans_year > 2020)
  gap_df <-   
    expG10_$hed_df %>%
    dplyr::group_by(submarket, trans_period) %>%
    dplyr::sample_frac(., .10) %>%
    dplyr::ungroup()
  expG10_$hed_df <- 
    dplyr::bind_rows(bef_df, aft_df, gap_df)
  
  expG10_$rt_df <-
    rtCreateTrans(trans_df = expG10_$hed_df,
                  prop_id = 'prop_id',
                  trans_id = 'trans_id',
                  price = 'price',
                  date = 'trans_date',
                  periodicity = expG10_$periodicity,
                  seq_only = TRUE,
                  min_period_dist = expG10_$train_period)
  
  saveRDS(expG10_, file = file.path(getwd(), 'data', exp_obj$name, paste0('exp_sG10_obj.RDS')))

#### Repeat Transaction only data -------------------
  
  expRT_ <- exp_
  expRT_$hed_df <-
    expRT_$hed_df %>%
    dplyr::filter(trans_id %in% c(expRT_$rt_df$trans_id1, expRT_$rt_df$trans_id2))
  
  saveRDS(expRT_, file = file.path(getwd(), 'data', exp_obj$name, paste0('exp_sRT_obj.RDS')))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  