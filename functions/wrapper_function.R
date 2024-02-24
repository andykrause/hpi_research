
expWrapper <- function(exp_obj,
                       partition = 'all',
                       verbose = TRUE,
                       estimator = 'robust',
                       log_dep = TRUE,
                       trim_model = TRUE,
                       vol_window = 3,
                       index_only = FALSE,
                       ...){
  
  ## Filter data if a partition of the whole
  
  if (partition != 'all'){
    exp_obj <- dataFilter(exp_obj, partition)
    cat('Analyzing ', exp_obj$sms[1], ' ', partition, '\n\n')
  }
  
  ## Get the max period
  max_period <- max(exp_obj$rt_df$period_2)
  
  ## Estimate the indexes
  if(verbose) cat('.Estimating Full Index with ', exp_obj$model, 'model. \n')
  
  if (exp_obj$model == 'rt'){
    hpi_obj <- rtIndex(trans_df = exp_obj$rt_df,
                       estimator = estimator,
                       log_dep = log_dep,
                       trim_model = trim_model,
                       max_period = max_period)
  }
  if (exp_obj$model == 'hed'){
    hpi_obj <- hedIndex(trans_df = exp_obj$hed_df,
                        estimator = estimator,
                        log_dep = log_dep,
                        dep_var = 'price',
                        ind_var = exp_obj$ind_var,
                        trim_model = TRUE,
                        max_period = max(exp_obj$hed_df$trans_period),
                        smooth = TRUE)
  }
  if (exp_obj$model == 'rf'){
    hpi_obj <- rfIndex(trans_df = exp_obj$hed_df,
                       estimator = 'pdp',
                       log_dep = log_dep,
                       dep_var = 'price',
                       ind_var = exp_obj$ind_var,
                       trim_model = TRUE,
                       ntrees = exp_obj$rf_par$ntrees,
                       sim_per = exp_obj$rf_par$sim_per,
                       max_period = max(exp_obj$hed_df$trans_period),
                       smooth = FALSE,
                       min.bucket = exp_obj$rf_par$min_bucket,
                       always.split.variables = 
                         exp_obj$rf_par$always_split_variables)
  }
  
  # Extract into a simple data.frame()
  index_df <- data.frame(name = hpi_obj$index$name,
                         period = hpi_obj$index$period,
                         value = as.numeric(hpi_obj$index$value),
                         imputed = hpi_obj$index$imputed,
                         time = exp_obj$time,
                         model = exp_obj$model, 
                         exp = exp_obj$name,
                         partition = partition)

  if(index_only) return(index_df)
  
  if(verbose) cat('..Calculating Index Volatility\n')
  hpi_obj <- calcVolatility(index = hpi_obj,
                            window = vol_window,
                            in_place = TRUE)
  
  vol_df <- data.frame(name = hpi_obj$index$volatility$roll,
                       mean = hpi_obj$index$volatility$mean,
                       median = hpi_obj$index$volatility$median,
                       time = exp_obj$time,
                       model = exp_obj$model, 
                       exp = exp_obj$name,
                       partition = partition)  
  
  gc()
  
  if(verbose) cat('.Calculating Index Series.\n')
  series_obj <- createSeries(hpi_obj = hpi_obj,
                             train_period = exp_$train_period,
                             max_period = max_period,
                             smooth = TRUE, 
                             slim = TRUE) %>%
    suppressWarnings()
  
  series_df <- purrr::map(.x = series_obj$hpis,
                          .f = function(x){
                            series_name <- max(x$index$period)
                            data.frame(name = x$index$name,
                                       period = x$index$period,
                                       value = as.numeric(x$index$value),
                                       imputed = x$index$imputed,
                                       time = exp_obj$time,
                                       model = exp_obj$model, 
                                       exp = exp_obj$name,
                                       series = series_name,
                                       partition = partition)}) %>%
    dplyr::bind_rows()
  
  if(verbose) cat('.Calculating Series Volatility.\n')
  series_obj <- calcSeriesVolatility(series_obj = series_obj,
                                     window = 3,
                                     smooth = FALSE,
                                     in_place = TRUE,
                                     in_place_name = 'volatility')
  
  volseries_df <- purrr::map(.x = series_obj$volatility,
                             .f = function(x){
                               series_name <- max(x$period)
                               data.frame(series = series_name,
                                          mean = x$volatility$mean,
                                          median = x$volatility$median,
                                          time = exp_obj$time,
                                          model = exp_obj$model, 
                                          exp = exp_obj$name,
                                          partition = partition)}) %>%
    dplyr::bind_rows()
  
  if(verbose) cat('.Calculating Index Revision.\n')
  series_obj <- calcRevision(series_obj = series_obj,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  rev_df <- series_obj$revision$period %>%
    dplyr::mutate(time = exp_obj$time,
                  model = exp_obj$model, 
                  exp = exp_obj$name,
                  partition = partition)
  
  if(verbose) cat('.Calculating Series Predictive Accuracy (Repeat).\n')  
  series_obj <- calcSeriesAccuracy(series_obj = series_obj,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_obj$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  absaccr_df <- series_obj$pr_accuracy %>%
    dplyr::mutate(time = exp_obj$time,
                  model = exp_obj$model, 
                  exp = exp_obj$name,
                  partition = partition)
  
  if(verbose) cat('.Calculating Series Relative Accuracy (Hed).\n')  
  
  series_obj <- calculateRelAccr(series_obj,
                                 exp_obj)
  relaccr_df <- dplyr::bind_rows(series_obj$rel_accuracy) %>%
    dplyr::mutate(time = exp_obj$time,
                  model = exp_obj$model, 
                  exp = exp_obj$name,
                  partition = partition)

  return(list(
    index = index_df,
    series = series_df,
    vol = vol_df,
    volS = volseries_df,
    revision = rev_df,
    absacc = absaccr_df,
    relacc = relaccr_df))
}



getHedFitAccuracy <- function(index_obj,
                              exp_obj,
                              model_class = 'rf'){
  
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
  
  if (model_class == 'lm'){
    base_lm <- lm(base_eq, train_df)   
    adj_lm <- lm(adj_eq, train_df)  
    base_pred <- predict(base_lm, val_df)
    adj_pred <- predict(adj_lm, val_df)
  }
  
  if (model_class == 'rf'){
    base_rf <- ranger::ranger(formula = base_eq, data = train_df)
    adj_rf <- ranger::ranger(formula = adj_eq, data = train_df)
    base_pred <- predict(base_rf, val_df)$predictions
    adj_pred <- predict(adj_rf, val_df)$predictions
    
  }
  
  base_val <- data.frame(trans_id = val_df$trans_id,
                         trans_period = val_df$trans_period,
                         prediction = exp(base_pred),
                         price = val_df$price,
                         type = 'base') %>%
    dplyr::mutate(error = log(prediction) - log(price))
  adj_val <- data.frame(trans_id = val_df$trans_id,
                        trans_period = val_df$trans_period,
                        prediction = exp(adj_pred),
                        price = val_df$price,
                        type = 'adj') %>%
    dplyr::mutate(error = log(prediction) - log(price))
  
  dplyr::bind_rows(base_val, adj_val)
}    

calculateRelAccr <- function(series_obj,
                             exp_obj,
                             ...){
  
  hedaccr_ <- list()
  for (ti in 1:(length(series_obj$hpis)-1)) {
    hedaccr_[[ti]] <- getHedFitAccuracy(series_obj$hpis[[ti]],
                                        exp_obj,
                                        ...)
  }
  series_obj$rel_accuracy <- dplyr::bind_rows(hedaccr_)
  series_obj 
}

dataFilter <- function(exp_obj,
                       partition){
  
  exp_obj$hed_df$partition_field <- exp_obj$hed_df[[exp_obj$partition_field[1]]]
  
  ss_ids <- exp_obj$hed_df %>%
    dplyr::filter(partition_field == partition) %>%
    dplyr::select(trans_id)
  
  exp_obj$rt_df <- exp_obj$rt_df %>%
    dplyr::filter(trans_id1 %in% ss_ids$trans_id)
  exp_obj$hed_df <- exp_obj$hed_df %>%
    dplyr::filter(trans_id %in% ss_ids$trans_id)
  
  exp_obj
  
}

unwrapPartitions <- function(part_obj){
  ind <- purrr::map(.x = part_obj,
                    .f = function(x){
                      x$index
                    })
  series <- purrr::map(.x = part_obj,
                    .f = function(x){
                      x$series
                    })
  vol <- purrr::map(.x = part_obj,
                       .f = function(x){
                         x$vol
                       })
  volS <- purrr::map(.x = part_obj,
                       .f = function(x){
                         x$volS
                       })
  
  revision <- purrr::map(.x = part_obj,
                     .f = function(x){
                       x$revision
                     })
  absacc <- purrr::map(.x = part_obj,
                           .f = function(x){
                             x$absacc
                           })
  relacc <- purrr::map(.x = part_obj,
                       .f = function(x){
                         x$relacc
                       })
  list(index = ind,
       series = series,
       vol = vol,
       volS = volS,
       revision = revision,
       absacc = absacc,
       relaccc = relacc)
}

periodOverPeriod <- function(index_obj){
  index_obj$index$PoP <- c(0, (index_obj$index$value[-1] / 
                                 index_obj$index$value[-length(index_obj$index$value)]) -1)
  index_obj
}  

indexes2df <- function(index_list,
                       time_length){
  
  purrr::map(.x = index_list,
             .f = function(x){
               x = periodOverPeriod(x)
               data.frame(approach = x$model$approach,
                          class = x$model$class,
                          time = time_length, 
                          time_period = x$index$period,
                          month = x$index$name,
                          index = as.numeric(x$index$value),
                          MoM = round(x$index$PoP, 3),
                          seasonal = x$stl$seasonal,
                          trend = x$stl$trend,
                          remainder = x$stl$remainder,
                          volatility = x$stl$volatility)
             }) %>%
    dplyr::bind_rows(.)
}


crossIndexWrapper <- function(expx_, 
                              sample_name,
                              vol_window = 3,
                              ...){
  
  # Pure Median
  med_index <- aggIndex(trans_df = expx_$hed_df,
                        estimator = 'median') %>%
  ind2stl(.)
  med_index$model$approach <- 'median_price'
  med_index$model$class <- 'agg'
  
  # PPSF Index 
  ppsf_index <- aggIndex(trans_df = expx_$hed_df,
                         estimator = 'median',
                         price_field = 'ppsf') %>%
    ind2stl(.)
  ppsf_index$model$approach <- 'median_ppsf'
  ppsf_index$model$class <- 'agg'
  
  # RT Index -----
  rt_index <- rtIndex(trans_df = expx_$rt_df,
                      estimator = 'robust',
                      log_dep = TRUE,
                      max_period = max(expx_$rt_df$period_2)) %>%
    ind2stl(.)
  rt_index$model$class <- 'tme'
  
  hed_index <- hedIndex(trans_df = expx_$hed_df,
                        estimator = 'robust',
                        log_dep = TRUE,
                        dep_var = 'price',
                        ind_var = expx_$ind_var,
                        trim_model = TRUE,
                        max_period = max(expx_$hed_df$trans_period),
                        smooth = FALSE) %>%
    ind2stl(.)
  hed_index$model$class <- 'tme'

  hedimp_index <- hedIndex(trans_df = expx_$hed_df,
                           estimator = 'impute',
                           log_dep = TRUE,
                           dep_var = 'price',
                           ind_var = expx_$ind_var,
                           trim_model = TRUE,
                           max_period = max(expx_$hed_df$trans_period),
                           smooth = FALSE,
                           sim_df = expx_$hed_df %>%
                             dplyr::filter(submarket != 'H')) %>%
    ind2stl(.)
  hedimp_index$model$approach <- 'hedimp'
  hedimp_index$model$class <- 'imp'
  
  ## RF Index -----
  rfimp_index <- rfIndex(trans_df = expx_$hed_df,
                         estimator = 'chain',
                         log_dep = TRUE,
                         dep_var = 'price',
                         ind_var = expx_$ind_var,
                         trim_model = TRUE,
                         ntrees = expx_$rf_par$ntrees,
                         sim_per = expx_$rf_par$sim_per,
                         max_period = max(expx_$hed_df$trans_period),
                         smooth = FALSE,
                         min.bucket = expx_$rf_par$min_bucket,
                         always.split.variables = 
                           expx_$rf_par$always_split_variables,
                         sim_df = uni_df)%>%
    ind2stl(.)
  rfimp_index$model$approach <- 'rf_imp'
  rfimp_index$model$class <- 'imp'
  
  indexes_ <- list(med_index,
                   ppsf_index,
                   rt_index,
                   hed_index,
                   hedimp_index,
                   rfimp_index)
  
  index_df <- indexes2df(index_list = indexes_,
                         time_length = 10)
  index_df$sample <- sample_name
  
  return(index_df)
  
}  


ind2stl <- function(index_obj,
                    window = 3,
                    in_place = TRUE){
  kt <- length(index_obj$index$value)
  
  ind_ts <- ts(index_obj$index$value, 
               frequency = 12)
  ind_stl <- stl(ind_ts, 
                 s.window = 'periodic')
  
  rem <- ind_stl$time.series[, 3]
  
  ## Calculate mean rolling sd
  iv <- zoo::rollapply(rem, window, stats::sd)
  
  data.frame(period = 1:(length(ind_stl$time.series)/3),
             seasonal = ind_stl$time.series[,1],
             trend = ind_stl$time.series[,2],
             remainder = ind_stl$time.series[,3],
             volatility = c(0, iv, 0)) ->
    stl_df
  
  if(in_place){
    index_obj$stl <- stl_df
    return(index_obj)
  } else {
    return(stl_df)
  }
  
}

aggWrapper <- function(exp_obj,
                       partition,
                       verbose = TRUE,
                       estimator = 'median',
                       price_field = 'price',
                       trim_model = TRUE,
                       vol_window = 3,
                       ...){
  
  if (partition != 'all'){
    exp_obj <- dataFilter(exp_obj, partition)
    cat('Analyzing ', exp_obj$sms[1], ': ', partition, '\n\n')
  }
  
  mp<- max(exp_obj$hed_df$trans_period)
  
  
  if(verbose) cat('..Calculating Index.\n')
  agg_hpi <- aggIndex(trans_df = exp_obj$hed_df,
                      estimator = estimator,
                      trim_model = TRUE,
                      price_field = price_field,
                      #max_period = mp,
                      smooth = TRUE) %>%
    ind2stl(.)
  
  gc()
  agg_hpi$model$approach <- 'agg'
  agg_hpi$model$class <- 'agg'
  
  
  if(verbose) cat('..Calculating Index Series.\n')
  agg_series <- createSeries(hpi_obj = agg_hpi,
                             train_period = exp_obj$train_period,
                             #max_period = mp,
                             smooth = TRUE,
                             price_field = price_field)
  
  if(verbose) cat('..Calculating Index Revision.\n')
  agg_series <- calcRevision(series_obj = agg_series,
                             in_place = TRUE,
                             in_place_name = 'revision')
  
  if(verbose) cat('..Calculating Series Predictive Accuracy.\n')
  agg_series <- calcSeriesAccuracy(series_obj = agg_series,
                                   test_method = 'forecast',
                                   test_type = 'rt',
                                   pred_df = exp_obj$rt_df,
                                   smooth = FALSE,
                                   in_place = TRUE,
                                   in_place_name = 'pr_accuracy')
  
  if(verbose) cat('..Calculating Series Relative Predictive Accuracy.\n')
   agg_hedaccr <- list()
  
  for (ti in 1:(length(agg_series$hpis)-1)) {
    agg_hedaccr[[ti]] <- getHedFitAccuracy(agg_series$hpis[[ti]],
                                           exp_obj,
                                           model_class = 'lm')
  }
  agg_series$hed_praccr <- dplyr::bind_rows(agg_hedaccr)
  
  if(verbose) cat('..Cleaning Up.\n')
  agg_hpi$data <- NULL
  agg_hpi$model <- NULL
  gc()
  
  agg_series$data <- NULL
  agg_series$hpis <- NULL
  gc()
  
  return(
    list(
      index = agg_hpi,
      series = agg_series
    )
  )
}







  
  
  


  