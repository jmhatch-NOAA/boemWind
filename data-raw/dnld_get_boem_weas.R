#' Download boundaries of renewable energy lease areas, wind planning areas, and marine hydrokinetic planning areas from BOEM.
#'
#' @param gdb_loc File path for the BOEM geodatabase.
#'
# needed R libraries
library(dplyr)
library(magrittr)

# location to save / access the gdb
gdb_loc <- 'data-raw/boem-renewable-energy-geodatabase'

# function to download geodatabase (gdb)
dnld_boem_weas <- function(gdb_loc) {

  # download gdb
  httr::GET('https://www.boem.gov/BOEM-Renewable-Energy-Geodatabase.zip',
            httr::write_disk(here::here(paste0(gdb_loc, '.zip')), overwrite = TRUE))

  # unzip
  here::here(paste0(gdb_loc, '.zip')) %>% unzip(., exdir = here::here(gdb_loc))

  # delete zip folder
  file.remove(here::here(paste0(gdb_loc, '.zip')))

}

#' Extract renewable energy lease areas and wind planning areas from BOEM geodatabase and save as an rda file.
#'
#' @param gdb_loc File path for the BOEM geodatabase.
#' @param save_clean Boolean. TRUE / FALSE to save data as an rda file or return \code{sf} object.
#'
#' @return A \code{sf} object if \code{save_clean = FALSE}, otherwise \code{NULL}.
#'
sf::sf_use_s2(FALSE) # turn off s2 processing

# function to extract WEAs
get_boem_weas <- function(gdb_loc, save_clean = TRUE) {

  # list layers in gdb
  list_layers <- here::here(paste0(gdb_loc, '/BOEMWindLayers_4Download.gdb')) %>% sf::st_layers()

  # grab layer names
  active_name <- list_layers$name[stringr::str_detect(list_layers$name, 'WindLeaseOutlines')]
  planning_name <- list_layers$name[stringr::str_detect(list_layers$name, 'WindPlanningAreaOutlines')]

  # extract dates
  active_date <- paste(stringr::str_split(active_name, pattern = '_')[[1]][c(4,2,3)], collapse = '/')
  planning_date <- paste(stringr::str_split(planning_name, pattern = '_')[[1]][c(4,2,3)], collapse = '/')

  # read in feature layers
  active_shapes <- here::here(paste0(gdb_loc, '/BOEMWindLayers_4Download.gdb')) %>%
    sf::st_read(layer = active_name) %>%
    dplyr::mutate(LEASE_STAGE = 'Active', UPDATED = active_date)
  planning_shapes <- here::here(paste0(gdb_loc, '/BOEMWindLayers_4Download.gdb')) %>%
    sf::st_read(layer = planning_name) %>%
    dplyr::mutate(LEASE_STAGE = 'Planning', UPDATED = planning_date)

  # figure out which columns are in one and not the other
  cols_not_planning = colnames(active_shapes)[!colnames(active_shapes) %in% colnames(planning_shapes)]
  cols_not_active = colnames(planning_shapes)[!colnames(planning_shapes) %in% colnames(active_shapes)]

  # add missing columns to enable rbind
  active_shapes[cols_not_active] = NA
  planning_shapes[cols_not_planning] = NA

  # combine
  boem_wea_outlines <- sf:::rbind.sf(active_shapes, planning_shapes)

  # delete columns w/ all NAs
  boem_wea_outlines %<>% dplyr::select(-c(Shape__Area, Shape__Length))

  # save or not
  if (save_clean) {
    usethis::use_data(boem_wea_outlines, overwrite = TRUE)
  } else {
    return(boem_wea_outlines)
  }

}

#' Update the R file documenting the renewable energy lease areas and wind planning areas from BOEM.
#'
#' @return NULL
#'
update_weas_R <- function() {

  # load data
  load(file = here::here('data', 'boem_wea_outlines.rda'))

  # get metadata
  n_features <- nrow(boem_wea_outlines)
  n_fields <- ncol(boem_wea_outlines)
  bbox <- sf::st_bbox(boem_wea_outlines)
  x_min <- round(bbox['xmin'], 4)
  x_max <- round(bbox['xmax'], 4)
  y_min <- round(bbox['ymin'], 4)
  y_max <- round(bbox['ymax'], 4)
  active_update <- boem_wea_outlines %>% dplyr::filter(LEASE_STAGE == 'Active') %>% dplyr::pull(UPDATED) %>% unique()
  planning_update <- boem_wea_outlines %>% dplyr::filter(LEASE_STAGE == 'Planning') %>% dplyr::pull(UPDATED) %>% unique()

  # query ArcGIS REST service
  url = 'https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer'
  active_layer_info <- jsonlite::fromJSON(httr::content(httr::POST(paste0(url, '/0'), query = list(f = "json"), encode = "form", config = httr::config(ssl_verifypeer = FALSE)), as = "text"))
  planning_layer_info <- jsonlite::fromJSON(httr::content(httr::POST(paste0(url, '/2'), query = list(f = "json"), encode = "form", config = httr::config(ssl_verifypeer = FALSE)), as = "text"))

  # paste string
  txt_file <- paste0("#' @title BOEM Renewable Energy Lease Areas and Wind Planning Areas
#'
#' @description A \\code{sf} object containing the outlines for BOEM Renewable Energy Lease Areas (LEASE_STAGE = 'Active') and Wind Planning Areas (LEASE_STAGE = 'Planning').
#'
#' @format A \\code{sf} collection with ", n_features," features and ", n_fields," fields.
#' \\describe{
#'   \\item{Geometry type}{", sf::st_geometry_type(boem_wea_outlines) %>% unique() %>% paste(collapse = ', '),"}
#'   \\item{Dimension}{", ifelse(all(sf::st_dimension(boem_wea_outlines) == 2), 'XY', 'UNDET'),"}
#'   \\item{Bounding box}{xmin: ", x_min," ymin: ", y_min," xmax: ", x_max," ymax: ", y_max,"}
#'   \\item{Geodetic CRS}{", sf::st_crs(boem_wea_outlines)$input,"}
#'   \\item{Source}{data-raw/boem-renewable-energy-geodatabase/BOEMWindLayers_4Download.gdb}
#'   \\item{Fields}{Field descriptions can be found \\href{https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer/layers}{here}.}
#' }
#'
#' @docType data
#' @name boem_wea_outlines
#' @usage data('boem_wea_outlines')
#' @keywords datasets
#' @source \\url{https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data}
#' @details
#' BOEM wind lease area outlines were updated on ", active_update," (version ", active_layer_info$currentVersion,") and BOEM wind planning area outlines were updated on ", planning_update," (version ", planning_layer_info$currentVersion, ").
#'
#' There may be more up to date BOEM wind planning areas than those included in NEFSCspatial.
#' It is recommended that you reach out to the Wind Team at the NEFSC (\\email{angela.silva@@noaa.gov}) to confirm.
NULL")

  # output
  cat(txt_file, file = here::here('R/data_boem_wea_outlines.R'))

}

# download
dnld_boem_weas(gdb_loc = gdb_loc)

# extract
get_boem_weas(gdb_loc = gdb_loc)

# update R
update_weas_R()

# re-build documentation
devtools::document()
