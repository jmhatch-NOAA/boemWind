#' @title switch_url
#'
#' @description Based on \code{type}, provide the Direct Service Link to download GIS data from BOEM's Renewable Energy Program using their ArcGIS server.
#'
#' @param type A character string for the type of GIS data that you would like to download.
#' Can be:
#' * \code{active lease outlines}
#' * \code{planning area outlines}
#' * \code{project phases}
#' * \code{export cables}
#' * \code{substations}
#' * \code{turbine locations}
#' * \code{cable interconnections}
#' * \code{data collection devices}
#' * \code{cable corridors}
#' * \code{cable landings}
#' * \code{interarray cables}
#'
#' @return A url path.
#'
#' @keywords internal
#'
switch_url <- function(type) {

  # urls
  if (type == "active lease outlines") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/arcgis/rest/services/Wind_Lease_Boundaries__BOEM_/FeatureServer"
  } else if (type == "planning area outlines") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/arcgis/rest/services/Wind_Planning_Area_Boundaries__BOEM_/FeatureServer"
  } else if (type == "project phases") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/arcgis/rest/services/Offshore_Wind_Proposed_Projects_Phase_Areas/FeatureServer"
  } else if (type == "export cables") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Export_Cables_Proposed_Locations/FeatureServer"
  } else if (type == "substations") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Substations/FeatureServer"
  } else if (type == "turbine locations") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Turbine_Locations/FeatureServer"
  } else if (type == "cable interconnections") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Cable_Interconnections/FeatureServer"
  } else if (type == "data collection devices") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Data_Collection_Devices/FeatureServer"
  } else if (type == "cable corridors") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind-_Proposed_Export_Cable_Corridors/FeatureServer"
  } else if (type == "cable landings") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Offshore_Landings/FeatureServer"
  } else if (type == "interarray cables") {
    base_url <- "https://services7.arcgis.com/G5Ma95RzqJRPKsWL/ArcGIS/rest/services/Offshore_Wind_-_Proposed_or_Installed_Project_Inter-array_Cables/FeatureServer"
  } else {
    stop(glue::glue("Sorry, but type = \'{ type }\' isn't yet supported."))
  }

  # output
  return(base_url)

}

#' @title Download GIS data from BOEM's Renewable Energy Program
#'
#' @description Query GIS data from BOEM's Renewable Energy Program using their ArcGIS server.
#'
#' @param type A character string for the type of GIS data that you would like to download.
#' Can be:
#' * \code{active lease outlines}
#' * \code{planning area outlines}
#' * \code{project phases}
#' * \code{export cables}
#' * \code{substations}
#' * \code{turbine locations}
#' * \code{cable interconnections}
#' * \code{data collection devices}
#' * \code{cable corridors}
#' * \code{cable landings}
#' * \code{interarray cables}
#'
#' @return A list with two named elements: 1) \code{meta} that stores metadata and 2) \code{data} that stores an \code{sf} data frame.
#'
#' @export
#'
query_boem <- function(type) {

  # grab url
  base_url <- switch_url(type)

  # grab meta data
  meta <- base_url |>
    httr::GET(query = list(f = "json")) |>
    httr::stop_for_status(task = glue::glue("Grabbing metadata from:\n { base_url }")) |>
    httr::content(simplifyVector = TRUE)

  # should only be 1 layer for now
  stopifnot(nrow(meta) == 1)

  # query parameters
  query <- list(
    where = "1=1",
    outFields = "*",
    f = "geoJSON"
  )

  # download GIS data
  sf_data <- httr::POST(url = file.path(base_url, meta$layers$id, "query"), body = query) |>
    httr::content(as = "text", encoding = "UTF-8") |>
    sf::read_sf()

  # output
  return(list(metadata = meta, data = sf_data))

}
