#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom lifecycle deprecated
## usethis namespace: end
NULL

## backward compatibility w/ data name change
#' @export boem_wea_outlines
makeActiveBinding("boem_wea_outlines", env = asNamespace("boemWind"), fun = function(ignored) {
  data("boem_orep_outlines", package = "boemWind", envir = environment())
  boem_orep_outlines
})
