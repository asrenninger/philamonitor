########################################
## Vrooming
########################################

source("R/package.R")
source("R/help.R")

##

files <- dir_ls("data/places_2020/09/Core-USA-Sep-CORE_POI-2020_08-2020-09-08")
files <- files[3:7]

##

poi <- map_df(files, vroom) %>% glimpse()

##

cbg <- block_groups("NY", "New York", cb = TRUE, class = 'sf')

##

phl <- 
  poi %>% 
  filter(city == "Philadelphia" & region == "PA") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE) %>% 
  st_transform(4269) %>%
  st_intersection(cbg)

##

files <- dir_ls("data/patterns_2020_monthly/2020", recurse = TRUE, type = 'file')
files <- files[!str_detect(files, "_SUCCESS")]

##

phila <- read_sf("data/processed/phila.geojson")

##

vroom(files[length(files)]) %>% glimpse()

moves <- map_df(files, function(x) {
  vroom(x) %>%
    filter(safegraph_place_id %in% phila$safegraph_place_id)
})

moves %>% 
  group_by(safegraph_place_id) %>%
  summarise(n = n()) %>%
  ungroup() %>%
  group_by(n) %>%
  summarise(sum = n())




