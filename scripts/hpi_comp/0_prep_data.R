#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Create data for HPI comparisons
#
#    -- This script converts the raw `kingco_sales` object into data ready for 
#    -- the hpi comparison experiments
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

### Setup ------------------------------------------------------------------------------------------

  ## Load standard package(s)
  library(tidyverse)

  ## Load custom package(s)
  if(!'kingCoData' %in% installed.packages()[,1]){
    devtools::install_github('andykrause/kingCoData')
  } 
  library(kingCoData)

  ## Load Data
  data(kingco_sales)

### Filters and Feature Engineering ----------------------------------------------------------------

  ## Remove sales with 'bad' status
  
   # Set status
   allowed_status <- c('new', 'nochg', 'rebuilt - before', 'reno - before')

   # Remove
   kingsales_df <- kingco_sales %>%
     dplyr::filter(join_status %in% allowed_status)
  
 ## Create new features
  kingsales_df <- kingsales_df %>%
    dplyr::mutate(baths = bath_full + (bath_3qtr * .75) + (bath_half * .5),
                  garage_sqft = garb_sqft + gara_sqft,
                  view_score = view_rainier + view_olympics + view_cascades + view_sound + 
                    view_lakewash,
                  tax_value = land_val + imp_val,
                  waterfront_type = dplyr::case_when(
                    wfnt %in% c(4,5,8) ~ 'lake',
                    wfnt %in% c(1,9) ~ 'river',
                    wfnt %in% c(2,3) ~ 'puget_sound',
                    wfnt == 6 ~ 'lake_wash',
                    wfnt == 7 ~ 'lake_samm',
                    TRUE ~'none'),
                  is_wfnt = ifelse(wfnt == 0, 0, 1),
                  age = as.numeric(substr(sale_date, 1, 4)) - year_built,
                  eff_age = ifelse(year_reno == 0, age,
                                   as.numeric(substr(sale_date, 1, 4)) - year_reno),
                  green_adjacent = ifelse(golf == 1 | greenbelt == 1, 1, 0),
                  townhome = ifelse(present_use == 29, 1, 0))

  ## Select necessary fields

  kingsales_df <-
    kingsales_df %>% 
    dplyr::select(sale_id, pinx, sale_date, sale_price, join_status, latitude, longitude,
                  city, area, submarket, subdivision, use = present_use, land_val, imp_val,
                  year_built, year_reno, age, eff_age, sqft_lot, sqft, grade, condition, stories, 
                  beds, baths, garb_sqft, gara_sqft, waterfront_type, is_wfnt, golf, greenbelt, 
                  traffic = noise_traffic, view_score)
  
  ## Fix Vashon Island Submarket
  
  kingsales_df <- kingsales_df %>%
    dplyr::mutate(submarket = ifelse(submarket == 'H', 'I', submarket))
  

### Write out data ---------------------------------------------------------------------------------  

  saveRDS(kingsales_df, file = file.path(getwd(), 'data', 'king_df.RDS'))
  
  # CleanUp
  rm(kingco_sales)
  rm(kingsales_df)
  gc()

### Create Inference set ---------------------------------------------------------------------------
  
## Create new features
  kinghomes_df <- kingco_homes %>%
    dplyr::mutate(baths = bath_full + (bath_3qtr * .75) + (bath_half * .5),
                  garage_sqft = garb_sqft + gara_sqft,
                  view_score = view_rainier + view_olympics + view_cascades + view_sound + 
                    view_lakewash,
                  tax_value = land_val + imp_val,
                  waterfront_type = dplyr::case_when(
                    wfnt %in% c(4,5,8) ~ 'lake',
                    wfnt %in% c(1,9) ~ 'river',
                    wfnt %in% c(2,3) ~ 'puget_sound',
                    wfnt == 6 ~ 'lake_wash',
                    wfnt == 7 ~ 'lake_samm',
                    TRUE ~'none'),
                  is_wfnt = ifelse(wfnt == 0, 0, 1),
                  age = 2023 - year_built,
                  eff_age = ifelse(year_reno == 0, age,
                                   2023 - year_reno),
                  green_adjacent = ifelse(golf == 1 | greenbelt == 1, 1, 0),
                  townhome = ifelse(present_use == 29, 1, 0))
  
  ## Select necessary fields
  
  kinghomes_df <-
    kinghomes_df %>% 
    dplyr::select(pinx, latitude, longitude,
                  city, area, submarket, subdivision, use = present_use, land_val, imp_val,
                  year_built, year_reno, age, eff_age, sqft_lot, sqft, grade, condition, stories, 
                  beds, baths, garb_sqft, gara_sqft, waterfront_type, is_wfnt, golf, greenbelt, 
                  traffic = noise_traffic, view_score)
  
  ## Fix Vashon Island Submarket
  kinghomes_df <- kinghomes_df %>%
    dplyr::mutate(submarket = ifelse(submarket == 'H', 'I', submarket))
  
### Write out data ---------------------------------------------------------------------------------  
  
  saveRDS(kinghomes_df, file = file.path(getwd(), 'data', 'kinghomes_df.RDS'))
  
  # CleanUp
  rm(kingco_homes)
  rm(kinghomes_df)
  gc()
  
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~