library(tidyverse)
library(digest)

## Custom packages 
library(hpiR) # Ensure this is v 0.3.0 from Github, not 0.2.0 from CRAN

source(file.path(getwd(), 'irf', 'scripts', 'wrapper_function.R'))

exp = 'exp_5'
exp_ <- readRDS(file=file.path(getwd(), 'data', exp, 'exp_obj.RDS'))

kcb_sf <- sf::st_read(file.path(getwd(), 'data', 'geo', 'kingco_boundary.shp'))
kcs_sf <- sf::st_read(file.path(getwd(), 'data', 'geo', 'kingco_submarkets.shp'))

hed_sf <- exp_$hed_df %>%
  sf::st_as_sf(., coords = c('longitude', 'latitude'),
               crs = 4326) %>%
  dplyr::select(area, submarket, prop_id)

sf::st_write(hed_sf, file.path(getwd(), 'data', 'sale_points.shp')

h_sf <- hed_sf %>%
  dplyr::sample_n(20000)
             
library(tmap)
tmap_mode("view")
basemap <- leaflet::providers$CartoDB.Positron

tm_shape(kcb_sf) +
  tm_basemap(basemap) + 
  tm_borders(col = 'black', lwd = 3) + 
  tm_shape(h_sf) + 
  tm_symbols(col = 'red', alpha = .6, size = .01, border.col = 'red') + 
  tm_shape(kcs_sf) + 
  tm_borders(col = 'gray20', lwd = 2)  






