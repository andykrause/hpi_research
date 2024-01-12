#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Experiments on 5 year feature comparisons
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

 ## Load libraries

  library(tidyverse)
  library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

 ## Load custom functions  
  source(file.path(getwd(), 'functions', 'wrapper_function.R'))

### Load Five year data ----------------------------------------------------------------------  

  # Set Experiment Setup to use
  exp <- 'exp_5'

  # Read in experiment object (includes pre-filtered data)
  exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

  ## Run analysis for each submarket -

  models <- 'rf'
  partition <- 'all'
  exp_$partition <- partition
  exp_$min_bucket <- 5
  exp_$always_split_variables <- 'trans_period'
  exp_$ntrees <- 300
  exp_$sim_per <- .10
  exp_$model <- 'rf'
  
  ind_var1 <- c('sqft', 'beds', 'baths')
  ind_var2 <- c('use', 'grade', 'sqft', 'beds', 'baths', 'sqft_lot')
  ind_var3 <- c('use', 'grade', 'sqft', 'age')
  ind_var4 <- c('use', 'grade', 'sqft', 'submarket')
  ind_var5 <- c('use', 'grade', 'sqft', 'latitude', 'longitude')
  ind_var6 <- c('use', 'grade', 'sqft', 'beds', 'baths', 'sqft_lot', 'age')
  ind_var7 <- c('use', 'grade', 'sqft', 'beds', 'baths', 'sqft_lot', 'age', 'submarket')
  ind_var8 <- c('use', 'grade', 'sqft', 'beds', 'baths', 'sqft_lot', 'age', 'submarket',
                'longitude', 'latitude')
  
  ind_var_ <- list(ind_var1, ind_var2, ind_var3, ind_var4, ind_var5,
                   ind_var6, ind_var7, ind_var8)
  results_ <- list()
  
  for (i in 1:length(ind_var_)){
    exp_$ind_var <- ind_var_[[i]]
  
    cat('------ Independent Variable Set: ', i, '------\n')
  
    results_[[i]] <- expWrapper(exp_obj = exp_,
                                partition = 'all', 
                                index_only = TRUE) %>% 
      dplyr::mutate(model = paste0('rf_', i),
                    fs = i,
                    asv = exp_$always_split_variables)
  }

  index_df <- results_ %>%
    dplyr::bind_rows()
  
  ggplot(index_df,
         aes(x = period, y = value, color = model, group=model)) + 
    geom_line()
  
### Remove forced splits
  
  exp_$always_split_variables <- NULL
  
  resultsx_ <- list()
  
  for (i in 1:length(ind_var_)){
    exp_$ind_var <- ind_var_[[i]]
    
    cat('------ Independent Variable Set: ', i, '------\n')
    
    resultsx_[[i]] <- expWrapper(exp_obj = exp_,
                                partition = 'all', 
                                index_only = TRUE) %>% 
      dplyr::mutate(model = paste0('rfu_', i),
                    fs = i,
                    asv = exp_$always_split_variables)
  }
  
  indexx_df <- index_df %>% dplyr::bind_rows(., resultsx_) 
  indexx_df$mom <- c(0, (indexx_df$value[-1] - indexx_df$value[nrow(indexx_df)]) / 
                       indexx_df$value[nrow(indexx_df)])
  
  indexx_df$mom <- ifelse(indexx_df$period == 1, 0, indexx_df$mom)
  
  diff_ <- split(indexx_df, indexx_df$fs)
  for (k in 1:length(diff_)){
    
    Reduce(f = `-`,
           x = list(diff_[[k]]$value[31:60], diff_[[k]]$value[1:30])) -> g
    diff_[[k]]$diff <- c(g,g)/diff_[[k]]$value[1:30]
  
    Reduce(f = `-`,
           x = list(diff_[[k]]$mom[31:60], diff_[[k]]$mom[1:30])) -> g
    diff_[[k]]$mdiff <- c(g,g)/diff_[[k]]$mom[1:30]
    
  }
  indexx_df <- diff_ %>% dplyr::bind_rows()  
  
  ggplot(indexx_df,
         aes(x = period, y = value, color = fs, group=model)) + 
    facet_wrap(~asv) + 
    geom_line()

  ggplot(indexx_df,
         aes(x = mom, y = diff, color = fs, group=model)) + 
    facet_wrap(~asv) + 
    geom_point()
  
  
  ggplot(indexx_df,
         aes(x = period, y = diff, color = fs, group=model)) + 
    facet_wrap(~asv) + 
    geom_point()
  
  
  
  
  ggplot(indexx_df,
         aes(x = mdiff, y = diff, color = fs, group=model)) + 
    facet_wrap(~asv) + 
    geom_point()
  
    
  ggplot(indexx_df,
         aes(x = period, y = mdiff, color = asv, group=model)) + 
    facet_wrap(~fs) + 
    geom_line()
  