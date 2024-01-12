#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Combine all results 
#
#   -- Flatten each metric form all experiments into a single long df
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Setup ------------------------------------------------------------------------------------------

 ## Load libraries
  library(tidyverse)

### Load and extract -------------------------------------------------------------------------------

 ## list Experiments
 exps <- c('exp_5', 'exp_10', 'exp_20')

 ## Setup up capture lists
 
  # For the individual metrics 
  index_ <- indexvol_ <- series_ <- revision_ <- seriesrev_ <- seriesvol_ <- 
     absacc_ <- relacc_ <- list()

  # For loading and counting
  lf <- list()
  exp_count <- 1
  
 ## Loop through all experiments
  for (exp in exps){
    
    # Get list of results files
    allfiles <- list.files(file.path(getwd(), 'data', exp))
    resfiles <- allfiles[grepl('results', allfiles)]
    
    # For each result file, extract all metrics into their own df
    for (res in resfiles){
      cat('Reading file: ', exp, res, '\n\n')
      x_ <- readRDS(file.path(getwd(), 'data', exp, res))
      
      # For any divided by submarket, must do extra flattening
      if (!grepl('all', res)){
        x_$index <- purrr::map(.x = x_,
                               .f = function(x){
                                 x$index
                               }) %>%
          dplyr::bind_rows()
        x_$vol <- purrr::map(.x = x_,
                               .f = function(x){
                                 x$vol
                               }) %>%
          dplyr::bind_rows()
        x_$series <- purrr::map(.x = x_,
                             .f = function(x){
                               x$series
                             }) %>%
          dplyr::bind_rows()
        x_$revision <- purrr::map(.x = x_,
                                .f = function(x){
                                  x$revision
                                }) %>%
          dplyr::bind_rows()
        x_$volS <- purrr::map(.x = x_,
                                  .f = function(x){
                                    x$volS
                                  }) %>%
          dplyr::bind_rows()
        
        x_$absacc <- purrr::map(.x = x_,
                              .f = function(x){
                                x$absacc
                              }) %>%
          dplyr::bind_rows()
        
        x_$relacc <- purrr::map(.x = x_,
                              .f = function(x){
                                x$relacc
                              }) %>%
          dplyr::bind_rows()
      }
      
      # Add to correct capture list
      index_[[exp_count]] <- x_$index
      indexvol_[[exp_count]] <- x_$vol
      series_[[exp_count]] <- x_$series
      revision_[[exp_count]] <- x_$revision
      seriesvol_[[exp_count]] <- x_$seriesvol
      absacc_[[exp_count]] <- x_$absacc
      relacc_[[exp_count]] <- x_$relacc
      
      # Increment counter
      exp_count <- exp_count + 1
    }
  }

### Flatten all in to data.frames ------------------------------------------------------------------ 
  
  index_df <- index_ %>% dplyr::bind_rows()
  indexvol_df <- indexvol_ %>% dplyr::bind_rows()
  
  series_df <- series_ %>% dplyr::bind_rows()
  revision_df <- revision_ %>% dplyr::bind_rows()
  seriesvol_df <- seriesvol_ %>% dplyr::bind_rows()
  absacc_df <- absacc_ %>% dplyr::bind_rows()
  relacc_df <- relacc_ %>% dplyr::bind_rows()
  
 ## Save combined results  
  saveRDS(list(index = index_df,
               indexvol = indexvol_df,
               series = series_df,
               seriesvol = seriesvol_df,
               revision = revision_df,
               absacc = absacc_df,
               relacc = relacc_df), 
          file = file.path(getwd(), 'data', 'combined_results.RDS'))
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  