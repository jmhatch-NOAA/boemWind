#' Extract renewable energy lease or wind planning areas from BOEM's ArcGIS server and save as an rda file.
#'
#' @param save_clean Boolean. TRUE / FALSE to save data as an rda file or return \code{sf} object.
#'
#' @return A \code{sf} object if \code{save_clean = FALSE}, otherwise \code{NULL}.
#'
sf::sf_use_s2(FALSE) # turn off s2 processing
here::here('R', 'boem_arcgis.R') |> source(echo = FALSE) # load needed functions

# function to extract outlines
get_boem_outlines <- function(save_clean = TRUE) {

  # read in feature layers
  active_leases <- query_boem(type = "active lease outlines")
  planning_areas <- query_boem(type = "planning area outlines")

  # shapes
  active_shapes <- active_leases |>
    purrr::pluck('data') |>
    dplyr::mutate(LEASE_STAGE = 'Active', EDIT = as.POSIXct(active_leases$metadata$editingInfo$lastEditDate / 1000, origin = "1970-01-01", tz = "UTC"))
  planning_shapes <-planning_areas |>
    purrr::pluck('data') |>
    dplyr::mutate(LEASE_STAGE = 'Planning', EDIT = as.POSIXct(planning_areas$metadata$editingInfo$lastEditDate / 1000, origin = "1970-01-01", tz = "UTC"))

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
  boem_orep_outlines <- sf:::rbind.sf(active_shapes, planning_shapes)

  # save or not
  if (save_clean) {
    usethis::use_data(boem_orep_outlines, overwrite = TRUE)
  } else {
    return(boem_orep_outlines)
  }

}

#' Update the R file documenting the renewable energy lease and wind planning areas from BOEM's ArcGIS server.
#'
#' @return NULL
#'
update_outlines_R <- function() {

  # load data
  load(file = here::here('data', 'boem_orep_outlines.rda'))

  # get metadata
  n_features <- nrow(boem_orep_outlines)
  n_fields <- ncol(boem_orep_outlines)
  bbox <- sf::st_bbox(boem_orep_outlines)
  x_min <- round(bbox['xmin'], 4)
  x_max <- round(bbox['xmax'], 4)
  y_min <- round(bbox['ymin'], 4)
  y_max <- round(bbox['ymax'], 4)
  active_version <- unique(boem_orep_outlines$EDIT[boem_orep_outlines$LEASE_STAGE == 'Active'] |> as.Date())
  planning_version <- unique(boem_orep_outlines$EDIT[boem_orep_outlines$LEASE_STAGE == 'Planning'] |> as.Date())
  dims <- sf::st_dimension(boem_orep_outlines)

  # paste string
  txt_file <- paste0("#' @title BOEM Office of Renewable Energy Program Lease and Wind Planning Areas
#'
#' @description An \\code{sf} object containing the outlines for BOEM Renewable Energy Lease (LEASE_STAGE = 'Active') and Wind Planning (LEASE_STAGE = 'Planning') Areas.
#'
#' @format An \\code{sf} collection with ", n_features," features and ", n_fields," fields.
#' \\describe{
#'   \\item{Geometry type}{", sf::st_geometry_type(boem_orep_outlines) |> unique() |> paste(collapse = ', '),"}
#'   \\item{Dimension}{", ifelse(all(dims[!is.na(dims)] == 2), 'XY', 'UNDET'),"}
#'   \\item{Bounding box}{xmin: ", x_min," ymin: ", y_min," xmax: ", x_max," ymax: ", y_max,"}
#'   \\item{Geodetic CRS}{", sf::st_crs(boem_orep_outlines)$input,"}
#' }
#'
#' @details The Lease Area Boundaries were updated on ", active_version," and the Wind Planning Area Boundaries were updated on ", planning_version, ". The Wind Planning Areas were rescinded on July 30, 2025.
#'
#' @docType data
#' @name boem_orep_outlines
#' @aliases boem_wea_outlines
#' @usage data('boem_orep_outlines')
#' @keywords datasets
#' @source \\url{https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data}
NULL")

  # output
  cat(txt_file, file = here::here('R/data_boem_orep_outlines.R'))

}

# download & extract
get_boem_outlines()

# update R
update_outlines_R()

# re-build documentation
devtools::document()
