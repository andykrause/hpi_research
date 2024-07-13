#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#  Run 10 year, aggregate index analyses
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

## Load libraries

library(tidyverse)
library(kingCoData)
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN
library(tmap)


## Load custom functions  
source(file.path(getwd(), 'functions', 'wrapper_function.R'))
#source(file.path(getwd(), 'functions', 'oldWrappers.R'))

### Read in Data ------------------------------------------------------------------------------  

# Set Experiment Setup to use
exp <- 'exp_10'

# Read in experiment object (includes pre-filtered data)
exp_ <- readRDS(file = file.path(getwd(), 'data', exp, 'exp_obj.RDS'))
subm_sf <- sf::st_read(file.path(getwd(), 'data', 'gis', 'kingco_submarkets.shp'))

sales_sf <- exp_$hed_df %>% 
  dplyr::select(trans_id, latitude, longitude, submarket) %>%
  sf::st_as_sf(., coords = c('longitude', 'latitude'),
               crs = 4326)

tmap_mode("view")
basemap <- leaflet::providers$CartoDB

tm_shape(sales_sf) +
  tm_basemap(basemap) +
  tm_dots(col = 'dodgerblue', scale = .01) + 
  tm_shape(subm_sf) + 
  tm_borders(col = 'black', lwd = 3)



