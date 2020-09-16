########################################
## Explorations
########################################

source("R/package.R")
source("help.R")

##

library(fs)

##

files <- dir_ls("data/patterns_2020/07/Core-USA-July2020-Release-CORE_POI-2020_06-2020-07-13/")
files <- files[3:7]

##

poi <- map_df(files, vroom)

glimpse(poi)

##

phl <- 
  poi %>% 
  lazy_dt() %>%
  filter(city == "Philadelphia" & region == "PA") %>%
  as_tibble()

## 

reg <- 
  counties(cb = TRUE, class = 'sf') %>%
  filter(str_detect(STATEFP, "42|34|10|24")) %>%
  filter(str_detect(NAME, "Bucks|Chester|Delaware|Montgomery|Philadelphia|Burlington|Camden|Gloucester|New Castle|Salem|Cecil")) %>%
  filter(GEOID != "24031")

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

##

cbg <- 
  reduce(
    map(unique(reg$STATEFP), function(x){
      block_groups(x, cb = TRUE, class = 'sf')
    }),
    rbind
  ) %>%
  filter(str_sub(GEOID, 1, 5) %in% reg$GEOID)

##


    

