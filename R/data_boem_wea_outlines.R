#' @title BOEM Renewable Energy Lease Areas and Wind Planning Areas
#'
#' @description A \code{sf} object containing the outlines for BOEM Renewable Energy Lease Areas (LEASE_STAGE = 'Active') and Wind Planning Areas (LEASE_STAGE = 'Planning').
#'
#' @format A \code{sf} collection with 71 features and 29 fields.
#' \describe{
#'   \item{Geometry type}{MULTIPOLYGON}
#'   \item{Dimension}{XY}
#'   \item{Bounding box}{xmin: -158.6636 ymin: 20.7765 xmax: -67.2804 ymax: 44.248}
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
#' BOEM wind lease area outlines.
NULL