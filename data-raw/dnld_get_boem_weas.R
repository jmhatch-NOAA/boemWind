#' Extract renewable energy lease areas or wind planning areas from BOEM ArcGIS server and save as an rda file.
#'
#' @param save_clean Boolean. TRUE / FALSE to save data as an rda file or return \code{sf} object.
#'
#' @return A \code{sf} object if \code{save_clean = FALSE}, otherwise \code{NULL}.
#'
sf::sf_use_s2(FALSE) # turn off s2 processing
here::here('R', 'boem_arcgis.R') |> source(echo = FALSE) # load needed functions

# function to extract WEAs
get_boem_weas <- function(save_clean = TRUE) {

  # read in feature layers
  active_leases <- query_boem(type = "active lease outlines")
  planning_areas <- query_boem(type = "planning area outlines")

  # shapes
  active_shapes <- active_leases |>
    purrr::pluck('data') |>
    dplyr::mutate(LEASE_STAGE = 'Active', VERSION = active_leases$metadata$currentVersion)
  planning_shapes <-planning_areas |>
    purrr::pluck('data') |>
    dplyr::mutate(LEASE_STAGE = 'Planning', VERSION = planning_areas$metadata$currentVersion)

  # figure out which columns are in one and not the other
  cols_not_planning = colnames(active_shapes)[!colnames(active_shapes) %in% colnames(planning_shapes)]
  cols_not_active = colnames(planning_shapes)[!colnames(planning_shapes) %in% colnames(active_shapes)]

  # add missing columns to enable rbind
  active_shapes[cols_not_active] = NA
  planning_shapes[cols_not_planning] = NA

  # ensure same crs
  if (sf::st_crs(active_shapes) != sf::st_crs(4326)) {
    active_shapes <- active_shapes |> sf::st_transform(4326)
  }
  if (sf::st_crs(planning_shapes) != sf::st_crs(4326)) {
    planning_shapes <- planning_shapes |> sf::st_transform(4326)
  }

  # combine
  boem_wea_outlines <- sf:::rbind.sf(active_shapes, planning_shapes)

  # save or not
  if (save_clean) {
    usethis::use_data(boem_wea_outlines, overwrite = TRUE)
  } else {
    return(boem_wea_outlines)
  }

}

#' Update the R file documenting the renewable energy lease areas and wind planning areas from BOEM ArcGIS server.
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
  active_version <- unique(boem_wea_outlines$VERSION[boem_wea_outlines$LEASE_STAGE == 'Active'])
  planning_version <- unique(boem_wea_outlines$VERSION[boem_wea_outlines$LEASE_STAGE == 'Planning'])
  dims <- sf::st_dimension(boem_wea_outlines)

  # paste string
  txt_file <- paste0("#' @title BOEM Renewable Energy Lease Areas and Wind Planning Areas
#'
#' @description An \\code{sf} object containing the outlines for BOEM Renewable Energy Lease Areas (LEASE_STAGE = 'Active') and Wind Planning Areas (LEASE_STAGE = 'Planning').
#'
#' @format An \\code{sf} collection with ", n_features," features and ", n_fields," fields.
#' \\describe{
#'   \\item{Geometry type}{", sf::st_geometry_type(boem_wea_outlines) |> unique() |> paste(collapse = ', '),"}
#'   \\item{Dimension}{", ifelse(all(dims[!is.na(dims)] == 2), 'XY', 'UNDET'),"}
#'   \\item{Bounding box}{xmin: ", x_min," ymin: ", y_min," xmax: ", x_max," ymax: ", y_max,"}
#'   \\item{Geodetic CRS}{", sf::st_crs(boem_wea_outlines)$input,"}
#' }
#'
#' @details The Wind Lease Boundaries are from version ", active_version, " and the Wind Planning Area Boundaries are from version ", planning_version, ".
#'
#' @docType data
#' @name boem_wea_outlines
#' @usage data('boem_wea_outlines')
#' @keywords datasets
#' @source \\url{https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data}
NULL")

  # output
  cat(txt_file, file = here::here('R/data_boem_wea_outlines.R'))

}

# download & extract
get_boem_weas()

# update R
update_weas_R()

# re-build documentation
devtools::document()
