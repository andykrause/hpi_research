library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

## Create experiment data output

sales_df <- readRDS(file = file.path(getwd(), 'data', 'king_df.RDS'))
rt5_df <- readRDS(file = file.path(getwd(), 'data', 'data_rt_5_county_king.RDS'))
rt10_df <- readRDS(file = file.path(getwd(), 'data', 'data_rt_10_county_king.RDS'))
#rt22_df <- readRDS(file = file.path(getwd(), 'data', 'data_rt_22_county_king.RDS'))

ind_var = c('use', 'grade', 'sqft_lot', 'age', 'sqft', 'beds', 
            'baths', 'latitude', 'longitude')

## All King County

  # Five Year
  he_5 <- hedWrapper(sales_df = sales_df %>%
                      dplyr::filter(sale_date >= as.Date('2017-01-01')),
                    time_id = 5,
                    sm_field = 'county',
                    sm_id = 'king',
                    ind_var = ind_var,
                    periodicity = 'weekly',
                    rt_df = rt5_df,
                    data_path = file.path(getwd(), 'data'),
                    train_period = 12)
  
  # Five Year
  he_10 <- hedWrapper(sales_df = sales_df %>%
                       dplyr::filter(sale_date >= as.Date('2012-01-01')),
                     time_id = 10,
                     sm_field = 'county',
                     sm_id = 'king',
                     ind_var = ind_var,
                     rt_df = rt10_df,
                     data_path = file.path(getwd(), 'data'),
                     train_period = 24)
  
  # Five Year
  he_22 <- hedWrapper(sales_df = sales_df,
                     time_id = 22,
                     sm_field = 'county',
                     sm_id = 'king',
                     ind_var = ind_var,
                     estimator = 'base', 
                     rt_df = rt22_df,
                     data_path = file.path(getwd(), 'data'),
                     train_period = 48)
  
  ### City Specific
  
  cities <- c('SEATTLE', 'KING COUNTY', 'BELLEVUE', 'SAMMAMISH', 'KENT',
              'RENTON', 'KIRKLAND', 'FEDERAL WAY', 'AUBURN', 'MAPLE VALLEY')
  
  city_sales_df <- sales_df %>%
    dplyr::filter(sale_date >= as.Date('2012-01-01') & 
                    city %in% cities)
  
  cities <- sort(cities)
  city_ <- split(city_sales_df, city_sales_df$city)
  
  city_results <- purrr::map2(.x = city_,
                              .y = tolower(cities),
                              .f = hedWrapper,
                              time_id = 10,
                              sm_field = 'city', 
                              ind_var = ind_var,
                              rt_df = rt10_df,
                              estimator = 'base', 
                              data_path = file.path(getwd(), 'data'),
                              train_period = 24)
  
  ### Submarket
  
  subm <- c('A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N',
            'O', 'P', 'Q', 'R', 'S')
  
  subm_sales_df <- sales_df %>%
    dplyr::filter(sale_date >= as.Date('2012-01-01') & 
                    submarket %in% subm)
  
  subm_ <- split(subm_sales_df, subm_sales_df$submarket)
  
  he_subm_results <- purrr::map2(.x = subm_,
                                 .y = tolower(subm),
                                 .f = hedWrapper,
                                 time_id = 10,
                                 sm_field = 'submarket', 
                                 ind_var = ind_var,
                                 estimator = 'base', 
                                 rt_df = rt10_df,
                                 data_path = file.path(getwd(), 'data'),
                                 train_period = 24)  
  
  
