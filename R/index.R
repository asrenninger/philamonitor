########################################
## Deprivation & Demography
########################################

source("R/package.R")
source("R/help.R")

##

moves <- vroom("data/processed/moves_monthly.csv")
phila <- read_sf("data/processed/phila.geojson")

##

vars <- c(White = "P005003",
          Black = "P005004",
          Asian = "P005006",
          Hispanic = "P004003")

demos <- get_decennial(geography = "block group", variables = vars,
                       state = "PA", county = "Philadelphia County", geometry = TRUE,
                       summary_var = "P001001")

##

demos %>%
  mutate(percent = 100 * (value / summary_value)) %>%
  ggplot(aes(fill = percent)) +
  facet_wrap(~variable) +
  geom_sf(color = NA) +
  coord_sf(crs = 3857) +
  scale_fill_gradientn(colours = pal[6:10], 
                       guide = guide_continuous) +
  labs(title = "Philadelphia Demography", subtitle = "Resident mix by block group") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("demography.png", height = 8, width = 8, dpi = 300)

##

blocks <- block_groups("PA", "Philadelphia", cb = TRUE, class = 'sf')
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


