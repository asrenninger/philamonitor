########################################
## Geofaceting
########################################

source("R/package.R")
source("R/help.R")

##

phila <- read_sf("data/processed/phila.geojson") %>% glimpse()
moves <- read_csv("data/processed/moves_monthly.csv") %>% glimpse()

##

hoods <- read_sf("https://raw.githubusercontent.com/azavea/geo-data/master/Neighborhoods_Philadelphia/Neighborhoods_Philadelphia.geojson")

point <- 
  st_point(c(-75.163645, 39.952271)) %>% 
  st_sfc(crs = 4326) %>% 
  st_as_sf() %>%
  rename(geometry = x) %>%
  st_transform(3702) %>%
  st_buffer(5000) %>%
  mutate(area = st_area(geometry)) %>%
  select(area, geometry) %>%
  st_as_sf()

##

phila <- st_transform(phila, 3702)
hoods <- st_transform(hoods, 3702)


hoods <- 
  hoods %>%
  st_intersection(point) %>%
  mutate(code = 1:n(),
         name = mapname) %>%
  select(name, code, geometry) 

##

hoods <-
  hoods %>%
  mutate(name = case_when(str_detect(mapname, "Rittenhouse|Fitler") ~ "Rittenhouse Square",
                          str_detect(mapname, "Washington Square|Society") ~ "Washington Square",
                          str_detect(mapname, "Kensington") & !str_detect(mapname, "Upper") ~ "Kensington",
                          str_detect(mapname, "Poplar") ~ "Poplar",
                          str_detect(mapname, "Fairhill|McGuire|Upper Kensington") ~ "Fairhill",
                          str_detect(mapname, "Penrose|Clearview") ~ "Eastwick", 
                          str_detect(mapname, "Woodland") ~ "University City",
                          str_detect(mapname, "Germantown|Wister") ~ "Germantwon",
                          str_detect(mapname, "Mechanicsville") ~ "Parkwood Manor",
                          str_detect(mapname, "Crestmont Farms") ~ "Franklin Mills",
                          str_detect(mapname, "Haverford") ~ "Belmont",
                          str_detect(mapname, "Garden Court") ~ "Walnut Hill",
                          str_detect(mapname, "Southwest Schuylkill") ~ "Bartram Village",
                          str_detect(mapname, "Chinatown") ~ "Center City East", 
                          str_detect(mapname, "Passyunk Square|East Passyunk|Greenwich") ~ "Passyunk",
                          str_detect(mapname, "Hawthorne") ~ "Bella Vista", 
                          str_detect(mapname, "Narrows") ~ "Pennsport", 
                          str_detect(mapname, "Powelton") ~ "Mantua", 
                          str_detect(mapname, "Dunlap") ~ "Mill Creek",  
                          str_detect(mapname, "East Parkside|West Park") ~ "Parkside", 
                          str_detect(mapname, "Yorktown") ~ "Ludlow",
                          str_detect(mapname, "Nicetown") ~ "Tioga",
                          str_detect(mapname, "Germany Hill|Dearnley Park") ~ "Roxborough Park", 
                          str_detect(mapname, "Wissahickon Hills") ~ "Upper Roxborough",
                          str_detect(mapname, "Oak Lane|Melrose Park Gardens") ~ "Oak Lane",  
                          str_detect(mapname, "Crescentville") ~ "Summerdale", 
                          str_detect(mapname, "Burholme") ~ "Lawndale",
                          str_detect(mapname, "West Torresdale") ~ "Morrell Park", 
                          str_detect(mapname, "Millbrook|Modena|Parkwood Manor|Franklin Mills") ~ "Franklin Mills",
                          str_detect(mapname, "Byberry|Normandy Village") ~ "Normandy Village", 
                          str_detect(mapname, "Ogontz") ~ "Fern Rock", 
                          str_detect(mapname, "Aston-Woodbridge") ~ "Academy Gardens",
                          str_detect(mapname, "Sharswood") ~ "North Central",
                          TRUE ~ mapname)) %>% 
  group_by(name) %>% 
  summarise() %>% 
  mutate(code = 1:n()) %>%
  select(name, code, geometry)

plot(hoods)

##

cross <- 
  phila %>%
  st_intersection(hoods) %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            name = name,
            code = code) %>% 
  st_drop_geometry()

##

library(geogrid)
library(geofacet)

##

estimated_hex <- calculate_grid(shape = st_transform(hoods, 4326), grid_type = "regular", 
                                learning_rate = 0.03, seed = 1, verbose = TRUE)

resulting_hex <- assign_polygons(st_transform(hoods, 4326), estimated_hex)

resulting_hex %>% select(name, row, col) %>% tm_shape() + tm_polygons()

facet <-
  resulting_hex %>%
  transmute(name = name, 
            code = as.character(code),
            col = dense_rank(V1),
            row = dense_rank(-V2)) %>%
  st_drop_geometry()

resuling_hex %>%
  transmute(name = name, 
            code = as.character(code),
            col = col,
            row = row,
            col2 = dense_rank(V1),
            row2 = dense_rank(-V2)) 

grid_preview(facet)

resulting_hex %>% select(row) %>% plot()

##

library(prophet)

##

joint <- 
  moves %>%
  mutate(visits_by_day = str_remove_all(visits_by_day, pattern = "\\[|\\]"))  %>%
  separate_rows(visits_by_day, sep = ",") %>%
  mutate(month = month(date_range_start)) %>%
  group_by(safegraph_place_id, month) %>%
  mutate(day = 1:n()) %>%
  ungroup() %>%
  mutate(date = glue("2020-{month}-{day}")) %>%
  select(safegraph_place_id, date, visits_by_day) %>%
  mutate(visits_by_day = as.numeric(visits_by_day)) %>%
  left_join(cross) %>%
  group_by(date, name) %>%
  summarise(visits = sum(visits_by_day)) %>%
  ungroup() %>%
  rename(ds = date, 
         y = visits) %>%
  drop_na(name)

##

nested <-
  joint %>% 
  group_by(name) %>% 
  nest() %>%
  ungroup()

delts <- function(df) {
  
  proph <- prophet(df, weekly.seasonality = TRUE)
  tibble(dates = as_date(proph$changepoints),
         values = proph$params$delta[, ])
  
}

test <- 
  nested %>% 
  mutate(delta = map(data, delts)) %>%
  unnest(cols = delta)

ggplot(test, aes(x = as_date(dates), y = values)) +
  geom_bar(stat = 'identity', fill = pal[4]) +
  geom_hline(yintercept = 0) +
  facet_geo(~ name, grid = facet) +
  xlab("") +
  ylab("") +
  labs(title = "Strength of Change", subtitle = "Weekly jumps by neighborhood") +
  theme_hor() +
  ggsave("changexmagnitude.png", height = 20, width = 20, dpi = 300)

##

