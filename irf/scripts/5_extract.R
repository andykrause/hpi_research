#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#.   Extract data from multiple files for easier plotting and analysis
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Setup ------------------------------------------------------------------------------------------

 ## Load libraries
  library(tidyverse)

### Set up experiment ------------------------------------------------------------------------------

  exp <- 'exp_5'

 ## Get file names
  
  lf <- list.files(file.path(getwd(), 'data', exp))
  lf <- lf[grepl('results', lf)]

### County Level -----------------------------------------------------------------------------------  

  ## Set up capture lists
  
  index_ <- list()
  series_ <- list()
  lfc <- lf[!grepl('subm', lf)]
  
for (i in lfc){
  
  data_name <- i
  cat('Processing: ', data_name, '\n\n')
  
  x_ <- readRDS(file.path(getwd(), 'data', exp, data_name))
  data_j <- gsub('[.RDS]', '', data_name)
  data_i <- unlist(str_split(data_j, '_'))
  
  index_df <- data.frame(name = x_$index$index$name, 
                         period = x_$index$index$period, 
                         value = x_$index$index$value, 
                         imputed = x_$index$index$imputed,
                         model = data_i[1])
  
  x_$index$index$index <- index_df
  
  x_$index$index$is_accuracy$model <- data_i[1]
  x_$index$index$kf_accuracy$model <- data_i[1]
  x_$index$index$volatility$model <- data_i[1]
  
  x_$series$revision$model <- data_i[1]
  x_$series$pr_accuracy$model <- data_i[1]
  x_$series$volatility$model <- data_i[1]
  x_$series$hed_praccr$model <- data_i[1]
  
  index_[[data_i[1]]] <- x_$index
  series_[[data_i[1]]] <- x_$series
}

  # Indexes
  ind_df <- purrr::map(.x = index_,
                       .f = function(x){
                         x$index$index %>%
                           dplyr::select(name, period, value, model)
                       }) %>%
    dplyr::bind_rows()
  

  # In Sample accuracy
  is_accr <- purrr::map(.x = index_,
                        .f = function(x){
                          x$index$is_accuracy
                        }) %>%
    dplyr::bind_rows()
  
  # K-fold accuracy
  kf_accr <- purrr::map(.x = index_,
                        .f = function(x){
                          y <- x$index$kf_accuracy
                          x$kf_accuracy
                        }) %>%
    dplyr::bind_rows()
  
  # Prediction accuracy
  pr_accr <- purrr::map(.x = series_,
                        .f = function(x){
                          x$pr_accuracy
                        }) %>%
    dplyr::bind_rows()
  
  # Prediction accuracy
  hed_accr <- purrr::map(.x = series_,
                         .f = function(x){
                           x$hed_praccr
                         }) %>%
    dplyr::bind_rows()

  # Revisions
  revision <- purrr::map(.x = series_,
                         .f = function(x){
                           data.frame(model = x$revision$model,
                                      mean = x$revision$mean,
                                      median = x$revision$median)
                         }) %>%
    dplyr::bind_rows()
  
  # Index Vol
  ind_vol <- purrr::map(.x = index_,
                        .f = function(x){
                          data.frame(model = x$index$volatility$model,
                                     mean = x$index$volatility$mean,
                                     median = x$index$volatility$median)
                        })%>%
    dplyr::bind_rows()

  cty_summaries <- list(kfa = kf_accr,
                         pra = pr_accr,
                         hpa = hed_accr,
                         rev = revision,
                         ind = ind_df,
                         vol = ind_vol)
  
  saveRDS(cty_summaries, file.path(getwd(), 'data', exp, 'cty_summaries.RDS'))
  
### Submarket --------------------------------------------------------------------------------------
  
  indexS_ <- list()
  seriesS_ <- list()
  
  lfs <- lf[grepl('subm', lf)]
  
  for (i in lfs){
    
    data_name <- i
    cat('Processing: ', data_name, '\n\n')
    x_ <- readRDS(file.path(getwd(), 'data', exp, data_name))
    data_j <- gsub('[.RDS]', '', data_name)
    data_i <- unlist(str_split(data_j, '_'))
     
    i_ <- list()
    s_ <- list()
      
    for (k in names(x_)){
      k_ <- x_[[k]]
      index_df <- cbind(name = k_$index$index$name, 
                        period = k_$index$index$period, 
                        value = k_$index$index$value, 
                        imputed = k_$index$index$imputed) %>%
          as.data.frame()
      index_df$model <- data_i[1]
      index_df$subm <- k
      
      k_$index$index$index <- index_df
      k_$index$index$is_accuracy$model <- data_i[1]
      k_$index$index$is_accuracy$subm <- k
      
      k_$index$index$kf_accuracy$model <- data_i[1]
      k_$index$index$kf_accuracy$subm <- k
      
      k_$index$index$volatility$model <- data_i[1]
      k_$index$index$volatility$subm <- k
      
      k_$series$revision$model <- data_i[1]
      k_$series$revision$subm <- k
      
      k_$series$pr_accuracy$model <- data_i[1]
      k_$series$pr_accuracy$subm <- k
      
      k_$series$volatility$model <- data_i[1]
      k_$series$volatility$subm <- k
      
      k_$series$hed_praccr$model <- data_i[1]
      k_$series$hed_praccr$subm <- k
      
      i_[[k]] <- k_$index
      s_[[k]] <- k_$series
    }
    
    indexS_df <- purrr::map(.x = i_,
                            .f = function(x){
                              g <- x$index$index
                              g$subm <- x$subm
                              g
                          }) %>%
      dplyr::bind_rows() %>%
      dplyr::mutate(period = as.numeric(period),
                    value = as.numeric(value))
    
    kfa_df <- purrr::map(.x = i_,
                            .f = function(x){
                              g <- x$index$kf_accuracy
                              g$subm <- x$index$index$subm[1]
                              g
                            }) %>%
      dplyr::bind_rows() 
    
    volS_df <- purrr::map(.x = i_,
                          .f = function(x){
                           data.frame(subm = x$index$index$subm[1],
                                      mean = x$index$volatility$mean,
                                      median = x$index$volatility$median)
                         }) %>%
      dplyr::bind_rows() %>%
      dplyr::mutate(model = data_i[1])
    
    indexS_[[data_i[1]]] <- list(index = indexS_df,
                                 kfa = kfa_df,
                                 vol = volS_df)

    
    pra_df <- purrr::map(.x = s_,
                         .f = function(x){
                           x$pr_accuracy
                         }) %>%
      dplyr::bind_rows() 
    
    hpa_df <- purrr::map(.x = s_,
                         .f = function(x){
                           x$hed_praccr
                         }) %>%
      dplyr::bind_rows() 
    
    rev_df <- purrr::map(.x = i_,
                        .f = function(x){
                            data.frame(subm = x$revision$subm[1],
                                       mean = x$revision$mean,
                                       median = x$revision$median,
                                       model = x$revision$model)
                          }) %>%
      dplyr::bind_rows() 
    
                                     
    seriesS_[[data_i[1]]] <- list(pra = pra_df,
                                  hpa = hpa_df,
                                  rev = rev_df)
    }
  
  ## Convert/Transform
  indexS_df <- purrr::map(.x = indexS_,
                          .f = function(x){
                            x$index
                          }) %>%
    dplyr::bind_rows()
  
  kfaS_df <- purrr::map(.x = indexS_,
                          .f = function(x){
                            x$kfa
                          }) %>%
    dplyr::bind_rows()
  
  volS_df <- purrr::map(.x = indexS_,
                        .f = function(x){
                          x$vol
                        }) %>%
    dplyr::bind_rows()
  
  praS_df <- purrr::map(.x = seriesS_,
                        .f = function(x){
                          x$pra
                        }) %>%
    dplyr::bind_rows()
  
  hpaS_df <- purrr::map(.x = seriesS_,
                       .f = function(x){
                         x$hpa
                       }) %>%
    dplyr::bind_rows()
  
  revS_df <- purrr::map(.x = seriesS_,
                       .f = function(x){
                         x$revision
                       }) %>%
    dplyr::bind_rows()
  
  subm_summaries <- list(kfa = kfaS_df,
                         pra = praS_df,
                         hpa = hpaS_df,
                         rev = revS_df,
                         ind = indexS_df,
                         vol = volS_df)
  
  saveRDS(subm_summaries, file.path(getwd(), 'data', exp, 'subm_summaries.RDS'))
  
### xxx -----------------------------------------------------------
  
  ggplot(cty_summaries$ind,
         aes(x=period, y=value, color = model), lwd = 3) + 
    geom_line() + 
    ggtitle('Comparison of Indexes\n King County, WA') + 
    scale_color_manual(name = 'Model', 
                       labels = c('Hedonic', 'IRF', 'Repeat Sales'),
                       values = c('Black', 'Purple', 'Orange')) + 
    ylab('Index Value \n (2017 = 100)') + 
    xlab ('Time') + 
    scale_x_continuous(breaks = c(0, 12, 24, 36, 48, 60, 72),
                       labels = 2017:2023) + 
    theme(plot.title = element_text(hjust = 0.5, size = 14),
          legend.position = 'bottom')
  
  
  
  
  cty_summaries$pra %>%
    dplyr::group_by(model) %>%
    dplyr::summarize(mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error))) %>%
    slice(c(3,1,2))
  
  cty_summaries$pra %>%
    dplyr::group_by(model, pred_period) %>%
    dplyr::summarize(mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error))) -> pra_sdf
  
  ggplot(pra_sdf,
         aes(x = pred_period, y = mdpe, color = model)) + 
    geom_line()  +
    ggtitle('Comparison of Absolute Index Errors\n King County, WA') + 
    geom_hline(yintercept = 0, color = 'gray10', linetype = 'dashed') + 
    scale_color_manual(name = 'Model', 
                       labels = c('Hedonic', 'IRF', 'Repeat Sales'),
                       values = c('Black', 'Purple', 'Orange')) + 
    ylab('Median Model Error \n(MdPE)') + 
    xlab ('Time') + 
    scale_x_continuous(breaks = c(12, 24, 36, 48, 60, 72),
                       labels = 2018:2023) + 
    theme(plot.title = element_text(hjust = 0.5, size = 14),
          legend.position = 'bottom')
  
  
  
  
  
  
  
  
  cty_summaries$hpa %>%
    dplyr::group_by(model, type) %>%
    dplyr::summarize(mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))  
  
  
  cty_summaries$hpa %>%
    dplyr::filter(type != 'base') %>%
    dplyr::group_by(model, trans_period) %>%
    dplyr::summarize(mdpe = median(error),
                     mpe = mean(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error))) -> hpa_sdf
  
  ggplot(hpa_sdf,
         aes(x = trans_period, y = mdpe, color = model)) + 
    geom_line()  +
    ggtitle('Comparison of Relative Index Errors\n King County, WA') + 
    geom_hline(yintercept = 0, color = 'gray10', linetype = 'dashed') + 
    scale_color_manual(name = 'Model', 
                       labels = c('Hedonic', 'IRF', 'Repeat Sales'),
                       values = c('Black', 'Purple', 'Orange')) + 
    ylab('Median Model Error \n(MdPE)') + 
    xlab ('Time') + 
    scale_x_continuous(breaks = c(12, 24, 36, 48, 60, 72),
                       labels = 2018:2023) + 
    theme(plot.title = element_text(hjust = 0.5, size = 14),
          legend.position = 'bottom')
  
  
  
  cty_summaries$vol 
  
  %>%
    dplyr::group_by(model) %>%
    dplyr::summarize(mdpe = median(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  
  cty_summaries$rev %>%
    dplyr::group_by(model) %>%
    dplyr::summarize(mdpe = median(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  
  ##
  
  ggplot(subm_summaries$ind,
         aes(x=period, y=value, color = model)) + 
    geom_line() + 
    facet_wrap(~submarket)
  
  subm_summaries$pra %>%
    dplyr::group_by(model) %>%
    dplyr::summarize(mdpe = median(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  
  subm_summaries$hpa %>%
    dplyr::group_by(model, type) %>%
    dplyr::summarize(mdpe = median(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  
  subm_summaries$vol %>%
    dplyr::group_by(model)
  
  cty_summaries$rev %>%
    dplyr::group_by(model) %>%
    dplyr::summarize(mdpe = median(error),
                     mdape = median(abs(error)),
                     mape = mean(abs(error)))
  