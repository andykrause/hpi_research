
expWrapper <- function(exp_obj,
                       partition = 'all',
                       verbose = TRUE,
                       estimator = 'robust',
                       log_dep = TRUE,
                       trim_model = TRUE,
                       vol_window = 3,
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
                       ntrees = 200,
                       sim_per = exp_obj$sim_per,
                       max_period = max(exp_obj$hed_df$trans_period),
                       smooth = TRUE,
                       min.bucket = exp_obj$min_bucket,
                       always.split.variables = 
                         exp_obj$always_split_variables)
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

calculateRelAccr <- function(series_obj,
                             exp_obj){
  
  hedaccr_ <- list()
  for (ti in 1:(length(series_obj$hpis)-1)) {
    hedaccr_[[ti]] <- getHedFitAccuracy(series_obj$hpis[[ti]],
                                        exp_obj)
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

  
  
  
  


  