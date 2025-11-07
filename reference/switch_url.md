# switch_url

Based on `type`, provide the Direct Service Link to download GIS data
from BOEM's Office of Renewable Energy Program using their ArcGIS
server.

## Usage

``` r
switch_url(type)
```

## Arguments

- type:

  A character string for the type of GIS data that you would like to
  download. Can be:

  - `active lease outlines`

  - `planning area outlines`

  - `project phases`

  - `export cables`

  - `substations`

  - `turbine locations`

  - `cable interconnections`

  - `data collection devices`

  - `cable corridors`

  - `cable landings`

  - `interarray cables`

## Value

A url path.
