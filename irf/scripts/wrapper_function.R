

rtWrapper <- function(exp_obj, 
                      verbose = TRUE,
                      estimator = 'robust',
                      log_dep = TRUE,
                      trim_model = TRUE,
                      vol_window = 3,
                      ...){
  
  if(verbose) cat('.Estimating Full Index\n')

  max_period <- max(exp_obj$rt_df$period_2)
  rt_hpi <- rtIndex(trans_df = exp_obj$rt_df,
                    estimator = estimator,
                    log_dep = log_dep,
                    trim_model = trim_model,
                    max_period = max_period)
  
  if(verbose) cat('..Calculating Index Volatility\n')
  rt_hpi <- calcVolatility(index = rt_hpi,
                           window = vol_window,
                           in_place = TRUE)
  
  if(verbose) cat('..Calculating Index (In Sample) Accuracy\n')
  rt_hpi <- calcAccuracy(hpi_obj = rt_hpi,
                         test_method = 'insample',
                         test_type = 'rt',
                         in_place = TRUE,
                         in_place_name = 'is_accuracy')
  
  if(verbose) cat('..Calculating Index (kFold) Accuracy.\n')
  rt_hpi <- calcAccuracy(hpi_obj = rt_hpi,
                         test_method = 'kfold',
                         test_type = 'rt',
                         in_place = TRUE,
                         in_place_name = 'kf_accuracy')
  
  gc()
  
  if(verbose) cat('.Calculating Index Series.\n')
  rt_series <- createSeries(hpi_obj = rt_hpi,
                            train_period = exp_$train_period,
                            max_period = max_period,
                            smooth = TRUE, 
                            slim = TRUE)
  
  if(verbose) cat('.Calculating Series Volatility.\n')
  rt_series <- calcSeriesVolatility(series_obj = rt_series,
                                    window = 3,
                                    smooth = FALSE,
                                    in_place = TRUE,
                                    in_place_name = 'volatility')
  
  if(verbose) cat('.Calculating Index Revision.\n')
  rt_series <- calcRevision(series_obj = rt_series,
                            in_place = TRUE,
                            in_place_name = 'revision')
  
  if(verbose) cat('.Calculating Series Predictive Accuracy (Repeat).\n')  
  rt_series <- calcSeriesAccuracy(series_obj = rt_series,
                                  test_method = 'forecast',
                                  test_type = 'rt',
                                  smooth = FALSE,
                                  in_place = TRUE,
                                  in_place_name = 'pr_accuracy')
  
  if(verbose) cat('.Calculating Series Predictive Accuracy (Hedonic).\n')  
  
  rt_hedaccr <- list()
  for (ti in 1:(length(rt_series$hpis)-1)) {
    rt_hedaccr[[ti]] <- getHedFitAccuracy(rt_series$hpis[[ti]],
                                          exp_obj)
  }
  rt_series$hed_praccr <- dplyr::bind_rows(rt_hedaccr)
  
  # if(verbose) cat('...Writing Full Index\n')
  rt_hpi$data <- NULL
  rt_hpi$model <- NULL
  gc()
  # saveRDS(rt_hpi, file = file.path(data_path, paste0('index_', exp_name, '.RDS')))
  # 
  rt_series$data <- NULL
  rt_series$hpis <- NULL
  gc()
  # if(verbose) cat('...Writing Full Series\n')
  # saveRDS(rt_series, file = file.path(data_path, paste0('series_', exp_name, '.RDS')))
  # 
  return(list(
     index = rt_hpi,
     series = rt_series))
}


hedWrapper <- function(exp_obj,
                       verbose = TRUE,
                       estimator = 'robust',
                       log_dep = TRUE,
                       trim_model = TRUE,
                       vol_window = 3,
                       ...){
  
  if(verbose) cat('.Estimating Full Index\n')
  
  max_period <- max(exp_obj$hed_df$trans_period)
  he_hpi <- hedIndex(trans_df = exp_obj$hed_df,
                     estimator = estimator,
                     log_dep = log_dep,
                     dep_var = 'price',
                     ind_var = exp_obj$ind_var,
                     trim_model = TRUE,
                     max_period = max(exp_obj$hed_df$trans_period),
                     smooth = TRUE)
  
  if(verbose) cat('..Calculating Index Volatility\n')
  he_hpi <- calcVolatility(index = he_hpi,
                           window = vol_window,
                           in_place = TRUE)
  
  if(verbose) cat('..Calculating Index (In Sample) Accuracy\n')
  he_hpi <- calcAccuracy(hpi_obj = he_hpi,
                         test_method = 'insample',
                         test_type = 'rt',
                         pred_df = exp_obj$rt_df,
                         in_place = TRUE,
                         in_place_name = 'is_accuracy')
  
  if(verbose) cat('..Calculating Index (kFold) Accuracy.\n')
  he_hpi <- calcAccuracy(hpi_obj = he_hpi,
                          test_method = 'kfold',
                          test_type = 'rt',
                          pred_df = exp_obj$rt_df,
                          in_place = TRUE,
                          in_place_name = 'kf_accuracy')
  
  
  gc()
  
  if(verbose) cat('.Calculating Index Series.\n')
  he_series <- createSeries(hpi_obj = he_hpi,
                            train_period = exp_obj$train_period,
                            max_period = max_period,
                            smooth = TRUE)
  
  if(verbose) cat('.Calculating Series Volatility.\n')
  he_series <- calcSeriesVolatility(series_obj = he_series,
                                    window = vol_window,
                                    smooth = FALSE,
                                    in_place = TRUE,
                                    in_place_name = 'volatility')
  
  if(verbose) cat('.Calculating Index Revision.\n')
  he_series <- calcRevision(series_obj = he_series,
                            in_place = TRUE,
                            in_place_name = 'revision')
  
  if(verbose) cat('.Calculating Series Predictive Accuracy.\n')
  he_series <- calcSeriesAccuracy(series_obj = he_series,
                                  test_method = 'forecast',
                                  test_type = 'rt',
                                  pred_df = exp_obj$rt_df,
                                  smooth = FALSE,
                                  in_place = TRUE,
                                  in_place_name = 'pr_accuracy')
  
  
  hed_hedaccr <- list()
  for (ti in 1:(length(he_series$hpis)-1)) {
    hed_hedaccr[[ti]] <- getHedFitAccuracy(he_series$hpis[[ti]],
                                          exp_obj)
  }
  he_series$hed_praccr <- dplyr::bind_rows(hed_hedaccr)
  

  # if(verbose) cat('...Writing Full Index\n')
  he_hpi$data <- NULL
  he_hpi$model <- NULL
  gc()
  # saveRDS(he_hpi, file = file.path(data_path, paste0('index_', exp_name, '.RDS')))
  
  he_series$data <- NULL
  he_series$hpis <- NULL
  gc()
  # if(verbose) cat('...Writing Full Series\n')
  # saveRDS(he_series, file = file.path(data_path, paste0('series_', exp_name, '.RDS')))
  
  return(
    list(
      index = he_hpi,
      series = he_series
    )
  )
  
}


rfWrapper <- function(exp_obj,
                      verbose = TRUE,
                      estimator = 'pdp',
                      ntrees = 100,
                      sim_per = .1,
                      log_dep = TRUE,
                      trim_model = TRUE,
                      vol_window = 3,
                      ...){
  
  max_period <- max(exp_obj$hed_df$trans_period)
  rf_hpi <- rfIndex(trans_df = exp_obj$hed_df,
                     estimator = estimator,
                     log_dep = log_dep,
                     dep_var = 'price',
                     ind_var = exp_obj$ind_var,
                     trim_model = TRUE,
                     ntrees = ntrees,
                     sim_per = sim_per,
                     max_period = max(exp_obj$hed_df$trans_period),
                     smooth = TRUE)
  
  if(verbose) cat('..Calculating Index Volatility\n')
  rf_hpi <- calcVolatility(index = rf_hpi,
                           window = vol_window,
                           in_place = TRUE)
  
  if(verbose) cat('..Calculating Index (In Sample) Accuracy\n')
  rf_hpi <- calcAccuracy(hpi_obj = rf_hpi,
                         test_method = 'insample',
                         test_type = 'rt',
                         pred_df = exp_obj$rt_df,
                         in_place = TRUE,
                         in_place_name = 'is_accuracy')

  if(verbose) cat('..Calculating Index (kfold) Accuracy\n')
  rf_hpi <- calcAccuracy(hpi_obj = rf_hpi,
                         test_method = 'kfold',
                         test_type = 'rt',
                         pred_df = exp_obj$rt_df,
                         in_place = TRUE,
                         in_place_name = 'kf_accuracy')

  gc()

  if(verbose) cat('.Calculating Index Series.\n')
  rf_series <- createSeries(hpi_obj = rf_hpi,
                            train_period = exp_obj$train_period,
                            max_period = max_period,
                            smooth = TRUE,
                            ntrees = ntrees,
                            sim_per = sim_per)

  if(verbose) cat('.Calculating Series Volatility.\n')
  rf_series <- calcSeriesVolatility(series_obj = rf_series,
                                    window = vol_window,
                                    smooth = FALSE,
                                    in_place = TRUE,
                                    in_place_name = 'volatility')

  if(verbose) cat('.Calculating Index Revision.\n')
  rf_series <- calcRevision(series_obj = rf_series,
                            in_place = TRUE,
                            in_place_name = 'revision')

  if(verbose) cat('.Calculating Series Predictive Accuracy.\n')
  rf_series <- calcSeriesAccuracy(series_obj = rf_series,
                                  test_method = 'forecast',
                                  test_type = 'rt',
                                  pred_df = exp_obj$rt_df,
                                  smooth = FALSE,
                                  in_place = TRUE,
                                  in_place_name = 'pr_accuracy')

  rf_hedaccr <- list()
  for (ti in 1:(length(rf_series$hpis)-1)) {
    rf_hedaccr[[ti]] <- getHedFitAccuracy(rf_series$hpis[[ti]],
                                           exp_obj)
  }
  rf_series$hed_praccr <- dplyr::bind_rows(rf_hedaccr)
  
  if(verbose) cat('...Writing Full Index\n')
  rf_hpi$data <- NULL
  rf_hpi$model <- NULL
  gc()
  # saveRDS(rf_hpi, file = file.path(data_path, paste0('index_', exp_name, '.RDS')))
  

  rf_series$data <- NULL
  rf_series$hpis <- NULL
  gc()
  # if(verbose) cat('...Writing Full Series\n')
  # saveRDS(rf_series, file = file.path(data_path, paste0('series_', exp_name, '.RDS')))

  return(
    list(
      #data = hed_df,
      index = rf_hpi,
      series = rf_series
    )
  )
  
}

getHedFitAccuracy <- function(index_obj,
                              exp_obj){
  
  max_period <- length(index_obj$index$period)
  
  adj_df <- data.frame(trans_period = index_obj$index$period,
                       index_value = index_obj$index$value) %>%
    dplyr::mutate(index_adj = 1 / (index_value / index_value[max_period]))
  
  val_period <- max(adj_df$trans_period + 1)
  
  train_df <- exp_obj$hed_df %>%
    dplyr::filter(trans_period < val_period) %>%
    dplyr::left_join(., adj_df, by = 'trans_period') %>%
    dplyr::mutate(adj_price = price * index_adj)
  
  val_df <- exp_obj$hed_df %>%
    dplyr::filter(trans_period == val_period)
  
  base_eq <- as.formula(paste('log(price) ~ ', paste(exp_obj$ind_var, collapse= '+')))
  adj_eq <- as.formula(paste('log(adj_price) ~ ', paste(exp_obj$ind_var, collapse= '+')))
  
  base_lm <- lm(base_eq, train_df)   
  adj_lm <- lm(adj_eq, train_df)  
  
  base_val <- data.frame(trans_id = val_df$trans_id,
                         trans_period = val_df$trans_period,
                         prediction = exp(predict(base_lm, val_df)),
                         price = val_df$price,
                         type = 'base') %>%
    dplyr::mutate(error = log(prediction) - log(price))
  adj_val <- data.frame(trans_id = val_df$trans_id,
                        trans_period = val_df$trans_period,
                        prediction = exp(predict(adj_lm, val_df)),
                        price = val_df$price,
                        type = 'adj') %>%
    dplyr::mutate(error = log(prediction) - log(price))
  
  dplyr::bind_rows(base_val, adj_val)
}    


  