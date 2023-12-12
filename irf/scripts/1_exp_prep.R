library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Create experiment data output

sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))

## Set Experiment guidelines

exp_ <- list(
  time = 5,
  sms = c('county', 'submarket'),
  periodicity = 'monthly',
  train_period = 12,
  ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths', 'latitude', 'longitude',
              'submarket')
)

exp_$name <- paste0('exp_', exp_$time)
exp_$start_date <- as.Date(paste0(2022-exp_$time, '-01-01'))

if(!file.exists(file.path(getwd(), 'data', exp_$name))){
  dir.create(file.path(getwd(), 'data', exp_$name))
}

## Prep Exp Data

rt_df <- rtCreateTrans(trans_df = sales_df %>%
                         dplyr::filter(sale_date >= exp_$start_date),
                       prop_id = 'pinx',
                       trans_id = 'sale_id',
                       price = 'sale_price',
                       date = 'sale_date',
                       periodicity = exp_$periodicity,
                       seq_only = TRUE,
                       min_period_dist = exp_$train_period)

hed_df <- hedCreateTrans(trans_df = sales_df %>%
                           dplyr::filter(sale_date >= exp_$start_date),
                         prop_id = 'pinx',
                         trans_id = 'sale_id',
                         price = 'sale_price',
                         date = 'sale_date',
                         periodicity = exp_$periodicity)

exp_$rt_df <- rt_df
exp_$hed_df <- hed_df

saveRDS(exp_, file = file.path(getwd(), 'data', exp_$name, paste0('exp_obj.RDS')))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
