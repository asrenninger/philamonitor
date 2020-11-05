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
  st_make_grid(cellsize = 250) %>% 
  as_tibble() %>%
  rownames_to_column() %>%
  rename(id = rowname) %>%
  mutate(id = case_when(nchar(id) < 2 ~ paste("000", {id}, sep = ""),
                        nchar(id) < 3 ~ paste("00", {id}, sep = ""),
                        nchar(id) < 4 ~ paste("0", {id}, sep = ""),
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

phila %>%
  left_join(cross) %>%
  filter(class == "leisure") %>%
  mutate(cluster = clusters$cluster) %>%
  filter(cluster != 0) %>%
  group_by(cluster) %>%
  summarise() %>%
  mutate(geometry = st_convex_hull(geometry)) %>%
  plot()

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

leisure <- 
  phila %>%
  st_drop_geometry() %>%
  left_join(cross) %>%
  filter(class == "leisure") %>%
  mutate(cluster = clusters$cluster) %>%
  select(safegraph_place_id, cluster)

ready <- 
  fixed %>%
  filter(safegraph_place_id %in% leisure$safegraph_place_id) %>%
  left_join(leisure) %>%
  filter(cluster != 0) %>%
  mutate(date = glue("2020-{month(date_range_start)}-{day}"),
         visits = as.numeric(visits)) %>%
  mutate(date = as_date(date)) %>%
  mutate(week = week(date)) %>%
  group_by(cluster, week) %>%
  summarise(visits = sum(visits)) %>%
  ungroup()

##

coord <-
  phila %>%
  left_join(cross) %>%
  filter(class == "leisure") %>%
  mutate(cluster = clusters$cluster) %>%
  group_by(cluster) %>%
  summarise() %>%
  mutate(geometry = st_convex_hull(geometry)) %>%
  st_centroid() %>%
  st_transform(3701)

dizzy <- 
  background %>% 
  st_transform(3701)

##

mapit <- function(id){
  
  locater <-
    ggplot() +
    geom_point(data = coord %>% 
                 filter(cluster == id) %>%
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
    geom_line(colour = rev(pal[1:9])[df$decile[1]], size = 10) +
    theme_void()
  
  return(sparkline)
  
}  

##

plots <- 
  ready %>%
  select(cluster, week, visits) %>%
  group_by(cluster) %>%
  mutate(decile = ntile(mean(visits), 9)) %>%
  ungroup() %>%
  group_by(cluster) %>%
  nest() %>%
  mutate(plot = map(data, spark)) %>%
  select(-data)

maps <- 
  ready %>%
  distinct(cluster) %>%
  mutate(map = map(cluster, mapit))

##

top10 <-
  ready %>%
  group_by(cluster) %>%
  summarise(high = max(visits),
            low = min(visits),
            average = mean(visits)) %>%
  mutate(change = (low - high) / high) %>%
  filter(high > 500) %>%
  left_join(maps) %>%
  left_join(plots) %>%
  select(map, cluster, high, low, average, change, plot) %>%
  arrange(desc(change)) %>%
  slice(1:10)

top10_plots <- select(top10, cluster, plot, map)
top10 <- select(top10, cluster, high, low, average, change)

bot10 <-
  ready %>%
  group_by(cluster) %>%
  summarise(high = max(visits),
            low = min(visits),
            average = mean(visits)) %>%
  mutate(change = (low - high) / high) %>%
  filter(high > 500) %>%
  left_join(maps) %>%
  left_join(plots) %>%
  select(map, cluster, high, low, average, change, plot) %>%
  arrange(change) %>%
  slice(1:10)

bot10_plots <- select(bot10, cluster, plot, map)
bot10 <- select(bot10, cluster, high, low, average, change)

##

library(gt)

##

pal <- read_csv("https://raw.githubusercontent.com/asrenninger/palettes/master/grered.txt", col_names = FALSE) %>% pull(X1)

##

bot10 %>% 
  mutate(ggplot = NA, ggmap = NA) %>%
  select(ggmap, cluster, high, low, average, change, ggplot) %>%
  gt() %>% 
  tab_header(title = html("<b>Nigh Life Hubs: bottom ten</b>"),
             subtitle = md("Weekly visits to various economic clusters<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Period spanning January to August 2020"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`cluster`))) %>% 
  cols_label(ggmap = "") %>% 
  text_transform(locations = cells_body(columns = vars(`ggmap`)),
                 fn = function(x) {map(bot10_plots$map, ggplot_image, height = px(30), aspect_ratio = 1)}) %>%
  data_color(columns = vars(`change`),
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
  select(ggmap, cluster, high, low, average, change, ggplot) %>%
  gt() %>% 
  tab_header(title = html("<b>Nigh Life Hubs: top ten</b>"),
             subtitle = md("Weekly visits to various economic clusters<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Period spanning January to August 2020"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`cluster`))) %>% 
  cols_label(ggmap = "") %>% 
  text_transform(locations = cells_body(columns = vars(`ggmap`)),
                 fn = function(x) {map(top10_plots$map, ggplot_image, height = px(30), aspect_ratio = 1)}) %>%
  data_color(columns = vars(`change`),
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





