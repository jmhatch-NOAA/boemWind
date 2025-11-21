# Download GIS data from BOEM's Office of Renewable Energy Program

Query GIS data from BOEM's Office of Renewable Energy Program using
their ArcGIS server.

## Usage

``` r
query_boem(type)
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

A list with two named elements: 1) `meta` that stores metadata and 2)
`data` that stores an `sf` data frame.

## Examples

``` r
# basic usage
active_leases <- query_boem('active lease outlines') |>
  purrr::pluck('data')

# use stored data instead
active_leases_v2 <- boem_orep_outlines |>
  dplyr::filter(LEASE_STAGE == 'Active')
```
