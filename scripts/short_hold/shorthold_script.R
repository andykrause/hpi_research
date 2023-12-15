#***************************************************************************************************
#
#     Analysis
#
#***************************************************************************************************

 # Set paths
  base_path <- '~/projects/ml_hpi_research/'
  
  # Source helper functions
  source(file.path(base_path, 'scripts', 'short_hold', 'shorthold_functions.R'))      
  
  # Load Data
  seattle_sales <- read.csv(file.path(base_path, 'data', 'short_hold', 'seattlesales.csv'))

  # Load Libraries
  library(hpiR)
  library(magrittr)
  library(tidyverse)
  library(ggplot2)
  library(ggridges)

## Data Prep ---------------------------------------------------------------------------------------  

  sales_df <- seattle_sales %>%
    dplyr::mutate(eff_age = sale_year - pmax(year_built, year_reno)) %>% 
    dplyr::filter(!grepl('rebuilt', match_type) & 
                    !grepl('reno', match_type) & 
                    sale_price > 50000 & 
                    units == 1 & 
                    eff_age >= 0)

### Full Time Period Analysis ----------------------------------------------------------------------  
 
  full_sg <- steeleGoy(sales_df) 
  
  ggplot(full_sg$indexes, aes(x = time, y = index, group = model, color = model)) + 
    geom_line() +
    scale_x_continuous(breaks = seq(1, 253, by = 12), labels = 1999:2020) +
    scale_color_manual(name = "Model Type", values = c('red', 'maroon', 'orange','black')) + 
    ylab('Index Value\n') + 
    xlab('\nTime') + 
    theme(legend.position = 'bottom')
  
  ggplot(full_sg$hed_df, aes(x=trans_period, y = status, color = status)) +
    geom_density_ridges(scale=3, alpha = .4) +
    theme_ridges() +
    scale_y_discrete(expand = c(0.1,0)) + 
    scale_x_continuous(breaks = seq(1, 241, by = 24), labels = seq(1999,2019,by=2)) + 
    scale_color_manual(name = 'Sale Status', values = c('gray10', 'darkgreen', 'blue', 'red')) + 
    theme(legend.position = 'none') + 
    xlab('') + 
    ylab('') + 
    ggtitle('Sale Volume by Repeat Sale Order')
  
### Short Time Period Analysis ---------------------------------------------------------------------
  
  ## Short
  short_sg <- steeleGoy(sales_df %>% dplyr::filter(sale_date > as.Date('2016-09-30'))) 
  
  ggplot(short_sg$indexes, aes(x = time, y = index, group = model, color = model)) + 
    geom_line() +
    scale_x_continuous(breaks = seq(4,48, by = 12), labels = 2017:2020) +
    scale_color_manual(name = "Model Type", values = c('red', 'maroon', 'orange','black')) + 
    xlab('Index Value\n') + 
    ylab('\nTime') + 
    theme(legend.position = 'bottom')
  
  ggplot(short_sg$hed_df, aes(x=trans_period, y = status, color = status)) +
    geom_density_ridges(scale=3, alpha = .4) +
    theme_ridges() +
    scale_y_discrete(expand = c(0.1,0)) + 
    scale_x_continuous(breaks = seq(4, 48, by = 12), labels = 2017:2020) + 
    scale_color_manual(name = 'Sale Status', values = c('gray10', 'darkgreen', 'blue', 'red')) + 
    theme(legend.position = 'none') + 
    xlab('') + 
    ylab('') + 
    ggtitle('Sale Volume by Repeat Sale Order')
  
### Time period 1 (Runup 1) ------------------------------------------------------------------------    

  time1_sg <- steeleGoy(sales_df %>% dplyr::filter(sale_date <= as.Date('2007-07-31'))) 
  
  ggplot(time1_sg$indexes, aes(x = time, y = index, group = model, color = model)) + 
    geom_line() +
    scale_x_continuous(breaks = seq(1, 108, by = 12), labels = 1999:2007) +
    scale_color_manual(name = "Model Type", values = c('red', 'maroon', 'orange','black')) + 
    xlab('Index Value\n') + 
    ylab('\nTime') + 
    theme(legend.position = 'bottom')
  
  ggplot(time1_sg$hed_df, aes(x=trans_period, y = status, color = status)) +
    geom_density_ridges(scale=3, alpha = .4) +
    theme_ridges() +
    scale_y_discrete(expand = c(0.1,0)) + 
    scale_x_continuous(breaks = seq(1, 108, by = 12), labels = 1999:2007) +
    scale_color_manual(name = 'Sale Status', values = c('gray10', 'darkgreen', 'blue', 'red')) + 
    theme(legend.position = 'none') + 
    xlab('') + 
    ylab('') + 
    ggtitle('Sale Volume by Repeat Sale Order')
  
### Time Period 2 (Crash) --------------------------------------------------------------------------  
  
  time2_sg <- steeleGoy(sales_df %>% 
                         dplyr::filter(sale_date > as.Date('2007-07-31') & 
                                         sale_date <= as.Date('2011-01-31'))) 
  
  ggplot(time2_sg$indexes, aes(x = time, y = index, group = model, color = model)) + 
    geom_line() +
    scale_x_continuous(breaks = seq(6,42, by = 12), labels = 2008:2011) +
    scale_color_manual(name = "Model Type", values = c('red', 'maroon', 'orange','black')) + 
    ylab('Index Value\n') + 
    xlab('\nTime') + 
    theme(legend.position = 'bottom')
  
  ggplot(time2_sg$hed_df, aes(x=trans_period, y = status, color = status)) +
    geom_density_ridges(scale=3, alpha = .4) +
    theme_ridges() +
    scale_y_discrete(expand = c(0.1,0)) + 
    scale_x_continuous(breaks = seq(6,42, by = 12), labels = 2008:2011) +
    scale_color_manual(name = 'Sale Status', values = c('gray10', 'darkgreen', 'blue', 'red')) + 
    theme(legend.position = 'none') + 
    xlab('') + 
    ylab('') + 
    ggtitle('Sale Volume by Repeat Sale Order')
  
### Time Period 3 (Recovery to Now) ----------------------------------------------------------------  
  
  ## Before GFC
  time3_sg <- steeleGoy(sales_df %>% 
                         dplyr::filter(sale_date > as.Date('2011-01-31'))) 

  ggplot(time3_sg$indexes, aes(x = time, y = index, group = model, color = model)) + 
    geom_line() +
    scale_x_continuous(breaks = seq(11,107, by = 12), labels = 2012:2020) +
    scale_color_manual(name = "Model Type", values = c('red', 'maroon', 'orange','black')) + 
    xlab('Index Value\n') + 
    ylab('\nTime') + 
    theme(legend.position = 'bottom')
  
  ggplot(time3_sg$hed_df, aes(x=trans_period, y = status, color = status)) +
    geom_density_ridges(scale=3, alpha = .4) +
    theme_ridges() +
    scale_y_discrete(expand = c(0.1,0)) + 
    scale_x_continuous(breaks = seq(11,107, by = 12), labels = 2012:2020) +
    scale_color_manual(name = 'Sale Status', values = c('gray10', 'darkgreen', 'blue', 'red')) + 
    theme(legend.position = 'none') + 
    xlab('') + 
    ylab('') + 
    ggtitle('Sale Volume by Repeat Sale Order')
  
### Revision Analysis  
  
  rev_df <- expand.grid(2002:2019, c('01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'))
  rev_dates <- sort(as.Date(paste0(rev_df$Var1, '-', rev_df$Var2, '-01')))[1:213]
  rev_ <- list()
  for(i in 1:length(rev_dates)){
    rev_[[i]] <- steeleGoy(sales_df %>% dplyr::filter(sale_date < rev_dates[i]))$index
    rev_[[i]]$date <- rev_dates[i]
  }
  
  rev_df <- rev_ %>% dplyr::bind_rows() %>%
    dplyr::filter(time > 1 & time < 237) %>%
    dplyr::group_by(time, model) %>%
    dplyr::summarize(sd = sd(index))
  
  ggplot(rev_df, aes(x = time, y = sd, group = model, color = model)) +
    geom_point(alpha = .4) + 
    geom_smooth() + 
    scale_color_manual(values = c('red', 'blue', 'purple', 'black'))
  
  # Pick select 6-7 select periods and measure their revision
  # early24, mid rise65, peak100, mid decline125, trough150, mid rise200, recent235
  
### Span Analysis ---------------------------------------------------------------------------------- 
  
  # Set Dates
  span_dates <- as.Date(paste0(1999:2019, '-01-01'))
  dgrid <- expand.grid(span_dates, span_dates) %>%
    dplyr::mutate(dif = as.numeric(Var2 - Var1)) %>%
    dplyr::filter(dif >= 365 * 2)
  
  ## Monthly estimates
  sgm_ <- list()
  for (i in 1:nrow(dgrid)){
    cat(i)  
    data_df <- sales_df %>% dplyr::filter(sale_date >= dgrid$Var1[i] & 
                                            sale_date < dgrid$Var2[i])
    sgm_[[i]] <- data.frame(dif = dgrid$dif[i] / 365,
                           gamma = as.numeric(steeleGoy(data_df)$gamma))
  }
  
  gammaM_df <- dplyr::bind_rows(sgm_) %>%
    dplyr::mutate(start = dgrid$Var1,
                  end = dgrid$Var2,
                  exp = 1:nrow(.))
  
  ggplot(gammaM_df, aes(x = dif, y = gamma)) +
    geom_point() + 
    geom_smooth()
  
  gammaspanM_df <- gammaM_df %>%
    tidyr::gather(key = 'time', value = 'year', -c(dif, gamma, exp)) %>%
    dplyr::mutate(dif = floor(dif),
                  span = paste0('Time Span: ', ifelse(dif <= 9, as.character(dif), '10+'))) %>%
    dplyr::mutate(span = forcats::fct_relevel(span, 'Time Span: 2', 'Time Span: 3','Time Span: 4',
                                              'Time Span: 5', 'Time Span: 6','Time Span: 7',
                                              'Time Span: 8', 'Time Span: 9'))
  
  ggplot(gammaspanM_df, aes(x = year, y = gamma, group = exp, color = time)) + 
    geom_point() +
    geom_line(size = 1, color = 'gray30', alpha = .4) + 
    facet_wrap(~span, ncol = 3)
  
  ## Quarterly Estimates
  
  sgq_ <- list()
  for (i in 1:nrow(dgrid)){
    cat(paste0(i, ' '))  
    data_df <- sales_df %>% dplyr::filter(sale_date >= dgrid$Var1[i] & 
                                            sale_date < dgrid$Var2[i])
    sgq_[[i]] <- data.frame(dif = dgrid$dif[i] / 365,
                            gamma = as.numeric(steeleGoy(data_df, aggregation = 'quarterly')$gamma))
  }

  gammaQ_df <- dplyr::bind_rows(sgq_) %>%
    dplyr::mutate(start = dgrid$Var1,
                  end = dgrid$Var2,
                  exp = 1:nrow(.))
  
  ggplot(gammaQ_df, aes(x = dif, y = gamma)) +
    geom_point() + 
    geom_smooth()
  
  gammaspanQ_df <- gammaQ_df %>%
    tidyr::gather(key = 'time', value = 'year', -c(dif, gamma, exp)) %>%
    dplyr::mutate(dif = floor(dif),
                  span = paste0('Time Span: ', ifelse(dif <= 9, as.character(dif), '10+'))) %>%
    dplyr::mutate(span = forcats::fct_relevel(span, 'Time Span: 2', 'Time Span: 3','Time Span: 4',
                                              'Time Span: 5', 'Time Span: 6','Time Span: 7',
                                              'Time Span: 8', 'Time Span: 9'))
  
  ggplot(gammaspanQ_df, aes(x = year, y = gamma, group = exp, color = time)) + 
    geom_point() +
    geom_line(size = 1, color = 'gray30', alpha = .4) + 
    facet_wrap(~span, ncol = 3)
  
  ## Combine Gamma Data
  
  gamma_df <- dplyr::bind_rows(gammaM_df %>% dplyr::mutate(aggr = 'month'),
                               gammaQ_df %>% dplyr::mutate(aggr = 'quarter'))
  gammaspan_df <- dplyr::bind_rows(gammaspanM_df %>% dplyr::mutate(aggr = 'month'),
                                   gammaspanQ_df %>% dplyr::mutate(aggr = 'quarter'))

### Save into a results object----------------------------------------------------------------------
  
  results_ <- list(full = list(index = full_sg$indexes,
                               hed = full_sg$hed_df,
                               rt = full_sg$rt_df,
                               gamma = full_sg$gamma),
                   time1 = list(index = time1_sg$indexes,
                                hed = time1_sg$hed_df,
                                rt = time1_sg$rt_df,
                                gamma = time1_sg$gamma),
                   time2 = list(index = time2_sg$indexes,
                                hed = time2_sg$hed_df,
                                rt = time2_sg$rt_df,
                                gamma = time2_sg$gamma),
                   time3 = list(index = time3_sg$indexes,
                                hed = time3_sg$hed_df,
                                rt = time3_sg$rt_df,
                                gamma = time3_sg$gamma),
                   gamma = gamma_df,
                   gammaspan = gammaspan_df,
                   revision = rev_df)
  
  saveRDS(results_, file.path(base_path, 'data', 'short_hold', 'paper.RDS'))
  
#***************************************************************************************************
#***************************************************************************************************