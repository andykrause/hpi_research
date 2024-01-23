#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, index only results
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
  
### Read in Data ------------------------------------------------------------------------------  
  
  # Set Experiment Setup to use
  exp <- 'exp_10'
  
  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
  py_df <- read.csv(file = file.path(getwd(), 'data', exp, 'exp_results_py.csv'))
  
  # Set Parameters
  vol_window <- 3
  
  ## Create imputation data set
  uni_df <- homes_df %>%
    dplyr::sample_frac(., .1)
  
### Aggregate Indexes ----------------------------------------------------------------  
  
  # Add price/sfqf
  exp_$hed_df <- exp_$hed_df %>%
    dplyr::mutate(ppsf = round(price / sqft, 0))
  
  ## Get Aggregate index
  agg_index <- aggIndex(trans_df = exp_$hed_df,
                  estimator = 'median') %>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)
  
  ## Create PPSF Index
  ppsf_index <- aggIndex(trans_df = exp_$hed_df,
                         estimator = 'median',
                         price_field = 'ppsf') %>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)

### Extraction Indexes ---------------------------------------------------------------------  
  
  ## Create RT Index
  rt_index <- rtIndex(trans_df = exp_$rt_df,
                      estimator = 'robust',
                      log_dep = TRUE,
                      max_period = max(exp_$rt_df$period_2)) %>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE) 
  
  ## Create Hedonic Index
  hed_index <- hedIndex(trans_df = exp_$hed_df,
                        estimator = 'robust',
                        log_dep = TRUE,
                        dep_var = 'price',
                        ind_var = exp_$ind_var,
                        trim_model = TRUE,
                        max_period = max(exp_$hed_df$trans_period),
                        smooth = FALSE)%>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)
  
  nn_index <- structure(
    list(data = NULL,
    model = list(estimator = 'znn',
                                mod_spec = NULL,
                                approach = 'nn', 
                                log_dup = TRUE,
                                coefficents =  py_df %>%
                                  dplyr::filter(time == 10 & model == 'nn') %>%
                                  dplyr::select(time_period = time,
                                                coefficient = value) %>%
                                  dplyr::mutate(coefficient = (coefficient / 100) - 1)),
                   index = list(name = agg_index$index$name,
                                period = agg_index$index$period,
                                value = ts(py_df %>%
                                             dplyr::filter(time == 10 & model == 'nn') %>%
                                             dplyr::select(value) %>%
                                             unlist() %>%
                                             as.numeric(), 1, 120),
                                imputed = rep(0, 120))),
    class = 'hpi') %>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)

### Imputation Indexes ---------------------------------------------------------------------  
  
  ## Create Hedonic Index
  hedimp_index <- hedIndex(trans_df = exp_$hed_df,
                   estimator = 'impute',
                   log_dep = TRUE,
                   dep_var = 'price',
                   ind_var = exp_$ind_var,
                   trim_model = TRUE,
                   max_period = max(exp_$hed_df$trans_period),
                   smooth = FALSE,
                   sim_df = exp_$hed_df %>%
                     dplyr::filter(submarket != 'H')) %>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)
  hedimp_index$model$approach <- 'hedimp'
  

  
  # Create RF Index
  rfimp_index <- rfIndex(trans_df = exp_$hed_df,
                estimator = 'chain',
                log_dep = TRUE,
                dep_var = 'price',
                ind_var = exp_$ind_var,
                trim_model = TRUE,
                ntrees = exp_$rf_par$ntrees,
                sim_per = exp_$rf_par$sim_per,
                max_period = max(exp_$hed_df$trans_period),
                smooth = FALSE,
                min.bucket = exp_$rf_par$min_bucket,
                always.split.variables = 
                  exp_$rf_par$always_split_variables,
                sim_df = uni_df)%>%
    calcVolatility(.,
                   window = vol_window,
                   in_place = TRUE)
  rfimp_index$model$approach <- 'rf_imp'
    
### Make Plots ----------------------------------------------------------------------------  
  
 ## Extract all index objects  
  idx <- ls()[grepl('_index', ls())]
  indexes_ <- list()
  for (i in 1:length(idx)){
    indexes_[[i]] <- get(idx[i])
  }
  
  # Into a data.frame
  index_df <- purrr::map(.x = indexes_,
                         .f = function(x){
                           x = periodOverPeriod(x)
                           data.frame(approach = x$model$approach,
                                      time = 10, 
                                      time_period = x$index$period,
                                      month = x$index$name,
                                      index = as.numeric(x$index$value),
                                      MoM = round(x$index$PoP, 3),
                                      mean_vol = x$index$volatility$mean,
                                      med_vol = x$index$volatility$median)
                         }) %>%
    dplyr::bind_rows(.)
  
  ggplot(index_df %>%
           dplyr::filter(approach == 'agg'),
         aes(x = time_period, y = index, color = approach, group = approach)) + 
    geom_line()
  
  ggplot(index_df %>%
           dplyr::filter(approach %in% c('agg', 'agg_ppsf')),
         aes(x = time_period, y = index, color = approach, group = approach)) +
    scale_color_manual(values = c('gray70', 'orange')) +
    geom_line()
  
  ggplot(index_df %>%
           dplyr::filter(approach %in% c('agg', 'agg_ppsf', 'rt')),
         aes(x = time_period, y = index, color = approach, group = approach)) +
    scale_color_manual(values = c('gray70', 'gray70', 'cornflowerblue')) +
    geom_line()
  
  ggplot(index_df %>%
           dplyr::filter(approach %in% c('agg', 'agg_ppsf', 'rt', 'hed')),
         aes(x = time_period, y = index, color = approach, group = approach)) +
    scale_color_manual(values = c('gray70', 'gray70', 'blue3', 'gray70')) +
    geom_line()

  ggplot(index_df %>%
           dplyr::filter(approach %in% c('agg', 'agg_ppsf', 'rt', 'hed', 'nn', 
                                         'hedimp')),
         aes(x = time_period, y = index, color = approach, group = approach)) +
    scale_color_manual(values = c('gray70', 'gray70', 'gray70', 'orchid', 'gray70', 'gray70')) +
    geom_line()
  
  ggplot(index_df %>%
           dplyr::filter(approach %in% c('agg', 'agg_ppsf', 'rt', 'hed', 'nn', 
                                         'hedimp', 'rfimp')),
         aes(x = time_period, y = index, color = approach, group = approach)) +
    scale_color_manual(values = c('gray70', 'gray70', 'gray70', 'gray70', 
                                  'gray70', 'purple','gray70')) +
    geom_line()
  
 ## Volatility Plots and Calcs
  
  ggplot(index_df,
         aes(x = approach, y = mean_vol)) +
    geom_point()
  
  ## Running Volatility
  rvol_df <- purrr::map(.x = indexes_,
                         .f = function(x){
                           data.frame(approach = x$model$approach,
                                      time = 10, 
                                      time_period = x$index$period[-c(1,2, 120)],
                                      month = x$index$name[-c(1,2, 120)],
                                      vol = x$index$volatility$roll)
                         }) %>%
    dplyr::bind_rows(.)
  
  mom_df <- index_df %>%
    dplyr::group_by(time_period) %>%
    dplyr::summarize(mom_agg = mean(MoM))
  
  ggplot(rvol_df,
         aes(x = time_period, y = vol, color = approach, group = approach)) +
    geom_smooth()
  
  g <- rvol_df %>%
    dplyr::left_join(index_df %>%
                       dplyr::select(time_period, approach, MoM), 
                     by = c('time_period', 'approach'))
  
  ggplot(g, aes(x = abs(MoM), y = vol, color = approach)) + geom_point(alpha=.2) + geom_smooth(se=FALSE)
  
  x <- ts(nn_index$index$value, start = 1, end = 10, frequency = 12)
  y <- stl(x, s.window = 'periodic')
  plot(y)
  
  y$trend
  
  iv <- zoo::rollapply(y$time.series[,3], 3, stats::sd)
  mean(iv)
  
### Imputation ---------------------------------------------------------------------------  
   
 
 
  
  
  
  # # Create RF Index
  # rf2 <- rfIndex(trans_df = exp_$hed_df,
  #               estimator = 'pdp',
  #               log_dep = TRUE,
  #               dep_var = 'price',
  #               ind_var = exp_$ind_var,
  #               trim_model = TRUE,
  #               ntrees = exp_$rf_par$ntrees,
  #               sim_per = exp_$rf_par$sim_per,
  #               max_period = max(exp_$hed_df$trans_period),
  #               smooth = FALSE,
  #               min.bucket = exp_$rf_par$min_bucket,
  #               always.split.variables = 
  #                 exp_$rf_par$always_split_variables,
  #               sim_df = uni_df)
  # rf2$model$approach <- 'rf_imp2'
  # 
  
  ggplot(index_df %>%
           dplyr::filter(approach == 'agg'),
         aes(x = time_period, y = index, color = approach, group = approach)) + 
    geom_line() + 
    ylab('Price Index\n(Jan 2019 = 100)\n') + 
    xlab('') + 
    scale_x_continuous(breaks = seq(1, 61, 12),
                       labels = 2019:2024) + 
    theme(legend.position = 'right') + 
    scale_color_manual(name = 'Method',
                      values = c("red"),
                      labels = 'Aggregate (Median)')
  

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  