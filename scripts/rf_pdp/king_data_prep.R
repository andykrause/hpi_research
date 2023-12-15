#***************************************************************************************************
#
#   Prepare the King County data
#
#***************************************************************************************************

  library(tidyverse)
  library(magrittr)
  library(hpiR)
  library(magrittr)
  library(tidyverse)
  library(ggplot2)
  library(ggridges)

  data_path <- '/volumes/googledrive/my drive/to_read/ZOMLRead/short_holds/short_hold_data'
  func_path <- '~/projects/ml_hpi_research/scripts/'
  sales_file <- 'sales_2019.csv'
  parcel_orig_file <- 'parcel1999.csv'
  parcel_curr_file <- 'parcel2019.csv'
  resbldg_orig_file <- 'resbldg1999.csv'
  resbldg_curr_file <- 'resbldg2019.csv'
  tax_orig_file <- 'valhist1999.csv'
  tax_curr_file <- 'valhist2019.csv'
  
  sale_min <- 1999
  sale_max <- 2019

  source(file.path(func_path, 'king_data_functions.R'))
  
### Load Data --------------------------------------------------------------------------------------
  
  # Sales data
  raw_df <- read.csv(file.path(data_path, sales_file))

  # Parcel Data
  parO_df <- read.csv(file.path(data_path, parcel_orig_file))
  parC_df <- read.csv(file.path(data_path, parcel_curr_file))
  
  # Parcel Data
  rbO_df <- read.csv(file.path(data_path, resbldg_orig_file))
  rbC_df <- read.csv(file.path(data_path, resbldg_curr_file))
  
  # Tax Data
  tax_19 <- read.csv(file.path(data_path, tax_curr_file)) %>%
    dplyr::filter(BillYr == 2019) %>%
    dplyr::mutate(pinx = paste0('..', substr(AcctNbr, 1, 10)))
  
### Clean Sales Data -------------------------------------------------------------------------------
  
  # base clean
  clean_df <- raw_df %>%
    dplyr::filter(Major > 0 & SalePrice > 0)

  clean_df <- clean_df %>%
    dplyr::mutate(doc_date = paste(substr(DocumentDate, 4, 5), substr(DocumentDate, 1, 2),
                                   substr(DocumentDate, 7, 10), sep=""),
                  sale_date = as.POSIXct(strptime(doc_date, "%d%m%Y")),
                  sale_year = as.numeric(format(sale_date, "%Y"))) %>%
    dplyr::filter(!is.na(sale_date))

  # eliminate Transactions prior to Sales Year Limit
  clean_df <- clean_df %>%
    dplyr::filter(sale_year >= sale_min & sale_year <= sale_max)

  # add PINX
  clean_df <- kngBuildPinx(clean_df)

  # add trans count and limit by paramter
  clean_df <- clean_df %>%
    dplyr::arrange(sale_date) %>%
    dplyr::group_by(pinx) %>%
    dplyr::mutate(sales_cnt = dplyr::n(),
                  sale_nbr = 1:sales_cnt) %>%
    dplyr::ungroup()

  # add MultiParcel sale designation
  clean_df <- clean_df %>%
    dplyr::group_by(ExciseTaxNbr) %>%
    dplyr::mutate(parcel_cnt = dplyr::n(),
                  multi_parcel = ifelse(parcel_cnt > 1, 1, 0)) %>%
    dplyr::ungroup()
 
 # Add unique IDs
  clean_df <- clean_df %>%
    dplyr::arrange(ExciseTaxNbr) %>%
    dplyr::mutate(temp_id = paste0(sale_year, '..', ExciseTaxNbr)) %>%
    dplyr::group_by(sale_year) %>%
    dplyr::mutate(sale_id = paste0(sale_year, '..', as.numeric(as.factor(temp_id)))) %>%
    dplyr::ungroup()

  # Fix the "Warning" Field.  Add a leading/trailing space for the grep()
  clean_df <- clean_df %>%
    dplyr::filter(!SaleReason %in% 2:19) %>%
    dplyr::filter(!SaleInstrument %in% c(0,1,4:28)) %>%
    dplyr::mutate(sale_warning = paste0(' ', SaleWarning, ' ')) %>%
    dplyr::filter(!grepl(' 1 ', sale_warning) & 
                    !grepl(' 2 ', sale_warning) & 
                    !grepl(' 5 ', sale_warning) & 
                    !grepl(' 6 ', sale_warning) & 
                    !grepl(' 7 ', sale_warning) & 
                    !grepl(' 8 ', sale_warning) & 
                    !grepl(' 9 ', sale_warning) & 
                    !grepl(' 11 ', sale_warning) & 
                    !grepl(' 12 ', sale_warning) & 
                    !grepl(' 13 ', sale_warning) & 
                    !grepl(' 14 ', sale_warning) & 
                    !grepl(' 18 ', sale_warning) & 
                    !grepl(' 19 ', sale_warning) & 
                    !grepl(' 20 ', sale_warning) & 
                    !grepl(' 21 ', sale_warning) & 
                    !grepl(' 22 ', sale_warning) & 
                    !grepl(' 23 ', sale_warning) & 
                    !grepl(' 25 ', sale_warning) &
                    !grepl(' 27 ', sale_warning) &
                    !grepl(' 31 ', sale_warning) &
                    !grepl(' 32 ', sale_warning) &
                    !grepl(' 33 ', sale_warning) &
                    !grepl(' 37 ', sale_warning) &
                    !grepl(' 39 ', sale_warning) &
                    !grepl(' 43 ', sale_warning) &
                    !grepl(' 46 ', sale_warning) &
                    !grepl(' 48 ', sale_warning) &
                    !grepl(' 49 ', sale_warning) &
                    !grepl(' 50 ', sale_warning) &
                    !grepl(' 51 ', sale_warning) &
                    !grepl(' 52 ', sale_warning) &
                    !grepl(' 53 ', sale_warning) &
                    !grepl(' 59 ', sale_warning) &
                    !grepl(' 61 ', sale_warning) &
                    !grepl(' 63 ', sale_warning) &
                    !grepl(' 64 ', sale_warning) &
                    !grepl(' 66 ', sale_warning))

  ## Remove multiparcel and limit 
  clean_df <- clean_df %>%
    dplyr::filter(multi_parcel == 0) %>%
    dplyr::select(sale_id, pinx, sale_date, sale_year, sale_price = SalePrice,
                  property_type = PropertyType, principal_use = PrincipalUse,
                  property_class = PropertyClass, sales_cnt, sale_nbr, sale_warning)

  # Write out temporary sales files
  write.csv(clean_df, file.path(data_path, 'cleansales.csv'), row.names = FALSE)

### Prepare Parcel, ResBldg and Tax Files ----------------------------------------------------------
  
  parO_df <- parO_df %>%
    dplyr::select(Major, Minor, prop_type = PropType, area=Area, sub_area = SubArea, 
                  city = DistrictName, zoning = CurrentZoning, present_use = PresentUse, 
                  sqft_lot = SqFtLot, view_rainier = MtRainier, view_olympics = Olympics,
                  view_cascades = Cascades, view_territorial = Territorial, 
                  view_skyline = SeattleSkyline, view_sound = PugetSound, 
                  view_lakewash = LakeWashington, view_lakesamm = LakeSammamish,
                  view_otherwater = SmallLakeRiverCreek, view_other = OtherView,
                  wfnt = WfntLocation, golf = AdjacentGolfFairway, greenbelt = AdjacentGreenbelt,
                  noise_traffic = TrafficNoise) %>%
    kngBuildPinx(.)
  
  parC_df <- parC_df %>%
    dplyr::select(Major, Minor, prop_type = PropType, area=Area, sub_area = SubArea, 
                  city = DistrictName, zoning = CurrentZoning, present_use = PresentUse, 
                  sqft_lot = SqFtLot, view_rainier = MtRainier, view_olympics = Olympics,
                  view_cascades = Cascades, view_territorial = Territorial, 
                  view_skyline = SeattleSkyline, view_sound = PugetSound, 
                  view_lakewash = LakeWashington, view_lakesamm = LakeSammamish,
                  view_otherwater = SmallLakeRiverCreek, view_other = OtherView,
                  wfnt = WfntLocation, golf = AdjacentGolfFairway, greenbelt = AdjacentGreenbelt,
                  noise_traffic = TrafficNoise) %>%
    kngBuildPinx(.)

  rbC_df <- rbC_df %>%
    kngBuildPinx(.) %>%
    dplyr::select(pinx, bldg_nbr = BldgNbr, units = NbrLivingUnits, zip = ZipCode, stories = Stories,
                  grade = BldgGrade, sqft = SqFtTotLiving, sqft_1 = SqFt1stFloor, 
                  sqft_fbsmt = SqFtFinBasement, fbsmt_grade = FinBasementGrade,
                  garb_sqft = SqFtGarageBasement, gara_sqft = SqFtGarageAttached,
                  beds = Bedrooms, bath_half = BathHalfCount, bath_3qtr = Bath3qtrCount, 
                  bath_full = BathFullCount, condition = Condition,
                  year_built = YrBuilt, year_reno = YrRenovated, view_util = ViewUtilization)
  
  rbO_df <- rbO_df %>%
    kngBuildPinx(.) %>%
    dplyr::select(pinx, bldg_nbr = BldgNbr, units = NbrLivingUnits, stories = Stories,
                  grade = BldgGrade, sqft = SqFtTotLiving, sqft_1 = SqFt1stFloor, 
                  sqft_fbsmt = SqFtFinBasement, fbsmt_grade = FinBasementGrade,
                  garb_sqft = SqFtGarageBasement, gara_sqft = SqFtGarageAttached,
                  beds = Bedrooms, bath_half = BathHalfCount, bath_3qtr = Bath3qtrCount, 
                  bath_full = BathFullCount, condition = Condition,
                  year_built = YrBuilt, year_reno = YrRenovated, view_util = ViewUtilization)
  
### Add matching year ------------------------------------------------------------------------------  
  
  # Simple year buit/Reno data
  rbs_df <- rbO_df %>%
    dplyr::select(pinx, yb99 = year_built, yr99 = year_reno) %>%
    dplyr::full_join(rbC_df %>%
                        dplyr::select(pinx, yb19 = year_built, yr19 = year_reno),
                      by = 'pinx')
  
  # Add RBS
  trim_df <- clean_df %>%
    inner_join(rbs_df, by = 'pinx') %>%
    dplyr::filter(property_type %in% c(2,3,10,11))

### Split by match type and add data ---------------------------------------------------------------  
  
  # No change
  nochg_df <- trim_df %>%
    dplyr::filter(!is.na(yb99) & !is.na(yb19) & 
                    yb99 == yb19 & yr19 == 0) %>%
    dplyr::mutate(match_type = 'nochg', 
                  match_year = 2019)

  x_df <- trim_df %>%
    dplyr::filter(!sale_id %in% nochg_df$sale_id)

  # Demolished
  demo_df <- x_df %>%
    dplyr::filter(is.na(yb19)) %>%
    dplyr::mutate(match_type = 'demo',
                  match_year = 1999)

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% demo_df$sale_id)

  # New construction
  new_df <- x_df %>%
    dplyr::filter(is.na(yb99)) %>%
    dplyr::mutate(match_type = 'new',
                  match_year = 2019)

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% new_df$sale_id)

  # Rebuilt home
  rebuilt_df <- x_df %>%
    dplyr::filter(yb99 != yb19) %>%
    dplyr::mutate(match_type = ifelse(yb19 > sale_year, 'rebuilt - after',
                                      ifelse(yb19 < sale_year, 'rebuilt - before', 'rebuilt - ?')),
                  match_year = ifelse(match_type == 'rebuilt - after', 2019, 
                                      ifelse(match_type == 'rebuilt - before', 1999, -1)))

  x_df <- x_df %>%
    dplyr::filter(!sale_id %in% rebuilt_df$sale_id)

  # Renovated
  reno_df <- x_df %>%
    dplyr::mutate(match_type = ifelse(yr19 > sale_year, 'reno - after',
                                      ifelse(yr19 < sale_year, 'reno - before', 'reno - ?')),
                  match_year = ifelse(match_type == 'reno - after', 1999,
                                      ifelse(match_type == 'reno - before', 2019, -1)))

### Join and Row Bind ------------------------------------------------------------------------------
  
  # Row Binds
  sale_df <- nochg_df %>%
    dplyr::bind_rows(., demo_df, new_df, 
                     rebuilt_df %>% dplyr::filter(match_year != -1),
                     reno_df %>% dplyr::filter(match_year != -1))

  # Matched to 99
  sale99_df <- sale_df %>%
    dplyr::filter(match_year == 1999) %>%
    dplyr::select(-c(yb99, yr99, yb19, yr19)) %>%
    dplyr::left_join(., parO_df, by = 'pinx') %>%
    dplyr::left_join(., rbO_df, by = 'pinx')

  # Matched to 2019
  sale19_df <- sale_df %>%
    dplyr::filter(match_year == 2019) %>%
    dplyr::select(-c(yb99, yr99, yb19, yr19)) %>%
    dplyr::left_join(., parC_df, by = 'pinx') %>%
    dplyr::left_join(., rbC_df, by = 'pinx')

  # Bind Together
  sale_df <- dplyr::bind_rows(sale99_df, sale19_df) %>%
    dplyr::select(-c(Major, Minor, prop_type)) %>%
    dplyr::filter(present_use %in% c(2, 6, 29)) %>%
    dplyr::filter(property_class == 8) %>%
    dplyr::filter(principal_use == 6)
  
### Write out data ---------------------------------------------------------------------------------
  
  write.csv(sale_df, file.path(data_path, 'kingsales.csv'), row.names = FALSE)
  write.csv(sale_df %>% dplyr::filter(city == 'SEATTLE'), 
            file.path(data_path, 'seattlesales.csv'), 
          row.names = FALSE)

####################################################################################################
####################################################################################################
  