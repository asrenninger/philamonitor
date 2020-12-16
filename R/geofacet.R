########################################
## Geofaceting
########################################

source("R/package.R")
source("R/help.R")

##

phila <- read_sf("data/processed/phila.geojson") %>% glimpse()
moves <- read_csv("data/processed/moves_monthly.csv") %>% glimpse()

##

pal <- read_csv("https://raw.githubusercontent.com/asrenninger/palettes/master/grered.txt", col_names = FALSE) %>% pull(X1)

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
                          str_detect(mapname, "Crestmont Farms|Parkwood Manor|Mechanicsville") ~ "Franklin Mills",
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

resulting_hex %>%
  transmute(name = name, 
            code = as.character(code),
            col = col,
            row = row,
            col2 = dense_rank(V1),
            row2 = dense_rank(-V2)) 

grid_preview(filter(facet, name != "Port Richmond"))

resulting_hex %>% select(row) %>% plot()

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
  ungroup()

joint %>%
  group_by(name) %>%
  mutate(lag0 = lag(visits),
         lag1 = lag(lag0),
         lag2 = lag(lag1),
         lag3 = lag(lag2),
         lag4 = lag(lag3),
         lag5 = lag(lag4),
         lag6 = lag(lag5),
         lag7 = lag(lag6),
         lag8 = lag(lag7),
         lag9 = lag(lag8),
         lag10 = lag(lag9),
         lag11 = lag(lag10),
         lag12 = lag(lag11),
         lag13 = lag(lag12)) %>%
  mutate(pct0 = (lag0 - visits) / visits,
         pct1 = (lag1 - lag0) / lag0,
         pct2 = (lag2 - lag1) / lag1,
         pct3 = (lag3 - lag2) / lag2,
         pct4 = (lag4 - lag3) / lag3,
         pct5 = (lag5 - lag4) / lag4,
         pct6 = (lag6 - lag5) / lag5) %>%
  drop_na() %>%
  ungroup() %>%
  group_by(date, name) %>%
  mutate(raw_change = (lag0 + lag1 + lag2 + lag3 + lag4 + lag5 + lag6 + lag7 + lag8 + lag9 + lag10 + lag11 + lag12 + lag13) / 14,
         pct_change = (pct0 + pct1 + pct2 + pct3 + pct4 + pct5 + pct6) / 7) %>%
  select(date, name, pct_change, raw_change) %>%
  ungroup() %>%
  ggplot(aes(x = as_date(date), y = raw_change)) +
  geom_line(colour = pal[1], size = 1) +
  facet_geo(~ name, grid = filter(facet, name != "Port Richmond"), scales = 'free_y') +
  xlab("") +
  ylab("") +
  labs(title = "7-Day rolling average", subtitle = "Weekly chnange by neighborhood") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = 'transparent', colour = 'transparent'),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.line.x = element_line(size = 0.5, colour = 'black'),
        axis.line.y = element_blank(),
        axis.ticks.x = element_line(size = 0.5, colour = 'black'),
        axis.ticks.y = element_blank(),
        axis.text.x = element_text(face = 'bold'),
        axis.text.y = element_blank(),
        plot.title = element_text(face = 'bold', colour = 'black', hjust = 0.5),
        plot.subtitle =  element_text(face = 'plain', colour = 'black', size = 15, hjust = 0.5),
        strip.text = element_text(face = 'bold', colour = 'black'),
        plot.margin = margin(20, 20, 20, 20)) + 
  ggsave("changexrolling.png", height = 20, width = 20, dpi = 300)

joint %>%
  mutate(week = week(date)) %>%
  group_by(name, week) %>%
  summarise(visits = mean(visits)) %>%
  ungroup() %>%
  drop_na() %>%
  ggplot(aes(x = ymd("2020-01-01") + weeks(week - 1), y = visits)) +
  geom_line(colour = pal[1], size = 1) +
  geom_line(data = joint %>%
              mutate(week = week(date)) %>%
              group_by(name, week) %>%
              summarise(visits = mean(visits)) %>%
              ungroup() %>%
              drop_na() %>%
              group_by(week) %>%
              summarise(visits = mean(visits)),
            aes(x = ymd("2020-01-01") + weeks(week - 1), y = visits),
            colour = '#707070', size = 1, linetype = 2) +
  facet_geo(~ name, grid = filter(facet, name != "Port Richmond"), scales = 'free_y') +
  xlab("") +
  ylab("") +
  labs(#title = "7-Day Rolling Average by Neighborhood", subtitle = "Weekly visit trends against city average",
       caption = "Dashed line is the mean change in travel across all neighborhoods") +
  theme_minimal() +
  theme(plot.background = element_rect(fill = 'transparent', colour = 'transparent'),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.minor.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.line.x = element_line(size = 0.5, colour = 'black'),
        axis.line.y = element_blank(),
        axis.ticks.x = element_line(size = 0.5, colour = 'black'),
        axis.ticks.y = element_blank(),
        axis.text.x = element_text(face = 'bold'),
        axis.text.y = element_blank(),
        plot.title = element_text(face = 'bold', colour = 'black', hjust = 0.5),
        plot.subtitle =  element_text(face = 'plain', colour = 'black', size = 15, hjust = 0.5),
        strip.text = element_text(face = 'bold', colour = 'black'),
        plot.margin = margin(20, 20, 20, 20)) + 
  ggsave("changexrolling.png", height = 20, width = 20, dpi = 300)

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

