#' Download the United States Wind Turbine Database (USWTDB) from the USGS.
#'
#' @param shp_loc File path for the USGS shapefile.
#'
# needed R libraries
library(dplyr)
library(magrittr)

# location to save / access the shp
shp_loc <- 'data-raw/usgs-uswtdb-shapefile'

# function to download shapefile (shp)
dnld_usgs_wtb <- function(shp_loc) {

  # create shp_loc
  if (!file.exists(here::here(shp_loc))) dir.create(here::here(shp_loc))

  # download shp
  httr::GET('https://eerscmap.usgs.gov/uswtdb/assets/data/uswtdbSHP.zip',
            httr::write_disk(here::here(paste0(shp_loc, '.zip')), overwrite = TRUE))

  # unzip
  here::here(paste0(shp_loc, '.zip')) %>% unzip(., exdir = here::here(shp_loc))

  # delete zip folder
  file.remove(here::here(paste0(shp_loc, '.zip')))

}

#' Extract locations of offshore wind turbines in the United States, corresponding wind project information, and turbine technical specifications from the USGS USWTDB and save as an rda file.
#'
#' @param shp_loc File path for the USGS shapefile.
#' @param save_clean Boolean. TRUE / FALSE to save data as an rda file or return \code{sf} object.
#'
#' @return A \code{sf} object if \code{save_clean = FALSE}, otherwise \code{NULL}.
#'
sf::sf_use_s2(FALSE) # turn off s2 processing

# function to extract WTBs
get_usgs_wtb <- function(shp_loc, save_clean = TRUE) {

  # list shp
  list_shp <- here::here(shp_loc) %>%
    list.files(pattern = '*.shp$', full.names = TRUE)

  # read in shp
  wtb_shp <- list_shp %>%
    sf::st_read()

  # filter for offshore (at least 6 MW capacity for offshore wind turbines)
  # NOTE: this doesn't work any longer, as some on-land turbines have a 6 MW capacity
  # As a hacky workaround, filtering by project name too
  usgs_offshore_wtbs <- wtb_shp %>%
    dplyr::filter(t_cap >= 6000 & !p_name %in% c('Deerfield II Wind project', 'Ranchland Wind Project'))

  # save or not
  if (save_clean) {
    usethis::use_data(usgs_offshore_wtbs, overwrite = TRUE)
  } else {
    return(usgs_offshore_wtbs)
  }

}

#' Update the R file documenting the offshore wind turbine locations and info from USGS.
#'
#' @return NULL
#'
update_wtbs_R <- function(shp_loc) {

  # load data
  load(file = here::here('data', 'usgs_offshore_wtbs.rda'))

  # get metadata
  n_features <- nrow(usgs_offshore_wtbs)
  n_fields <- ncol(usgs_offshore_wtbs)
  bbox <- sf::st_bbox(usgs_offshore_wtbs)
  x_min <- round(bbox['xmin'], 4)
  x_max <- round(bbox['xmax'], 4)
  y_min <- round(bbox['ymin'], 4)
  y_max <- round(bbox['ymax'], 4)
  shp_name <- here::here(shp_loc) %>%
    list.files(pattern = '*.shp$')

  # version
  changelog <- here::here(shp_loc, 'CHANGELOG.txt') %>%
    readLines()

  # remove dir
  if (grepl(pattern = '/home/runner/work', x = here::here())) unlink(here::here(shp_loc), recursive = TRUE, force = TRUE)

  # paste string
  txt_file <- paste0("#' @title The United States Wind Turbine Database (USWTDB)
#' @details Version:", gsub(pattern = '#|\\[|\\]', replacement = '', x = changelog[2]),"
#'
#' @description An \\code{sf} object containing the locations of offshore wind turbines.
#'
#' @format An \\code{sf} collection with ", n_features," features and ", n_fields," fields.
#' \\describe{
#'   \\item{Geometry type}{", sf::st_geometry_type(usgs_offshore_wtbs) %>% unique() %>% paste(collapse = ', '),"}
#'   \\item{Dimension}{", ifelse(all(sf::st_dimension(usgs_offshore_wtbs) == 0), 'XY', 'UNDET'),"}
#'   \\item{Bounding box}{xmin: ", x_min," ymin: ", y_min," xmax: ", x_max," ymax: ", y_max,"}
#'   \\item{Geodetic CRS}{", sf::st_crs(usgs_offshore_wtbs)$input,"}
#'   \\item{Source}{data-raw/usgs-uswtdb-shapefile/", shp_name, "}
#' }
#'
#' @docType data
#' @name usgs_offshore_wtbs
#' @usage data('usgs_offshore_wtbs')
#' @keywords datasets
#' @source \\url{https://eerscmap.usgs.gov/uswtdb/}
NULL")

  # output
  cat(txt_file, file = here::here('R/data_usgs_offshore_wtbs.R'))

}

# delete all files in shp_loc
list.files(shp_loc, full.names = TRUE) |> file.remove()

# download
dnld_usgs_wtb(shp_loc = shp_loc)

# extract
get_usgs_wtb(shp_loc = shp_loc)

# update R
update_wtbs_R(shp_loc = shp_loc)

# re-build documentation
devtools::document()

# take a peak
leaflet::leaflet() |>
  leaflet::addTiles() |>
  leaflet::addMarkers(data = boemWind::usgs_offshore_wtbs |> sf::st_transform(4326))
