#' @title BOEM Renewable Energy Lease Areas and Wind Planning Areas
#'
#' @description A \code{sf} object containing the outlines for BOEM Renewable Energy Lease Areas (LEASE_STAGE = 'Active') and Wind Planning Areas (LEASE_STAGE = 'Planning').
#'
#' @format A \code{sf} collection with 73 features and 23 fields.
#' \describe{
#'   \item{Geometry type}{MULTIPOLYGON}
#'   \item{Dimension}{XY}
#'   \item{Bounding box}{xmin: -158.6636 ymin: 20.7765 xmax: -66.9108 ymax: 44.769}
#'   \item{Geodetic CRS}{WGS 84}
#'   \item{Source}{data-raw/boem-renewable-energy-geodatabase/BOEMWindLayers_4Download.gdb}
#'   \item{Fields}{Field descriptions can be found \href{https://services1.arcgis.com/Hp6G80Pky0om7QvQ/ArcGIS/rest/services/BOEM_Wind_Planning_and_Lease_Areas/FeatureServer/layers}{here}.}
#' }
#'
#' @docType data
#' @name boem_wea_outlines
#' @usage data('boem_wea_outlines')
#' @keywords datasets
#' @source \url{https://www.boem.gov/renewable-energy/mapping-and-data/renewable-energy-gis-data}
#' @details
#' BOEM wind lease area outlines were updated on 11/Lease/Outlines (version 11) and BOEM wind planning area outlines were updated on Outlines/Planning/Area (version 11).
#'
#' There may be more up to date BOEM wind planning areas than those included in boemWind.
#' It is recommended that you reach out to the Wind Team at the NEFSC (\email{angela.silva@@noaa.gov}) to confirm.
NULL