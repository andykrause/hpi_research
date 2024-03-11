### Local
## Set Experiment Setup to use

exp <- 'exp_10'

# Read in experiment object
exp_ <- readRDS(file=file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

## Load libraries

library(tidyverse)
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Load custom functions  
source(file.path(getwd(), 'functions', 'wrapper_function.R'))
source(file.path(getwd(), 'functions', 'oldWrappers.R'))


### Run analysis for each submarket -----------------------------------------------------------------

## All King County

exp_$model <- 'rt'
exp_$sms <- 'all'

# Five Year
rt_obj <- expWrapper(exp_obj = exp_,
                     partition = 'all')

saveRDS(rt_obj, file = file.path(getwd(), 'data', exp_$name, paste0('rt_results_obj.RDS')))

rm(rt_obj)
gc()

### Submarket


exp_$ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 'baths',
                 'latitude', 'longitude')
exp_$sms <- 'submarket'
exp_$partition_field <- 'submarket'
subm <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
          'O', 'P', 'Q', 'R', 'S')

rt_subm_ <- purrr::map(.x = subm,
                       .f = rtWrapper,
                       exp_obj = exp_)

rt_obj <- unwrapPartitions(rt_subm_)

saveRDS(rt_obj, file = file.path(getwd(), 'data', exp_$name, paste0('rt_subm_results_obj.RDS')))

he_subm_ <- purrr::map(.x = subm,
                       .f = hedWrapper,
                       exp_obj = exp_)

med_subm_ <- purrr::map(.x = subm,
                        .f = aggWrapper,
                        exp_obj = exp_)

ppsf_subm_ <- purrr::map(.x = subm,
                         .f = aggWrapper,
                         exp_obj = exp_,
                         price_field = 'ppsf')

exp_$estimator <- 'impute'
hei_subm_ <- purrr::map(.x = subm,
                        .f = hedWrapper,
                        exp_obj = exp_)


exp_$estimator <- 'impute'
rfi_subm_ <- purrr::map(.x = subm,
                        .f = rfWrapper,
                        exp_obj = exp_)

