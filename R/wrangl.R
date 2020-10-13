########################################
## Explorations
########################################

source("R/package.R")
source("R/help.R")

##

files <- dir_ls("data/places_2020/09/Core-USA-Sep-CORE_POI-2020_08-2020-09-08")
files <- files[3:7]

##

poi <- map_df(files, vroom)

glimpse(poi)

##

cbg <- block_groups("PA", "Philadelphia", cb = TRUE, class = 'sf')

##

phl <- 
  poi %>% 
  filter(city == "Philadelphia" & region == "PA") %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326, remove = FALSE) %>% 
  st_transform(4269) %>%
  st_intersection(cbg)

## 

reg <- 
  counties(cb = TRUE, class = 'sf') %>%
  filter(str_detect(STATEFP, "42|34|10|24")) %>%
  filter(str_detect(NAME, "Bucks|Chester|Delaware|Montgomery|Philadelphia|Burlington|Camden|Gloucester|New Castle|Salem|Cecil")) %>%
  filter(GEOID != "24031")

cbg <- 
  reduce(
    map(unique(reg$STATEFP), function(x){
      block_groups(x, cb = TRUE, class = 'sf')
    }),
    rbind
  ) %>%
  filter(str_sub(GEOID, 1, 5) %in% reg$GEOID)

##

met <- 
  poi %>% 
  lazy_dt() %>%
  filter(str_detect(region, "PA|NJ|DE")) %>%
  as_tibble() %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) %>%
  st_transform(4269) %>%
  st_intersection(reg)

##

met %>% 
  st_drop_geometry() %>%
  group_by(top_category) %>% 
  summarise(n = n()) %>%
  ungroup() %>%
  arrange(desc(n)) %>%
  slice(1:10) %>%
  rename(category = top_category) %>%
  knitr::kable()

phl %>% 
  group_by(top_category) %>% 
  summarise(n = n()) %>%
  ungroup() %>%
  arrange(desc(n)) %>%
  slice(1:10) %>%
  rename(category = top_category) %>%
  knitr::kable()

##

map <- 
  tm_shape(phl) +
  tm_dots() +
  tm_layout("Points of Interest, Philadelphia",
            title.fontface = 'bold',
            frame.lwd = 0)

tmap_save(map, height = 8, width = 8, dpi = 300)

##

library(tidycensus)

##

pop <- get_acs(year = 2018, geography = "block group", state = "PA", county = "Philadelphia", variables = "B01001_001", geometry = TRUE)

##

dev <- 
  vroom("data/home_panel_summary/2020/09/09/18/home_panel_summary.csv") %>%
  transmute(GEOID = census_block_group,
            devices = number_devices_residing) %>%
  filter(GEOID %in% pop$GEOID)

com <- 
  pop %>% 
  transmute(GEOID = GEOID,
            population = estimate) %>%
  left_join(dev) %>%
  replace_na(list("devices" = 0)) %>%
  mutate(percent = devices / population)

##

map <- tm_shape(com %>% 
           filter(percent < 0.5)) +
  tm_fill(col = "percent") + 
  tm_layout("Devices Against Population",
            title.fontface = 'bold',
            frame.lwd = 0) +
  tm_shape(com %>% 
             st_union() %>% 
             st_combine()) +
  tm_borders()

tmap_save(map, "devices.png", height = 8, width = 8, dpi = 300)

##

files <- dir_ls("data/patterns_2020_weekly/2020/09/09/18")
files <- files[2:5]

##

flo <- 
  map_df(files, vroom) %>% 
  lazy_dt() %>%
  filter(safegraph_place_id %in% phl$safegraph_place_id) %>%
  as_tibble()

glimpse(flo)
glimpse(phl)

##

new <- 
  flo %>% 
  select(safegraph_place_id, visitor_home_cbgs) %>%
  mutate(visitor_home_cbgs = map(visitor_home_cbgs, function(x){
    jsonlite::fromJSON(x) %>% 
      as_tibble()
    })) %>% 
  unnest(visitor_home_cbgs) %>%
  pivot_longer(!safegraph_place_id, names_to = "cbg", values_to = "visits") %>%
  drop_na(visits)

sgp <- 
  phl %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            LOCALE = GEOID) %>% 
  st_drop_geometry()

mat <- 
  new %>%
  mutate(GEOID = cbg) %>% 
  select(GEOID, safegraph_place_id, visits) %>%
  left_join(sgp) %>%
  group_by(GEOID, LOCALE) %>% 
  summarise(visits = sum(visits)) %>%
  ungroup() %>%
  left_join(cbg) %>%
  drop_na(NAME) %>% 
  select(GEOID, LOCALE, visits, geometry) %>%
  st_as_sf()
  
top <- 
  mat %>% 
  st_drop_geometry() %>%
  group_by(LOCALE) %>%
  summarise(n = sum(visits)) %>%
  ungroup() %>%
  arrange(desc(n)) %>%
  slice(1:4) %>%
  pull(LOCALE)
 
map <- 
  tm_shape(mat %>%
           filter(LOCALE == "421019807001")) +
  tm_fill(col = 'visits') +
  tm_shape(cbg %>%
             filter(GEOID == "421019807001")) +
  tm_borders() +
  tm_shape(cbg %>% 
             st_union() %>%
             st_combine()) +
  tm_borders() +
  tm_layout("Sampling Visits",
            title.fontface = 'bold',
            frame.lwd = 0)

tmap_save(map, "visits.png", height = 8, 8)

##

sgl <- 
  phl %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            LOCALE = location_name) %>% 
  st_drop_geometry()

mat <- 
  new %>%
  mutate(GEOID = cbg) %>% 
  select(GEOID, safegraph_place_id, visits) %>%
  left_join(sgl) %>%
  group_by(LOCALE, GEOID) %>%
  summarise(visits = sum(visits)) %>%
  left_join(cbg) %>%
  drop_na(NAME) %>% 
  select(GEOID, LOCALE, visits, geometry) %>%
  st_as_sf()

##




