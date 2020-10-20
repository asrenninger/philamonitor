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

library(tidycensus)

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
  mutate(pct = 100 * (value / summary_value)) %>%
  ggplot(aes(fill = pct)) +
  facet_wrap(~variable) +
  geom_sf(color = NA) +
  coord_sf(crs = 3857) +
  scale_fill_gradientn(colours = pal[2:10], 
                       guide = guide_continuous) +
  labs(title = "Philadelphia Demography", subtitle = "Resident mix by block group") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("demography.png", height = 8, width = 8, dpi = 300)

##

expectancy <- 
  read_csv("data/demography/life_expectancy.csv") %>%
  clean_names() %>%
  transmute(GEOID = tract_id,
            expectancy = e_0,
            st_error = se_e_0)
