########################################
## Deprivation & Demography
########################################

source("R/package.R")
source("R/help.R")

##

moves <- vroom("data/processed/moves_monthly.csv")
phila <- read_sf("data/processed/phila.geojson")

##

blocks <- block_groups("PA", "Philadelphia", cb = TRUE, class = 'sf')

##

sf1 <- c(White = "P005003",
         Black = "P005004",
         Asian = "P005006",
         Hispanic = "P004003")

race <- get_decennial(geography = "block group", variables = sf1,
                       state = "PA", county = "Philadelphia County", geometry = TRUE,
                       summary_var = "P001001")

##

race %>%
  mutate(percent = 100 * (value / summary_value)) %>%
  ggplot(aes(fill = percent)) +
  facet_wrap(~variable) +
  geom_sf(color = NA) +
  coord_sf(crs = 3857) +
  scale_fill_gradientn(colours = pal, 
                       guide = guide_continuous) +
  labs(title = "Philadelphia Demography", subtitle = "Resident mix by block group") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("demography.png", height = 8, width = 8, dpi = 300)

##

odmat <- vroom("data/processed/od_monthly.csv")

black <- 
  race %>%
  st_drop_geometry() %>%
  filter(variable == "Black") %>%
  mutate(value = value / summary_value) %>%
  transmute(cbg = GEOID, pct_black = value)

##

datum <- 
  odmat %>%
  mutate(month = lubridate::month(start, label = TRUE, abbr = FALSE)) %>% 
  left_join(phila) %>% 
  rename(geocode1 = GEOID) %>%
  select(location_name, safegraph_place_id, cbg, visits, month, geocode1) %>%
  rename(GEOID = cbg) %>% 
  left_join(blocks) %>%
  drop_na(ALAND, AWATER) %>% 
  st_as_sf() %>%
  transmute(geocode1 = geocode1,
            geocode2 = GEOID,
            visits = visits,
            month = month) %>%
  st_drop_geometry()

##

lines <- stplanr::od2line(flow = datum, zones = transmute(blocks, geocode = GEOID))

distances <- 
  lines %>%
  st_transform(3857) %>% 
  mutate(distance = st_length(geometry)) %>%
  mutate(percentile = ntile(distance, 100)) %>%
  filter(percentile > 4 & percentile < 96) %>%
  rename(cbg = geocode2) %>%
  st_drop_geometry() %>%
  group_by(month, cbg) %>%
  summarise(distance = mean(distance))

joined <- left_join(distances, black)
  
##

anim <- 
  ggplot(joined, aes(pct_black, as.numeric(distance))) +
  geom_point(colour = pal[7]) + 
  geom_smooth(method = lm, se = FALSE, colour = pal[9]) +
  ylab("mean travel distance by neighborhood") +
  xlab("percent african american") +
  labs(title = "Race-Activity Relationship", subtitle = "{current_frame}") + 
  transition_manual(month) +
  ease_aes() + 
  theme_ver() 

anim_save("race.gif", animation = anim, 
          height = 400, width = 600)

##

tracts <- tracts("PA", "Philadelphia", cb = TRUE, class = 'sf')

##

library(tidycensus)

##

vars <- load_variables(year = 2018, dataset = 'acs5')

vars %>% filter(str_detect(str_to_lower(label), "african american"))
vars %>% filter(str_detect(str_to_lower(label), "education"))

##

acs <- c(income = "B06011_001",
         black = "B02001_003",
         education = "B06009_005",
         gini = "B19083_001", 
         population = "B01001_001")

demos <- get_acs(geography = 'tract', variables = acs, 
                 state = "PA", county = "Philadelphia County", geometry = TRUE,
                 summary_var = "B01001_001")

demos <- demos %>%
  mutate(estimate = case_when(variable == "black" ~ (estimate / summary_est),
                              variable == "education" ~ (estimate / summary_est),
                              TRUE ~ estimate)) %>%
  select(GEOID, variable, estimate) %>%
  #pivot_wider(id_cols = 'GEOID', names_from = 'variable', values_from = 'estimate')
  spread(key = 'variable', value = 'estimate')

##

expectancy <- 
  read_csv("data/demography/life_expectancy.csv") %>%
  clean_names() %>%
  transmute(GEOID = tract_id,
            expectancy = e_0)

##

tmap_mode("view")

tm_shape(demos %>% select(population)) +
  tm_fill(col = "population") +
  tm_shape(demos %>% select(income)) +
  tm_fill(col = "income")

