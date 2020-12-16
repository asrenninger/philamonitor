########################################
## Clusters
########################################

source("R/package.R")
source("R/help.R")

##

moves <- vroom("data/processed/moves_monthly.csv")
phila <- read_sf("data/processed/phila.geojson")

##

cross <- 
  phila %>%
  st_drop_geometry() %>%
  mutate(class = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                           str_detect(top_category, "Schools|Child") ~ "school",
                           str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                           str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                           str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                           str_detect(top_category, "Real Estate") ~ "real Estate",
                           str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                           str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                           str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                           str_detect(top_category, "Religious") ~ "worship",
                           TRUE ~ "other")) %>%
  distinct(top_category, .keep_all = TRUE) %>%
  select(top_category, class)

##

library("dbscan")

##

leisure <- 
  phila %>%
  left_join(cross) %>%
  filter(class == "leisure")

clusters <- dbscan(leisure %>%
                     st_transform(3857) %>%
                     st_coordinates() %>% 
                     as_tibble(), eps = 250, minPts = 5, weights = NULL, borderPoints = TRUE)

##

length(clusters$cluster)
unique(clusters$cluster)

clusters$cluster %>%
  enframe(name = NULL) %>%
  group_by(value) %>%
  summarise(n = n()) %>%
  arrange(desc(n))

clusters$cluster %>%
  enframe(name = NULL) %>%
  group_by(value) %>%
  summarise(n = n()) %>%
  arrange(n)

##

background <- 
  block_groups("PA", "Philadelphia", class = 'sf') %>%
  st_union() %>%
  st_combine() %>%
  st_transform(3702)

##

num <- length(unique(clusters$cluster))
fun <- colorRampPalette(pal)

##

set.seed(43)

##

ggplot() +
  geom_sf(data = background, aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_point(data = leisure %>%
               st_transform(3702) %>%
               st_coordinates() %>% 
               as_tibble(), 
             aes(X, Y, colour = factor(clusters$cluster)), 
             size = 0.5,
             show.legend = FALSE) +
  coord_sf(crs = 3702) +
  scale_colour_manual(values = c('#000000', sample(fun(num)[1:num]))) +
  labs(title = 'Leisure Corridors', subtitle = "Clusters of restaurants and bars") + 
  theme_map() +
  ggsave("clusters.png", height = 8, width = 6, dpi = 300)

##

clusters <- 
  leisure %>%
  st_transform(3702) %>%
  st_coordinates() %>% 
  as_tibble() %>%
  mutate(cluster = clusters$cluster) %>%
  bind_cols(leisure) %>%
  filter(cluster != 0) %>%
  st_as_sf() %>%
  st_transform(3702)

##

shape <- 
  block_groups("PA", "Philadelphia", cb = TRUE, class = 'sf') %>%
  st_transform(3702)

water <- 
  area_water("PA", "Philadelphia", class = 'sf') %>%
  st_transform(3702) %>%
  st_union() %>%
  st_combine()

background <- 
  shape %>%
  st_union() %>%
  st_combine() %>%
  st_difference(water) %>%
  ms_simplify(0.005)

##

grid <- 
  background %>% 
  st_make_grid(cellsize = 500) %>% 
  as_tibble() %>%
  rownames_to_column() %>%
  rename(id = rowname) %>%
  mutate(id = case_when(nchar(id) < 2 ~ paste("0000", {id}, sep = ""),
                        nchar(id) < 3 ~ paste("000", {id}, sep = ""),
                        nchar(id) < 4 ~ paste("00", {id}, sep = ""),
                        nchar(id) < 5 ~ paste("0", {id}, sep = ""),
                        TRUE ~ paste({id}))) %>%
  st_as_sf()

intersection <- st_intersection(grid, background)

dizz <- 
  grid %>% 
  filter(id %in% intersection$id) %>%
  st_union() %>% 
  st_combine()

##

cross <- 
  clusters %>%
  st_join(grid) %>% 
  transmute(cluster = cluster,
            id = id) %>% 
  st_drop_geometry()

##

joint <- 
  clusters %>%
  st_drop_geometry() %>%
  left_join(cross) %>%
  group_by(cluster, id) %>%
  summarise(n = n()) %>%
  left_join(grid) %>%
  st_as_sf()

##

ggplot(joint) +
  geom_sf(data = dizz, 
          aes(), fill = NA, colour = '#000000', lwd = 1) +
  geom_sf(aes(fill = factor(cluster)), 
          lwd = 0,
          colour = NA, 
          show.legend = FALSE) +
  coord_sf(crs = 3702) +
  scale_fill_manual(values = c(sample(fun(num)[1:num]))) +
  labs(title = 'Leisure Corridors', subtitle = "Clusters of restaurants and bars") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("grid.png", height = 12, width = 14, dpi = 300)

##

library(furrr)
future::plan(multiprocess)

##

fixed <- 
  moves %>% 
  select(safegraph_place_id, date_range_start, date_range_end, visits_by_day) %>%
  mutate(date_range_start = as_date(date_range_start),
         date_range_end = as_date(date_range_end)) %>%
  mutate(visits_by_day = str_remove_all(visits_by_day, pattern = "\\[|\\]")) %>% 
  mutate(visits_by_day = str_split(visits_by_day, pattern = ",")) %>%
  mutate(visits_by_day = future_map(visits_by_day, function(x){
    unlist(x) %>%
      as_tibble() %>%
      mutate(day = 1:n(),
             visits = value)
  })) %>%
  unnest(cols = c(visits_by_day))

##

cross <- 
  phila %>%
  st_drop_geometry() %>%
  mutate(class = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                           str_detect(top_category, "Schools|Child") ~ "school",
                           str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                           str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                           str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                           str_detect(top_category, "Real Estate") ~ "real Estate",
                           str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                           str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                           str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                           str_detect(top_category, "Religious") ~ "worship",
                           TRUE ~ "other")) %>%
  distinct(top_category, .keep_all = TRUE) %>%
  select(top_category, class)

##

corridors <- read_sf("http://data.phl.opendata.arcgis.com/datasets/f43e5f92d34e41249e7a11f269792d11_0.geojson") %>%
  clean_names() %>%
  transmute(corridor = name, 
            vacancy = str_remove_all(vac_rate, "[^0-9.]"),
            location = p_dist) %>%
  mutate(vacancy = as.numeric(vacancy)) %>%
  st_transform(3702)

plot(corridors)

##

leisure <- 
  phila %>% 
  left_join(cross) %>%
  filter(class == "leisure") %>%
  st_transform(3702) %>%
  st_join(corridors) %>%
  select(safegraph_place_id, corridor, vacancy, location)

ready <- 
  fixed %>%
  filter(safegraph_place_id %in% leisure$safegraph_place_id) %>%
  left_join(st_drop_geometry(leisure)) %>%
  drop_na(corridor) %>%
  mutate(date = glue("2020-{month(date_range_start)}-{day}"),
         visits = as.numeric(visits)) %>%
  mutate(date = as_date(date)) %>%
  mutate(week = week(date)) %>%
  group_by(corridor, week) %>%
  summarise(visits = sum(visits), n = n()) %>%
  ungroup() 

##

coord <- st_centroid(corridors)
  
dizzy <- st_transform(background, 3702)

##

shutdown <- 
  read_csv("https://raw.githubusercontent.com/Keystone-Strategy/covid19-intervention-data/master/complete_npis_inherited_policies.csv") %>% 
  filter(state == "Pennsylvania" & npi == "closing_of_public_venues" & county == "Philadelphia") %>%
  drop_na(start_date) %>%
  transmute(start_date = as_date(start_date, format = '%m/%d/%Y'),
            end_date = as_date(end_date, format = '%m/%d/%Y')) %>%
  mutate(start = week(start_date),
         end = week(end_date))

##

pal <- read_csv("https://raw.githubusercontent.com/asrenninger/palettes/master/grered.txt", col_names = FALSE) %>% pull(X1)

##

mapit <- function(id){
  
  locater <-
    ggplot() +
    geom_point(data = coord %>% 
                 filter(corridor == id) %>%
                 st_coordinates() %>%
                 as_tibble(), 
               aes(x = X, y = Y), 
               size = 20, colour = '#000000') +
    geom_sf(data = dizzy, aes(), fill = NA, colour = '#000000', lwd = 5) +
    theme_map()
  
  return(locater)
  
}

spark <- function(df){
  
  sparkline <- 
    ggplot(data = df, 
           aes(x = week, y = visits)) +
    geom_line(colour = pal[df$decile[1]], size = 10) +
    geom_vline(xintercept = shutdown$start, size = 5, linetype = 2) +
    geom_vline(xintercept = shutdown$end, size = 5, linetype = 2) +
    theme_void()
  
  return(sparkline)
  
}  

##

plots <- 
  ready %>%
  select(corridor, week, visits) %>%
  group_by(corridor) %>%
  mutate(change = (min(visits) - max(visits)) / max(visits)) %>%
  ungroup() %>%
  mutate(decile = ntile(change, 9)) %>%
  select(-change) %>%
  group_by(corridor) %>%
  nest() %>%
  mutate(plot = map(data, spark)) %>%
  select(-data)

maps <- 
  ready %>%
  distinct(corridor) %>%
  mutate(map = map(corridor, mapit))

##

top10 <-
  ready %>%
  group_by(corridor) %>%
  summarise(high = max(visits),
            low = min(visits),
            average = mean(visits)) %>%
  mutate(change = ((low - high) / high) * 100) %>%
  filter(high > 500) %>%
  left_join(maps) %>%
  left_join(plots) %>%
  select(map, corridor, high, low, average, change, plot) %>%
  arrange(desc(change)) %>%
  slice(1:20)

top10_plots <- select(top10, corridor, plot, map)
top10 <- select(top10, corridor, high, low, average, change)

bot10 <-
  ready %>%
  group_by(corridor) %>%
  summarise(high = max(visits),
            low = min(visits),
            average = mean(visits)) %>%
  mutate(change = ((low - high) / high) * 100) %>%
  filter(high > 500) %>%
  left_join(maps) %>%
  left_join(plots) %>%
  select(map, corridor, high, low, average, change, plot) %>%
  arrange(change) %>%
  slice(1:20)

bot10_plots <- select(bot10, corridor, plot, map)
bot10 <- select(bot10, corridor, high, low, average, change)

##

library(gt)

##

bot10 %>% 
  mutate(ggplot = NA, ggmap = NA) %>%
  select(ggmap, corridor, high, low, average, change, ggplot) %>%
  rename(`% change` = change) %>%
  gt() %>% 
  tab_header(title = html("<b>Nigh Life Hubs: bottom twenty</b>"),
             subtitle = md("Weekly visits to various economic clusters<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Period spanning January to August 2020"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`corridor`))) %>% 
  cols_label(ggmap = "") %>% 
  text_transform(locations = cells_body(columns = vars(`ggmap`)),
                 fn = function(x) {map(bot10_plots$map, ggplot_image, height = px(30), aspect_ratio = 1)}) %>%
  data_color(columns = vars(`% change`),
             colors = scales::col_numeric(c(pal), domain = NULL)) %>% 
  cols_align(align = "center",
             columns = 2:5) %>% 
  opt_table_font(font = list(c("IBM Plex Sans"))) %>% 
  tab_options(heading.title.font.size = 30,
              heading.subtitle.font.size = 15,
              heading.align = "left",
              table.border.top.color = "white",
              heading.border.bottom.color = "white",
              table.border.bottom.color = "white",
              column_labels.border.bottom.color = "grey",
              column_labels.border.bottom.width= px(1)) %>% 
  cols_label(ggplot = "trend") %>% 
  text_transform(locations = cells_body(columns = vars(`ggplot`)),
                 fn = function(x) {map(bot10_plots$plot, ggplot_image, height = px(20), aspect_ratio = 5)}) %>%
  gtsave("worst.png", expand = 10)

top10 %>% 
  mutate(ggplot = NA, ggmap = NA) %>%
  select(ggmap, corridor, high, low, average, change, ggplot) %>%
  rename(`% change` = change) %>%
  gt() %>% 
  tab_header(title = html("<b>Nigh Life Hubs: top twenty</b>"),
             subtitle = md("Weekly visits to various economic clusters<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Period spanning January to August 2020"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`corridor`))) %>% 
  cols_label(ggmap = "") %>% 
  text_transform(locations = cells_body(columns = vars(`ggmap`)),
                 fn = function(x) {map(top10_plots$map, ggplot_image, height = px(30), aspect_ratio = 1)}) %>%
  data_color(columns = vars(`% change`),
             colors = scales::col_numeric(c(pal), domain = NULL)) %>% 
  cols_align(align = "center",
             columns = 2:5) %>% 
  opt_table_font(font = list(c("IBM Plex Sans"))) %>% 
  tab_options(heading.title.font.size = 30,
              heading.subtitle.font.size = 15,
              heading.align = "left",
              table.border.top.color = "white",
              heading.border.bottom.color = "white",
              table.border.bottom.color = "white",
              column_labels.border.bottom.color = "grey",
              column_labels.border.bottom.width= px(1)) %>% 
  cols_label(ggplot = "trend") %>% 
  text_transform(locations = cells_body(columns = vars(`ggplot`)),
                 fn = function(x) {map(top10_plots$plot, ggplot_image, height = px(20), aspect_ratio = 5)}) %>%
  gtsave("best.png", expand = 10)

##

corridors %>% 
  filter(corridor == "Market East" | corridor == "Market West") %>% 
  group_by(corridor) %>% 
  summarise()

ggplot(ready %>%
         group_by(corridor) %>%
         summarise(high = max(visits),
                   low = min(visits),
                   recent = last(visits),
                   average = mean(visits)) %>%
         mutate(change = ((recent - high) / high) * 100) %>%
         left_join(corridors) %>%
         st_as_sf()) +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 1) +
  geom_sf(aes(fill = factor(ntile(change, 9))), 
          lwd = 0,
          colour = NA) +
  geom_sf(data =
            corridors %>% 
            filter(corridor == "Market East" | corridor == "Market West") %>% 
            group_by(corridor) %>% 
            summarise(),
          aes(), 
          lwd = 1,
          fill = NA, 
          colour = '#070707') +  
  coord_sf(crs = 3702) +
  scale_fill_manual(values = pal,
                    labels = as.character(round(quantile(ready %>%
                                                           group_by(corridor) %>%
                                                           summarise(high = max(visits),
                                                                     low = min(visits),
                                                                     recent = last(visits),
                                                                     average = mean(visits)) %>%
                                                           mutate(change = ((recent - high) / high) * 100) %>%
                                                           pull(change),
                                                         c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
                                                         na.rm = TRUE))),
                    name = "% change from high mark to most recent month",
                    guide = guide_discrete) +
  #labs(title = 'Leisure Corridors', subtitle = "Clusters of restaurants and bars") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("corridors.png", height = 12, width = 14, dpi = 300)

##

centroid <- 
  phila %>% 
  filter(str_detect(location_name, "City Hall")) %>% 
  st_transform(3702) %>% 
  st_coordinates() %>% 
  as_tibble()

location <- 
  coord %>%
  st_coordinates() %>% 
  as_tibble()

##

library(spdep)
library(FNN)

##

nn <- get.knnx(centroid, location, k = 1)

##

distance <- 
  coord %>% 
  st_drop_geometry() %>% 
  mutate(distance = nn$nn.dist[, 1]) %>%
  select(corridor, distance)

joined <- 
  ready %>%
  group_by(corridor) %>%
  summarise(high = max(visits),
            low = min(visits),
            average = mean(visits)) %>%
  mutate(change = ((low - high) / high) * 100) %>%
  left_join(distance) %>%
  mutate(percentile = ntile(average, 100)) %>%
  filter(percentile < 96 & percentile > 4)

p1 <- 
  ggplot(joined, aes(distance, average)) +
  geom_point(colour = pal[7]) + 
  geom_smooth(method = lm, se = FALSE, colour = pal[9]) +
  ylab("average visits") +
  xlab("distance to city hall") +
  theme_ver()

p2 <- 
  ggplot(joined, aes(distance, change)) +
  geom_point(colour = pal[7]) + 
  geom_smooth(method = lm, se = FALSE, colour = pal[9]) +
  ylab("% change in visits") +
  xlab("distance to city hall") +
  theme_ver()

##

library(patchwork)  

##

p <- p1 + p2 & plot_annotation(title = "Corridor Activity", subtitle = "The relationship between distance to City Hall and visits") & theme_ver()

ggsave(p, filename = "relationships.png", height = 4, width = 8)  

##

joined <- 
  ready %>%
  left_join(distance) %>%
  mutate(percentile = ntile(visits, 100)) %>%
  filter(percentile < 96 & percentile > 4)

##

library(gganimate)

##

anim <- 
  ggplot(joined, aes(distance, visits)) +
  geom_point(colour = pal[7]) + 
  geom_smooth(method = lm, se = FALSE, colour = pal[9]) +
  ylab("average visits") +
  xlab("distance to city hall") +
  labs(title = "Activity-Centrality Relationship", subtitle = "Week {current_frame}") + 
  transition_manual(week) +
  ease_aes() + 
  theme_ver() 

anim_save("relationships.gif", animation = anim, 
          height = 600, width = 800, fps = 2)


