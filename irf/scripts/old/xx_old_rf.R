library(tidyverse)
library(digest)
library(mlr)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Create experiment data output

sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))

rt_df <- readRDS(file = file.path(getwd(), 'data', '22_rt', 'rt_df.RDS'))
hed_df <- readRDS(file = file.path(getwd(), 'data', '22_hed', 'he_df.RDS'))


ntrees = 500
sim_count = 500
max_period <- max(hed_df$trans_period)
train_period <- 24
exp_name = '22_rf'
cat(exp_name, '\n\n')
if(!file.exists(file.path(getwd(), 'data', exp_name))){
  dir.create(file.path(getwd(), 'data', exp_name))
}

ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 
            'baths', 'wfnt', 'view_score', 'latitude', 'longitude')


rf_hpi <- rfIndex(trans_df = hed_df,
                  estimator = 'pdp',
                  dep_var = 'price',
                  ind_var = ind_var,
                  max_period = max_period,
                  smooth = FALSE,
                  ntrees = 500,
                  sim_ids = sample(1:nrow(hed_df), sim_count))

rf_hpi <- calcVolatility(index = rf_hpi,
                         window = 3,
                         in_place = TRUE)

rf_hpi <- calcAccuracy(hpi_obj = rf_hpi,
                       test_method = 'insample',
                       test_type = 'rt',
                       pred_df = rt_df,
                       in_place = TRUE,
                       in_place_name = 'is_accuracy')

rf_hpi <- calcAccuracy(hpi_obj = rf_hpi,
                       test_method = 'kfold',
                       test_type = 'rt',
                       pred_df = rt_df,
                       in_place = TRUE,
                       in_place_name = 'kf_accuracy',
                       sim_ids = 1:sim_count)

rf_series <- createSeries(hpi_obj = rf_hpi,
                          train_period = train_period,
                          max_period = max_period,
                          ntrees = 500,
                          sim_per = .01)

rf_series <- calcSeriesVolatility(series_obj = rf_series,
                                  window = 3,
                                  smooth = FALSE,
                                  in_place = TRUE,
                                  in_place_name = 'volatility')

rf_series <- calcRevision(series_obj = rf_series,
                          in_place = TRUE,
                          in_place_name = 'revision')

rf_series <- calcSeriesAccuracy(series_obj = rf_series,
                                test_method = 'forecast',
                                test_type = 'rt',
                                pred_df = rt_df,
                                smooth = FALSE,
                                in_place = TRUE,
                                in_place_name = 'pr_accuracy')
