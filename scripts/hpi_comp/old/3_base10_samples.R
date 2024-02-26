#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, changing sample results
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
  base_indexes <- readRDS(file = file.path(getwd(), 'data', 'exp_10', 'indexes.RDS'))
  
### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  
  # Set Parameters
  vol_window <- 3
  
  ## Create imputation data set
  uni_df <- homes_df %>%
    dplyr::sample_frac(., .1)
  
### 50% Test ----------------------------------------------------------------  

  ## Create 50% sample data
  seed = 1

  exp50_ <- exp_
  exp50_$hed_df <- exp50_$hed_df %>%
      dplyr::sample_frac(., .50) 

  exp50_$rt_df <-
    rtCreateTrans(trans_df = exp50_$hed_df,
                  prop_id = 'prop_id',
                  trans_id = 'trans_id',
                  price = 'price',
                  date = 'trans_date',
                  periodicity = exp50_$periodicity,
                  seq_only = TRUE,
                  min_period_dist = exp50_$train_period)

 
index50_df <- crossIndexWrapper(exp50_,
                                'random50', 
                                 vol_window = 3)

 ## Extraction Indexes --  
   
ggplot(index50_df, 
       aes(x = time_period, y = index, group = approach, color = approach)) + geom_line() + 
  facet_wrap(~class)

### 25% Test ----------------------------------------------------------------  

## Create 25% sample data
seed = 1

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

`
index25_df <- crossIndexWrapper(exp25_,
                                'random25', 
                                vol_window = 3)

## Extraction Indexes --  

ggplot(index25_df, 
       aes(x = time_period, y = index, group = approach, color = approach)) + geom_line() + 
  facet_wrap(~class)`

### Missing 10% Test ----------------------------------------------------------------  

## Create Gap of 10% sample data
seed = 1

expG10_ <- exp_
expG10_$hed_df <-
  expG10_$hed_df %>%
  dplyr::mutate(ppsf = round(price / sqft, 0),
                trans_year = as.numeric(substr(trans_date, 1, 4)))

expG10_$hed_df <- 
  expG10_$hed_df %>%
  dplyr::bind_rows(expG10_$hed_df %>% dplyr::filter(trans_year < 2019),
                   expG10_$hed_df %>% dplyr::filter(trans_year > 2019),
                   expG10_$hed_df %>% dplyr::filter(trans_year == 2019) %>%
                     dplyr::sample_frac(., .25))

expG10_$rt_df <-
  rtCreateTrans(trans_df = expG10_$hed_df,
                prop_id = 'prop_id',
                trans_id = 'trans_id',
                price = 'price',
                date = 'trans_date',
                periodicity = expG10_$periodicity,
                seq_only = TRUE,
                min_period_dist = expG10_$train_period)

indexG10_df <- crossIndexWrapper(expG10_,
                                'gap10', 
                                vol_window = 3)

## Extraction Indexes --  

ggplot(indexG10_df, 
       aes(x = time_period, y = index, color = approach)) + geom_line()


### RT Only Sample ----------------------------------------------------------------  

## Create Gap of 10% sample data

expRT_ <- exp_
expRT_$hed_df <-
  expRT_$hed_df %>%
  dplyr::filter(trans_id %in% c(expRT_$rt_df$trans_id1, expRT_$rt_df$trans_id2))

indexRT_df <- crossIndexWrapper(expRT_,
                                 'rt-only', 
                                 vol_window = 3)

## Extraction Indexes --  

ggplot(indexG10_df, 
       aes(x = time_period, y = index, color = approach)) + geom_line()



indexSample_df <- dplyr::bind_rows(indexRT_df, indexG10_df, index25_df, index50_df)

# Save index data.frame
saveRDS(indexRobust_df,
        file = file.path(getwd(), 'data', 'exp_10', 'indexesSample_df.RDS'))

# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   