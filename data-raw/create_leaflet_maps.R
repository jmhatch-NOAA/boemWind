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

# Active WEAs
active <- sf_data |>
  dplyr::filter(LEASE_STAGE == 'Active') |>
  dplyr::filter(STATE != 'CA') |>
  dplyr::mutate(PROJECT_NAME_1 = dplyr::if_else(is.na(PROJECT_NAME_1), LEASE_NUMBER_COMPANY, PROJECT_NAME_1))

# bounding box
bbox_active <- active |>
  sf::st_bbox() |>
  as.vector()

# leaflet map
leaflet_active <- leaflet::leaflet() |>
  leaflet::addTiles(urlTemplate = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") |>
  leaflet::fitBounds(lng1 = bbox_active[1], lat1 = bbox_active[2], lng2 = bbox_active[3], lat2 = bbox_active[4]) |>
  leaflet::addPolygons(data = active, popup = ~PROJECT_NAME_1) %>%
  leaflet::addEasyButton(leaflet::easyButton(icon = 'fa-home fa-lg', onClick = leaflet::JS("function(btn, map){ window.location.href = 'https://jmhatch-noaa.github.io/boemWind/'; }")))

# save
htmlwidgets::saveWidget(leaflet_active, file = here::here('leaflet_maps', 'active_weas.html'), title = 'Active WEAs • boemWind')

# add favicon headers
active_html <- here::here('leaflet_maps', 'active_weas.html') |>
  readLines()
active_out <- c(active_html[1:5],
                '<!-- favicons --><link rel="icon" type="image/png" sizes="16x16" href="../favicon-16x16.png">',
                '<link rel="icon" type="image/png" sizes="32x32" href="../favicon-32x32.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="180x180" href="../apple-touch-icon.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="120x120" href="../apple-touch-icon-120x120.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="76x76" href="../apple-touch-icon-76x76.png">',
                '<link rel="apple-touch-icon" type="image/png" sizes="60x60" href="../apple-touch-icon-60x60.png">',
                active_html[6:length(active_html)])
writeLines(active_out, here::here('leaflet_maps', 'active_weas.html'))

# Planning WEAs
planning <- sf_data |>
  dplyr::filter(LEASE_STAGE == 'Planning') |>
  dplyr::filter(!CATEGORY1 %in% c('California Call Area', 'Hawaii Call Area', 'Oregon Call Area', 'Final Sale Notice'))

# bounding box
bbox_planning <- planning |>
  sf::st_bbox() |>
  as.vector()

# leaflet map
leaflet_planning <- leaflet::leaflet() |>
  leaflet::addTiles(urlTemplate = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png") |>
  leaflet::fitBounds(lng1 = bbox_planning[1], lat1 = bbox_planning[2], lng2 = bbox_planning[3], lat2 = bbox_planning[4]) |>
  leaflet::addPolygons(data = planning, popup = ~ADDITIONAL_INFORMATION) %>%
  leaflet::addEasyButton(leaflet::easyButton(icon = 'fa-home fa-lg', onClick = leaflet::JS("function(btn, map){ window.location.href = 'https://jmhatch-noaa.github.io/boemWind/'; }")))

# save
htmlwidgets::saveWidget(leaflet_planning, file = here::here('leaflet_maps', 'planning_weas.html'), title = 'Planning WEAs • boemWind')

# add favicon headers
planning_html <- here::here('leaflet_maps', 'planning_weas.html') |>
  readLines()
planning_out <- c(planning_html[1:5],
                  '<!-- favicons --><link rel="icon" type="image/png" sizes="16x16" href="../favicon-16x16.png">',
                  '<link rel="icon" type="image/png" sizes="32x32" href="../favicon-32x32.png">',
                  '<link rel="apple-touch-icon" type="image/png" sizes="180x180" href="../apple-touch-icon.png">',
                  '<link rel="apple-touch-icon" type="image/png" sizes="120x120" href="../apple-touch-icon-120x120.png">',
                  '<link rel="apple-touch-icon" type="image/png" sizes="76x76" href="../apple-touch-icon-76x76.png">',
                  '<link rel="apple-touch-icon" type="image/png" sizes="60x60" href="../apple-touch-icon-60x60.png">',
                  planning_html[6:length(planning_html)])
writeLines(planning_out, here::here('leaflet_maps', 'planning_weas.html'))
