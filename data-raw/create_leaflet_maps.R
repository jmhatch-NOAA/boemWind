# needed libraries
library(boemWind)

# delete leaflet maps
leaflet_maps <- here::here('leaflet_maps') |>
  unlink(recursive = TRUE, force = TRUE)

# create leaflet_maps
if (!file.exists(here::here('leaflet_maps'))) dir.create(here::here('leaflet_maps'))

# list of exported data objects
exp_data <- ls("package:boemWind")

# load data
data(list = exp_data)

# get_data
sf_data <- get(exp_data)

# make valid, if needed
if (any(sf::st_is_valid(sf_data) != TRUE)) {
  sf_data <- sf_data |>
    sf::st_make_valid()
}

# change crs, if needed
if (sf::st_crs(sf_data) != sf::st_crs(4326)) {
  sf_data <- sf_data |>
    sf::st_transform(4326)
}

# combine
weas <- sf_data |>
  dplyr::filter((LEASE_STAGE == 'Active' & STATE != 'CA') | (LEASE_STAGE == 'Planning' & !CATEGORY1 %in% c('California Call Area', 'Hawaii Call Area', 'Oregon Call Area', 'Final Sale Notice'))) |>
  dplyr::mutate(PROJECT_NAME_1 = dplyr::if_else(is.na(PROJECT_NAME_1), LEASE_NUMBER_COMPANY, PROJECT_NAME_1)) |>
  dplyr::mutate(POPUP = ifelse(is.na(PROJECT_NAME_1), ADDITIONAL_INFORMATION, PROJECT_NAME_1))

# bounding box
bbox_weas <- weas |>
  dplyr::filter(LEASE_STAGE == 'Active') |>
  sf::st_bbox() |>
  as.vector()

# leaflet map
leaflet_weas <- leaflet::leaflet() |>
  leaflet::addTiles(urlTemplate = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") |>
  leaflet::fitBounds(lng1 = bbox_weas[1], lat1 = bbox_weas[2], lng2 = bbox_weas[3], lat2 = bbox_weas[4]) |>
  leaflet::addPolygons(data = weas |> dplyr::filter(LEASE_STAGE == 'Active'), group = 'Acive WEAs', popup = ~POPUP, color = '#0085CA') |>
  leaflet::addPolygons(data = weas |> dplyr::filter(LEASE_STAGE == 'Planning'), group = 'Planning WEAs', popup = ~POPUP, color = '#7171FF') |>
  leaflet::addEasyButton(leaflet::easyButton(icon = 'fa-home fa-lg', onClick = leaflet::JS("function(btn, map){ window.location.href = 'https://jmhatch-noaa.github.io/boemWind/'; }"))) |>
  leaflet::addLayersControl(overlayGroups = c('Active WEAs', 'Planning WEAs'), options = leaflet::layersControlOptions(collapsed = TRUE)) |>
  leaflet::hideGroup('Planning WEAs')

# save
htmlwidgets::saveWidget(leaflet_weas, file = here::here('leaflet_maps', 'boem_weas.html'), title = 'WEAs • boemWind')

# add favicon headers
active_html <- here::here('leaflet_maps', 'boem_weas.html') |>
  readLines()
active_out <- c(active_html[1:5],
                '<!-- favicons --><link rel="icon" type="image/png" sizes="16x16" href="../favicon-16x16.png">',
                '<link rel="icon" type="image/png" sizes="32x32" href="../favicon-32x32.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="180x180" href="../apple-touch-icon.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="120x120" href="../apple-touch-icon-120x120.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="76x76" href="../apple-touch-icon-76x76.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="60x60" href="../apple-touch-icon-60x60.png">',
                active_html[6:length(active_html)])
writeLines(active_out, here::here('leaflet_maps', 'boem_weas.html'))
