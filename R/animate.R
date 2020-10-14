########################################
## Animating
########################################

source("R/package.R")
source("R/help.R")

##

phila <- read_sf("data/processed/phila.geojson") %>% glimpse()
moves <- read_csv("data/processed/moves_monthly.csv") %>% glimpse()

##

hoods <- read_sf("https://raw.githubusercontent.com/azavea/geo-data/master/Neighborhoods_Philadelphia/Neighborhoods_Philadelphia.geojson")

##

phila <- st_transform(phila, 3702)
hoods <- st_transform(hoods, 3702)

##

cross <- 
  phila %>%
  st_join(hoods) %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            neighborhood = mapname) %>% 
  st_drop_geometry()

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
  group_by(date, neighborhood) %>%
  summarise(visits = sum(visits_by_day)) %>%
  ungroup() %>%
  rename(ds = date, 
         y = visits) %>%
  drop_na(neighborhood)

##

nested <-
  joint %>% 
  group_by(neighborhood) %>% 
  nest() %>%
  ungroup()

##

delts <- function(df) {
  
  proph <- prophet(df, weekly.seasonality = TRUE)
  tibble(dates = as_date(proph$changepoints),
         value = proph$params$delta[, ])
  
}

##

tested <- 
  nested %>% 
  mutate(delta = map(data, delts)) %>%
  unnest(cols = delta) %>%
  select(-data) %>%
  left_join(transmute(hoods, neighborhood = mapname)) %>%
  st_as_sf()

##

library(gganimate)

##

tested %>%
  st_drop_geometry() %>%
  group_by(neighborhood) %>%
  summarise(n = n()) %>%
  pull(n) %>%
  unique()

##

ggplot(tested) +
  geom_sf(data = hoods %>% st_combine() %>% st_union(),
          aes(), fill = NA, colour = pal[1], lwd = 1) +
  geom_sf(aes(fill = factor(ntile(value, 9))), colour = NA, lwd = 0) +
  scale_fill_manual(values = pal[2:10],
                    labels = as.character(scientific(quantile(tested$value,
                                                              c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
                                                              na.rm = TRUE), digits = 4)),
                    name = "strength of change",
                    guide = guide_discrete) +
  facet_wrap(~ dates) +
  labs(title = 'Time-Space Patterns', subtitle = "Rate changes at various points") +
  theme_map() +
  theme(legend.position = 'bottom',
        legend.text = element_text(size = 4)) +
  ggsave("test.png", height = 10, width = 6)

##

anim <- 
  ggplot(tested) +
  geom_sf(data = hoods %>% st_combine() %>% st_union(),
          aes(), fill = NA, colour = pal[1], lwd = 1) +
  geom_sf(aes(fill = factor(ntile(value, 9))), colour = NA, lwd = 0) +
  scale_fill_manual(values = pal[2:10],
                    labels = as.character(scientific(quantile(tested$value,
                                                              c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
                                                              na.rm = TRUE), digits = 4)),
                    name = "strength of change",
                    guide = guide_discrete) +
  labs(title = 'Time-Space Patterns', subtitle = "Rate changes on {month(as_date(current_frame), label = TRUE)} {day(as_date(current_frame))}") +
  transition_manual(dates) +
  theme_map() +
  theme(legend.position = 'bottom',
        legend.text = element_text(size = 4))

anim_save("changes.gif", animation = anim, 
          height = 600, width = 800, fps = 2,
          start_pause = 2, end_pause = 2)

##

long <- 
  moves %>%
  mutate(location_name = case_when(str_detect(location_name, "Lincoln Technical Institute") ~ "University of Pennsylvania",
                                   TRUE ~ location_name)) %>%
  mutate(visits_by_day = str_remove_all(visits_by_day, pattern = "\\[|\\]"))  %>%
  separate_rows(visits_by_day, sep = ",") %>%
  mutate(month = month(date_range_start)) %>%
  group_by(safegraph_place_id, month) %>%
  mutate(day = 1:n()) %>%
  ungroup() %>%
  mutate(date = glue("2020-{month}-{day}"),
         week = week(date)) %>%
  mutate(visits_by_day = as.numeric(visits_by_day))

sums <-
  long %>%
  lazy_dt() %>%
  group_by(location_name, week) %>%
  summarise(visits = n()) %>%
  ungroup() %>%
  as_tibble()

ranks <- 
  sums %>%
  lazy_dt() %>%
  group_by(week) %>%
  arrange(week, -visits) %>%
  mutate(rank = 1:n()) %>%
  ungroup() %>%
  filter(rank <= 10) %>%
  as_tibble()

base <- 
  ggplot(ranks %>%
           mutate(location_name = str_replace_all(location_name, pattern = " \\(.*?\\)", replacement = ""))) +  
  aes(xmin = 0 ,  
      xmax = visits) +  
  aes(ymin = rank - .45,  
      ymax = rank + .45,  
      y = rank) +  
  geom_rect(alpha = .7) + 
  aes(fill = visits) +  
  scale_fill_gradientn(colours = rev(pal[2:10]),
                       guide = 'none') +  
  geom_text(aes(x = visits - 10, y = rank, label = location_name), hjust = 1, col = pal[1], fontface = 'bold', size = 5) +
  scale_y_reverse() +  
  labs(fill = NULL) +  
  labs(x = 'activity (visits)') +  
  labs(y = "") +
  theme_rot() +
  theme(axis.text.y = element_blank())

anim <- 
  base +
  geom_text(x = 800 , y = -10, hjust = 1, 
            aes(label = paste("week", week, sep = " ")),
            size = 20, col = pal[11]) +
  aes(group = location_name) +
  transition_time(week) +
  ease_aes("cubic-in-out")
  
anim_save("bars.gif", animation = anim, 
          height = 800, width = 800, fps = 5,
          start_pause = 2, end_pause = 2)

  
