#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#.   Extract data from multiple files for easier plotting and analysis
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Setup ------------------------------------------------------------------------------------------

 ## Load libraries
  library(tidyverse)

### Load and extract -------------------------------------------------------------------------------

 exps <- c('exp_5', 'exp_10', 'exp_20')
 #exps <- 'exp_10'
 ## Get file names
 
  index_ <- list()
 
  lf <- list() 
  for (i in exps){
    ff <- list.files(file.path(getwd(), 'data', i))
    ff <- ff[grepl('results', ff)]
    for (f in ff){
      x_ <- readRDS(file.path(getwd(), 'data', i, f))
      if (grepl('sub', f)){
        x_$index <- purrr::map(.x = x_,
                               .f = function(x){
                                 x$index
                               }) %>%
          dplyr::bind_rows()
      }
      index_[[length(index_)+1]] <- x_$index     
    }
  }

  index_df <- index_ %>% dplyr::bind_rows()

  ggplot(index_df %>%
           dplyr::filter(exp == 'exp_5' & 
                           partition == 'all'),
         aes(x=period, y = value, group = model, color = model)) + 
    geom_line() + 
    ggtitle('2019 thru 2023 Indexes')
  
  ggplot(index_df %>%
           dplyr::filter(exp == 'exp_10' & 
                           partition == 'all'),
         aes(x=period, y = value, group = model, color = model)) + 
    geom_line() + 
    ggtitle('2014 thru 2023 Indexes')
  
  
  
  
  ggplot(index_df %>%
           dplyr::filter(exp == 'exp_5' & 
                           partition == 'C'),
         aes(x=period, y = value, group = model, color = model)) + 
    geom_line()
  
  
  
  
  
 ## Set up capture lists
  
  index_ <- list()
  series_ <- list()

 ## Read in data and extract
  
  for (i in lf){
  
  data_name <- i
  
  if (grepl('RDS', data_name) & !grepl('data', data_name)){
    
    cat('Processing: ', data_name, '\n\n')
    
    x_ <- readRDS(file.path(getwd(), 'data', data_name))
    data_j <- gsub('[.RDS]', '', data_name)
    data_i <- unlist(str_split(data_j, '_'))
    
    if(grepl('index', data_name)){
      
      index_df <- cbind(name = x_$index$name, period = x_$index$period, value = x_$index$value, 
                        imputed = x_$index$imputed) %>%
        as.data.frame()
      
      index_df$model <- data_i[2]
      x_$index$is_accuracy$model <- data_i[2]
      x_$index$kf_accuracy$model <- data_i[2]
      x_$index$volatility$model <- data_i[2]
      
      index_df$time <- data_i[3]
      x_$index$volatility$time <- data_i[3]
      x_$index$is_accuracy$time <- data_i[3]
      x_$index$kf_accuracy$time <- data_i[3]
      
      index_df$sm <- data_i[4]
      x_$index$volatility$sm <- data_i[4]
      x_$index$is_accuracy$sm <- data_i[4]
      x_$index$kf_accuracy$sm <- data_i[4]
      
      index_df$sm_id <- data_i[5]
      x_$index$volatility$sm_id <- data_i[5]
      x_$index$is_accuracy$sm_id <- data_i[5]
      x_$index$kf_accuracy$sm_id <- data_i[5]
      
      x_$index$index <- index_df
      index_[[data_j]] <- x_$index
      
    } 
  
    if(grepl('series', data_name)){
      
      x_$revision$model <- data_i[2]
      x_$pr_accuracy$model <- data_i[2]
      x_$volatility$model <- data_i[2]
    
      x_$revision$time <- data_i[3]
      x_$pr_accuracy$time <- data_i[3]
      x_$volatility$time <- data_i[3]
    
      x_$revision$sm <- data_i[4]
      x_$pr_accuracy$sm <- data_i[4]
      x_$volatility$sm <- data_i[4]
      
      x_$revision$sm_id <- data_i[5]
      x_$pr_accuracy$sm_id <- data_i[5]
      x_$volatility$sm_id <- data_i[5]
      
      series_[[data_j]] <- x_
    }
  }
}

  ## Convert/Transform
  
  # Indexes
  ind_df <- purrr::map(.x = index_,
                       .f = function(x){
                         x$index
                       }) %>%
    dplyr::bind_rows() %>%
    dplyr::mutate(value = as.numeric(value),
                  period = as.numeric(period))


  # In Sample accuracy
  is_accr <- purrr::map(.x = index_,
                        .f = function(x){
                           x$is_accuracy
                       }) %>%
    dplyr::bind_rows()

  # K-fold accuracy
  kf_accr <- purrr::map(.x = index_,
                        .f = function(x){
                           x$kf_accuracy
                        }) %>%
    dplyr::bind_rows()

  # Prediction accuracy
  pr_accr <- purrr::map(.x = series_,
                        .f = function(x){
                          x$pr_accuracy
                        }) %>%
    dplyr::bind_rows()

  # Revisions
  revision <- purrr::map(.x = series_,
                         .f = function(x){
                           x$revision
                          }) 

  # Index Vol
  ind_vol <- purrr::map(.x = index_,
                        .f = function(x){
                          x$volatility
                        })
  
  # Series Vol
  ser_vol <- purrr::map(.x = series_,
                        .f = function(x){
                          x$volatility
                        })
  
  
### Write the data ---------------------------------------------------------------------------------  
  
if(!file.exists(file.path(getwd(), 'data', 'cleaned'))){
  dir.create(file.path(getwd(), 'data', 'cleaned'))
}

saveRDS(ind_df, file = file.path(getwd(), 'data', 'cleaned', 'indexes.RDS'))
saveRDS(is_accr, file = file.path(getwd(), 'data', 'cleaned', 'is_accuracies.RDS'))
saveRDS(pr_accr, file = file.path(getwd(), 'data', 'cleaned', 'pr_accuracies.RDS'))
saveRDS(kf_accr, file = file.path(getwd(), 'data', 'cleaned', 'kf_accuracies.RDS'))
saveRDS(revision, file = file.path(getwd(), 'data', 'cleaned', 'revisions.RDS'))
saveRDS(ind_vol, file = file.path(getwd(), 'data', 'cleaned', 'index_volatilities.RDS'))
saveRDS(ser_vol, file = file.path(getwd(), 'data', 'cleaned', 'series_volatilities.RDS'))

#####


fig1_df <- ind_df %>%
  dplyr::filter(time == 5 & 
                  sm == 'county')

ggplot(fig1_df, aes(x = period, y = value, group = model, color = model, linetype = model,
                             size = model)) + 
  geom_line() +
  scale_size_manual(values = c(0.5, 1, 1.5), guide = 'none') + 
  scale_linetype_manual(values = c(1, 1, 1), guide = 'none') +
  scale_color_manual(name = '', values = c('black', 'gray70', 'red')) +
  scale_x_continuous(breaks = seq(1, 132, 12), labels = 2012:2022) +
  xlab('') + 
  ylab('House Price Index \n') + 
  #ggtitle('Comparison of Indexes')+
  theme(legend.position = 'bottom',
        plot.title = element_text(hjust = 0.5))

tbl1_df <- kf_accr %>% dplyr::filter(time == 10, sm == 'county')
tbl1_df %>% dplyr::group_by(model) %>%
  dplyr::summarize(mdpe = median(log_error),
                   mdape = median(abs(log_error)))

print_df <- results_$accr_g %>%
  dplyr::mutate(Model = c('Hedonic Price', 'Interpretable Random Forest', 'Repeat Sales')) %>%
  dplyr::rename(`MdAPE (k-fold)` = MAPE_KF, `MdPE (k-fold)` = MPE_KF,
                `MdAPE (forecast)` = MAPE_PR, `MdPE (forecast)` = MPE_PR)
print_df$Model <- forcats::fct_relevel(print_df$Model, 'Repeat Sales', 'Hedonic Price')
knitr::kable(print_df %>% dplyr::arrange(Model))

  







