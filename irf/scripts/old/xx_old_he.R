library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Create experiment data output

sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))


## Convert to hedonic-ready dataset
hed_df <- hedCreateTrans(trans_df = sales_df,
                         prop_id = 'pinx',
                         trans_id = 'sale_id',
                         price = 'sale_price',
                         date = 'sale_date',
                         periodicity = 'monthly')


rt_df <- readRDS(file = file.path(getwd(), 'data', '22_rt', 'rt_df.RDS'))

max_period <- max(hed_df$trans_period)
train_period <- 24
#exp_name <- paste0(substr(digest::digest(seattle_sales), 1, 6), '_',
#                    substr(digest::digest(ind_var), 1, 6), '_',
#                    max_period, '_', train_period)

exp_name = '22_hed'

cat(exp_name, '\n\n')
if(!file.exists(file.path(getwd(), 'data', exp_name))){
  dir.create(file.path(getwd(), 'data', exp_name))
}

ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 
            'baths', 'wfnt', 'view_score', 'latitude', 'longitude')


he_hpi <- hedIndex(trans_df = hed_df,
                   estimator = 'base',
                   log_dep = TRUE,
                   dep_var = 'price',
                   ind_var = ind_var,
                   trim_model = FALSE,
                   max_period = max_period,
                   smooth = TRUE)


he_hpi <- calcVolatility(index = he_hpi,
                         window = 3,
                         in_place = TRUE)

he_hpi <- calcAccuracy(hpi_obj = he_hpi,
                       test_method = 'insample',
                       test_type = 'rt',
                       pred_df = rt_df,
                       in_place = TRUE,
                       in_place_name = 'is_accuracy')

he_hpi <- calcAccuracy(hpi_obj = he_hpi,
                       test_method = 'kfold',
                       test_type = 'rt',
                       pred_df = rt_df,
                       in_place = TRUE,
                       in_place_name = 'kf_accuracy')

he_series <- createSeries(hpi_obj = he_hpi,
                          train_period = train_period,
                          max_period = max_period,
                          smooth = TRUE)

he_series <- calcSeriesVolatility(series_obj = he_series,
                                  window = 3,
                                  smooth = FALSE,
                                  in_place = TRUE,
                                  in_place_name = 'volatility')

he_series <- calcRevision(series_obj = he_series,
                          in_place = TRUE,
                          in_place_name = 'revision')

he_series <- calcSeriesAccuracy(series_obj = he_series,
                                test_method = 'forecast',
                                test_type = 'rt',
                                pred_df = rt_df,
                                smooth = FALSE,
                                in_place = TRUE,
                                in_place_name = 'pr_accuracy')

saveRDS(hed_df, file = file.path(getwd(), 'data', exp_name, 'he_df.RDS'))
saveRDS(he_hpi[c('index')], file = file.path(getwd(), 'data', exp_name, 'he_hpi.RDS'))
saveRDS(he_series[c('revision', 'pr_accuracy')], file = file.path(getwd(),
                                                                  'data', exp_name, 'he_series.RDS'))

rm(he_hpi); rm(he_series)
gc()
