library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

source(file.path(getwd(), 'irf', 'scripts', 'wrapper_function.R'))

exp = 'exp_5'
exp_ <- readRDS(file=file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

## All King County

  # Five Year
  hed_5 <- hedWrapper(exp_obj = exp_,)

  saveRDS(hed_5, file = file.path(getwd(), 'data', exp_$name, paste0('hed_results_obj.RDS')))
  
  rm(hed_5)
  gc()
  
  
  
  
  
  
#   
#   
#   # 10 Year
#   rt_10 <- rtWrapper(sales_df = sales_df %>%
#                        dplyr::filter(sale_date >= as.Date('2012-01-01')),
#                      time_id = 10,
#                      sm_field = 'county',
#                      sm_id = 'king',
#                      data_path = file.path(getwd(), 'data'),
#                      train_period = 24)
#   
#   # Full 22 years
#   rt_22 <- rtWrapper(sales_df = sales_df,
#                      time_id = 22,
#                      sm_field = 'county',
#                      sm_id = 'king',
#                      data_path = file.path(getwd(), 'data'),
#                      train_period = 48)
#   
# ### City Specific
#   
#   cities <- c('SEATTLE', 'KING COUNTY', 'BELLEVUE', 'SAMMAMISH', 'KENT',
#               'RENTON', 'KIRKLAND', 'FEDERAL WAY', 'AUBURN', 'MAPLE VALLEY')
#   
#   city_sales_df <- sales_df %>%
#     dplyr::filter(sale_date >= as.Date('2012-01-01') & 
#                     city %in% cities)
#   
#   cities <- sort(cities)
#   city_ <- split(city_sales_df, city_sales_df$city)
#   
#   city_results <- purrr::map2(.x = city_,
#                               .y = tolower(cities),
#                              .f = rtWrapper,
#                              time_id = 10,
#                              sm_field = 'city', 
#                              data_path = file.path(getwd(), 'data'),
#                              train_period = 24)
# 
# ### Submarket
#   
#   subm <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
#             'O', 'P', 'Q', 'R', 'S')
#   
#   subm_sales_df <- sales_df %>%
#     dplyr::filter(sale_date >= as.Date('2012-01-01') & 
#                     submarket %in% subm)
#   
#   subm_ <- split(subm_sales_df, subm_sales_df$submarket)
#   
#   rt_subm_results <- purrr::map2(.x = subm_,
#                                  .y = tolower(subm),
#                                  .f = rtWrapper,
#                                  time_id = 5,
#                                  sm_field = 'submarket', 
#                                  data_path = file.path(getwd(), 'data'),
#                                  train_period = 24)