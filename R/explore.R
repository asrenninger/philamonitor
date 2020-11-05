########################################
## Exploring
########################################

source("R/package.R")
source("R/help.R")

##

phila <- read_sf("data/processed/phila.geojson") %>% glimpse()
moves <- read_csv("data/processed/moves_monthly.csv") %>% glimpse()

##

hoods <- read_sf("https://raw.githubusercontent.com/azavea/geo-data/master/Neighborhoods_Philadelphia/Neighborhoods_Philadelphia.geojson")

##

tictoc::tic()

fixed <- 
  moves %>% 
  select(safegraph_place_id, date_range_start, date_range_end, visits_by_day) %>%
  mutate(date_range_start = as_date(date_range_start),
         date_range_end = as_date(date_range_end)) %>%
  mutate(visits_by_day = str_remove_all(visits_by_day, pattern = "\\[|\\]")) %>% 
  mutate(visits_by_day = str_split(visits_by_day, pattern = ",")) %>%
  mutate(visits_by_day = map(visits_by_day, function(x){
    unlist(x) %>%
      as_tibble() %>%
      mutate(day = 1:n(),
             visits = value)
  })) %>%
  unnest(cols = c(visits_by_day))

tictoc::toc()

library(furrr)
future::plan(multiprocess)

tictoc::tic()

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

tictoc::toc()

##

phila <- st_transform(phila, 3702)
hoods <- st_transform(hoods, 3702)

cross <- 
  phila %>%
  st_join(hoods) %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            neighborhood = mapname) %>% 
  st_drop_geometry()

##

hoods <- 
  fixed %>% 
  mutate(mon = month(date_range_start),
         date = as_date(glue("2020-{mon}-{day}"))) %>%
  left_join(cross) %>%
  mutate(visits = as.numeric(visits)) %>%
  group_by(neighborhood, date) %>%
  summarise(visits = sum(visits)) %>%
  ungroup()

test <-
  hoods %>%
  filter(neighborhood != "Pennypack Park") %>%
  mutate(week = week(date)) %>%
  group_by(neighborhood, week) %>%
  summarise(visits = mean(visits)) %>%
  ungroup() %>%
  group_by(neighborhood) %>%
  mutate(best = max(visits),
         worst = min(visits),
         last = last(visits)) %>%
  mutate(decline = (last - best) / best) %>%
  ungroup() %>%
  mutate(decile = ntile(decline, 9))

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

spark <- function(df){
  
  sparkline <- 
    ggplot(data = df, 
           aes(x = week, y = visits)) +
    geom_line(colour = rev(pal[1:9])[df$decile[1]], size = 10) +
    geom_vline(xintercept = shutdown$start, size = 5, linetype = 2) +
    geom_vline(xintercept = shutdown$end, size = 5, linetype = 2) +
    theme_void()
    
  return(sparkline)
  
}  

##

plots <- 
  test %>%
  group_by(neighborhood) %>%
  nest() %>%
  mutate(plot = map(data, spark)) %>%
  select(-data)

top10 <- 
  test %>%
  select(neighborhood, visits) %>%
  group_by(neighborhood) %>%
  mutate(highest = max(visits),
         lowest = min(visits),
         recent = last(visits)) %>%
  select(-visits) %>%
  mutate_if(is.numeric, round) %>%
  mutate(change = (recent - highest) / highest) %>%
  slice(1) %>%
  ungroup() %>%
  left_join(plots) %>%
  arrange(desc(change)) %>%
  drop_na(neighborhood) %>%
  slice(1:20)

top10_plots <- select(top10, neighborhood, plot)
top10 <- select(top10, neighborhood, highest, lowest, recent, change)
 
bot10 <- 
  test %>%
  select(neighborhood, visits) %>%
  group_by(neighborhood) %>%
  mutate(highest = max(visits),
         lowest = min(visits),
         recent = last(visits)) %>%
  select(-visits) %>%
  mutate_if(is.numeric, round) %>%
  mutate(change = (recent - highest) / highest) %>%
  slice(1) %>%
  ungroup() %>%
  left_join(plots) %>%
  arrange(change) %>%
  slice(1:20)

bot10_plots <- select(bot10, neighborhood, plot)
bot10 <- select(bot10, neighborhood, highest, lowest, recent, change)

##

library(gt)

##

pal <- read_csv("https://raw.githubusercontent.com/asrenninger/palettes/master/grered.txt", col_names = FALSE) %>% pull(X1)

##

bot10 %>% 
  mutate(ggplot = NA) %>% 
  gt() %>% 
  tab_header(title = html("<b>Average Daily Visitors by Week</b>"),
             subtitle = md("Highest, lowest, and most recent footfall in Philadelphia<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Change is the percent fall from highest to most recent"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`neighborhood`))) %>% 
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
  mutate(ggplot = NA) %>% 
  gt() %>% 
  tab_header(title = html("<b>Average Daily Visitors by Week</b>"),
             subtitle = md("Highest, lowest, and most recent footfall in Philadelphia<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Change is the percent fall from highest to most recent")) %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`neighborhood`))) %>% 
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
  phila %>%
  st_join(grid) %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            id = id) %>% 
  st_drop_geometry()

##

joint <- 
  moves %>%
  mutate(month = lubridate::month(date_range_start, label = TRUE)) %>%
  group_by(safegraph_place_id, month) %>%
  summarise(visits = sum(raw_visit_counts)) %>%
  left_join(cross) %>%
  left_join(grid) %>%
  st_as_sf()

##

ggplot(joint) +
  geom_sf(data = dizz, 
          aes(), fill = NA, colour = '#000000', lwd = 1) +
  geom_sf(aes(fill = factor(ntile(visits, 9))), colour = NA, lwd = 0) +
  scale_fill_manual(values = pal,
                    labels = as.character(quantile(joint$visits,
                                                           c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9),
                                                           na.rm = TRUE)),
                    name = "visits",
                    guide = guide_discrete) +
  facet_wrap(~ month, nrow = 2) +
  labs(title = 'Time-Space Patterns', subtitle = "Movement aggregated to 500 meter squared cells") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("grid.png", height = 12, width = 14, dpi = 300)

##

moves <- read_csv("data/processed/moves_monthly.csv")

##

library(future)
library(furrr)
library(glue)

future::plan(multiprocess)

##

map(6:8, 
    function(x) {
      moves %>% 
        filter(month(date_range_start) == x) %>%
        select(safegraph_place_id, visitor_home_cbgs) %>%
        mutate(visitor_home_cbgs = future_map(visitor_home_cbgs, function(x){
          jsonlite::fromJSON(x) %>% 
            as_tibble()
        })) %>% 
        unnest(visitor_home_cbgs) %>%
        pivot_longer(!safegraph_place_id, names_to = "cbg", values_to = "visits") %>%
        drop_na(visits) %>%
        write_csv(glue("od_monthly_0{x}.csv"))
    })

##

files <- dir_ls("data/processed/od")

map_df(1:8, function(x){
  vroom(files[x], col_types = cols(
    safegraph_place_id = col_character(),
    cbg = col_character(),
    visits = col_double())) %>%
    mutate(month = x,
           start = glue("2020-0{x}-01"))
}) %>%
  write_csv("od_monthly.csv")

##

odmat <- vroom("data/processed/od_monthly.csv")

change <- 
  left_join(odmat %>%
              filter(cbg %in% shape$GEOID) %>%
              filter(month == 1) %>%
              left_join(phila) %>%
              mutate(location_name = case_when(str_detect(location_name, "Lincoln Technical Institute") ~ "University of Pennsylvania",
                                               TRUE ~ location_name)) %>%
              group_by(location_name) %>%
              summarise(january = n()) %>%
              select(location_name, january),
            odmat %>%
              filter(cbg %in% shape$GEOID) %>%
              filter(month == 8) %>%
              left_join(phila) %>%
              mutate(location_name = case_when(str_detect(location_name, "Lincoln Technical Institute") ~ "University of Pennsylvania",
                                               TRUE ~ location_name)) %>%
              group_by(location_name) %>%
              summarise(august = n()) %>%
              select(location_name, august)) %>%
  drop_na(august) %>%
  filter(january > 1000) %>%
  mutate(change = (august - january) / january)

change <-
  bind_rows(change %>%
              arrange(desc(change)) %>%
              slice(1:10) %>%
              mutate(rank = "best"),
            change %>%
              arrange(change) %>%
              slice(1:10) %>%
              mutate(rank = "worst")) %>%
  select(-august, -january) %>%
  rename(`change (january-august)` = change)

gt(data = change, rowname_col = "location_name", groupname_col = "rank") %>%
  tab_header(title = html("<b>Points of Interest: best and worst</b>"),
             subtitle = md("Number of unique visitor origin neighborhoods<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: This is a count of unique desire lines, not total visitors"))  %>% 
  data_color(
    columns = vars(`change (january-august)`),
    colors = scales::col_numeric(
      palette = pal,
      domain = NULL
    )) %>%
  tab_options(heading.title.font.size = 30,
              heading.subtitle.font.size = 15,
              heading.align = "left",
              table.border.top.color = "white",
              heading.border.bottom.color = "white",
              table.border.bottom.color = "white",
              column_labels.border.bottom.color = "grey",
              column_labels.border.bottom.width= px(1)) %>% 
  gtsave("connections.png", expand = 10)

##

parks <- c("Rittenhouse Square", "Logan Square", "Franklin Square", "Washington Square")

parks <- 
  phila %>% 
  filter(location_name %in% parks) 

datum <- 
  odmat %>%
  mutate(month = lubridate::month(start, label = TRUE)) %>% 
  filter(safegraph_place_id %in% parks$safegraph_place_id) %>% 
  left_join(parks) %>% 
  select(location_name, safegraph_place_id, cbg, visits, month) %>%
  rename(GEOID = cbg) %>% 
  left_join(shape) %>%
  drop_na(ALAND, AWATER) %>% 
  st_as_sf()

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_sf(data = datum, aes(fill = visits), colour = NA, lwd = 0) +
  scale_fill_gradientn(colors = pal,
                       name = "visits",
                       guide = guide_continuous) +
  facet_wrap( ~ month, nrow = 1) +
  labs(title = 'Visitors to the Four Squares', subtitle = "Devices by neighborhood of origin") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("parks.png", height = 4, width = 14, dpi = 300)

##

comcast <- 
  phila %>% 
  filter(str_detect(location_name, "Comcast") & !str_detect(location_name, "XFINITY")) %>%
  rename(geocode1 = GEOID)

datum <- 
  odmat %>%
  mutate(month = lubridate::month(start, label = TRUE)) %>% 
  filter(safegraph_place_id %in% comcast$safegraph_place_id) %>% 
  left_join(comcast) %>% 
  select(location_name, safegraph_place_id, cbg, visits, month, geocode1) %>%
  rename(GEOID = cbg) %>% 
  left_join(shape) %>%
  drop_na(ALAND, AWATER) %>% 
  st_as_sf()

datum <- 
  datum %>% 
  transmute(geocode1 = geocode1,
            geocode2 = GEOID,
            visits = visits,
            month = month) %>%
  st_drop_geometry()

glimpse(datum)
glimpse(shape)

lines <- stplanr::od2line(flow = datum, zones = transmute(shape, geocode = GEOID))

##

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_sf(data = lines, aes(colour = visits, lwd = visits)) +
  scale_colour_gradientn(colors = rev(pal),
                       name = "visits",
                       guide = guide_continuous) +
  scale_size_continuous(range = c(0.1, 1), guide = 'none') +
  facet_wrap(~ month, nrow = 1) +
  labs(title = 'Visitors to the Comcast Center', subtitle = "Devices by neighborhood of origin") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("comcast.png", height = 4, width = 14, dpi = 300)

##

reading <- 
  phila %>% 
  filter(str_detect(location_name, "Iovine|Field House|Hard Rock Cafe")) %>%
  rename(geocode1 = GEOID)

datum <- 
  odmat %>%
  mutate(month = month(start, label = TRUE)) %>% 
  filter(safegraph_place_id %in% reading$safegraph_place_id) %>% 
  left_join(reading) %>% 
  select(location_name, safegraph_place_id, cbg, visits, month, geocode1) %>%
  rename(GEOID = cbg) %>% 
  left_join(shape) %>%
  drop_na(ALAND, AWATER) %>% 
  st_as_sf()

datum <- 
  datum %>% 
  transmute(geocode1 = geocode1,
            geocode2 = GEOID,
            visits = visits,
            month = month) %>%
  st_drop_geometry()

glimpse(datum)
glimpse(shape)

lines <- stplanr::od2line(flow = datum, zones = transmute(shape, geocode = GEOID))

##

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_sf(data = lines, aes(colour = visits, lwd = visits)) +
  scale_colour_gradientn(colors = rev(pal),
                         name = "visits",
                         guide = guide_continuous) +
  scale_size_continuous(range = c(0.1, 1), guide = 'none') +
  facet_wrap(~ month, nrow = 1) +
  labs(title = 'Visitors to Reading Terminal', subtitle = "Devices by neighborhood of origin") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("market.png", height = 4, width = 14, dpi = 300)

##

datum <- 
  moves %>%
  group_by(safegraph_place_id) %>%
  summarise(visits = sum(raw_visitor_counts)) %>%
  left_join(phila) %>%
  mutate(type = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                           str_detect(top_category, "Schools|Child") ~ "school",
                           str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                           str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                           str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                           str_detect(top_category, "Real estate") ~ "real Estate",
                           str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                           str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                           str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                           str_detect(top_category, "Religious") ~ "worship",
                           TRUE ~ "other")) %>%
  select(location_name, type, latitude, longitude, visits) %>%
  st_as_sf(coords = c("longitude", "latitude"), remove = FALSE, crs = 4326) %>%
  st_transform(3702)

##

datum <-
  datum %>%
  st_coordinates() %>%
  as_tibble() %>%
  bind_cols(datum) %>% 
  select(-geometry)

##

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_point(data = datum, aes(x = X, y = Y, size = visits), colour = '#000000', alpha = 0.5) +
  scale_size_continuous(range = c(0, 6)) +
  labs(title = "Points of Interest", subtitle = "Venues by visitation") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("context.png", height = 6, width = 4, dpi = 300)

##

datum <-
  phila %>%
  st_coordinates() %>%
  as_tibble() %>%
  bind_cols(phila) %>% 
  mutate(type = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                          str_detect(top_category, "Schools|Child") ~ "school",
                          str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                          str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                          str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                          str_detect(top_category, "Real estate") ~ "real Estate",
                          str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                          str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                          str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                          str_detect(top_category, "Religious") ~ "worship",
                          TRUE ~ "other")) %>%
  select(-geometry) 

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_hex(data = datum %>%
             filter(type != "other" & type != "automotive"), aes(x = X, y = Y), alpha = 0.5) +
  scale_fill_gradientn(colours = rev(pal),
                       guide = guide_continuous, 
                       limits = c(0, 50),
                       breaks = c(0, 10, 20, 30, 40, 50),
                       labels = c("0", "10", "20", "30", "40", "50+"),
                       oob = squish) +
  scale_size_continuous(range = c(0, 6), guide = 'none') +
  facet_wrap(~ type, nrow = 2) + 
  labs(title = "Points of Interest", subtitle = "Venues density use category") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("split.png", height = 6, width = 8, dpi = 300)

##

cross <- 
  phila %>%
  st_drop_geometry() %>%
  transmute(
    safegraph_place_id = safegraph_place_id,
    type = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                     str_detect(top_category, "Schools|Child") ~ "school",
                     str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                     str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                     str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                     str_detect(top_category, "Real Estate") ~ "real estate",
                     str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                     str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                     str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                     str_detect(top_category, "Religious") ~ "worship",
                     TRUE ~ "other"))

## 

odmat <- vroom("data/processed/od_monthly.csv")

##

moves %>%
  mutate(month = lubridate::month(date_range_start, label = TRUE)) %>%
  select(safegraph_place_id, raw_visit_counts, month) %>%
  left_join(phila) %>%
  mutate(type = case_when(str_detect(top_category, "Restaurants|Drinking") ~ "leisure",
                          str_detect(top_category, "Schools|Child") ~ "school",
                          str_detect(top_category, "Stores") & str_detect(top_category, "Food|Grocery|Liquor") ~ "grocery",
                          str_detect(top_category, "Stores|Dealers") & !str_detect(top_category, "Food|Grocery|Liquor") ~ "shopping",
                          str_detect(top_category, "Gasoline Stations|Automotive") ~ "automotive",
                          str_detect(top_category, "Real estate") ~ "real Estate",
                          str_detect(top_category, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                          str_detect(top_category, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(top_category, "Real Estate") ~ "healthcare",
                          str_detect(top_category, "Care") & str_detect(top_category, "Personal") ~ "pharmacy",
                          str_detect(top_category, "Religious") ~ "worship",
                          TRUE ~ "other")) %>%
  group_by(type, month) %>%
  summarise(visits = sum(raw_visit_counts)) %>%
  ggplot(aes(x = month, y = visits, colour = type)) +
  geom_path(aes(group = type), size = 1) +
  scale_colour_manual(values = c(pal, '#000000'),
                      name = "type of venue") +
  labs(title = "Tracking Activity", subtitle = "Venues by category") +
  xlab("") +
  theme_hor() +
  ggsave("seriesxtype.png", height = 4, width = 8, dpi = 300)

##

library(prophet)

##

ready <- 
  fixed %>% 
  mutate(mon = month(date_range_start),
         date = as_date(glue("2020-{mon}-{day}"))) %>%
  select(safegraph_place_id, date, visits) %>%
  mutate(visits = as.numeric(visits)) %>%
  left_join(cross) %>%
  filter(type == "leisure") %>%
  group_by(date) %>%
  summarise(visits = sum(visits)) %>%
  rename(ds = date, y = visits)

##

proph_1 <- prophet(ready, weekly.seasonality = TRUE, changepoint.prior.scale = 0.9, n.changepoints = 4)
proph_1$changepoints <- proph_1$changepoints[abs(proph_1$params$delta) >= quantile(proph_1$params$delta,
                                                                                   #c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
                                                                                   )[3]]

##

blank_1 <- make_future_dataframe(proph_1, periods = 365 - nrow(ready))  
preds_1 <- predict(proph_1, blank)

##

n <- 
  ggplot() +
  geom_point(aes(x = proph_1$history$ds, y = proph_1$history$y),
             colour = pal[4], size = 0.5) +
  geom_line(data = preds_1, 
            aes(x = ds, y = yhat), colour = pal[2], size = 0.5, alpha = 0.25) +
  geom_line(data = preds_1, 
            aes(x = ds, y = trend), colour = pal[2], size = 1) +
  geom_vline(xintercept = proph_1$changepoints, linetype = 2, size = 0.5, colour = pal[11]) +
  geom_text(aes(x = proph_1$changepoints - 24 * 60 * 60, y = 61000, label = glue("{month(proph_1$changepoints, label = TRUE)} {day(proph_1$changepoints)}")), 
            hjust = 1, colour = pal[11], fontface = 'bold', size = 2) +
  #scale_y_continuous(limits = c(0, 62000), breaks = c(20000, 40000, 60000)) +
  labs(subtitle = "Night life") + 
  xlab("") +
  ylab("visits") +
  theme_hor() +
  theme(axis.text.x = element_blank())

ready <- 
  fixed %>% 
  mutate(mon = month(date_range_start),
         date = as_date(glue("2020-{mon}-{day}"))) %>%
  select(safegraph_place_id, date, visits) %>%
  mutate(visits = as.numeric(visits)) %>%
  left_join(cross) %>%
  filter(type == "grocery") %>%
  group_by(date) %>%
  summarise(visits = sum(visits)) %>%
  rename(ds = date, y = visits)

##

proph_2 <- prophet(ready, weekly.seasonality = TRUE)
proph_2$changepoints <- proph_2$changepoints[abs(proph_1$params$delta) >= quantile(proph_2$params$delta,
                                                                                   #c(0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9)
                                                                                   )[5]]
##

blank_2 <- make_future_dataframe(proph_2, periods = 365 - nrow(ready))  
preds_2 <- predict(proph_2, blank)

##

g <- 
  ggplot() +
  geom_point(aes(x = proph_2$history$ds, y = proph_2$history$y),
             colour = pal[4], size = 0.5) +
  geom_line(data = preds_2, 
            aes(x = ds, y = yhat), colour = pal[2], size = 0.5, alpha = 0.25) +
  geom_line(data = preds_2, 
            aes(x = ds, y = trend), colour = pal[2], size = 1) +
  geom_vline(xintercept = proph_2$changepoints, linetype = 2, size = 0.5, colour = pal[11]) +
  geom_text(aes(x = proph_2$changepoints - 24 * 60 * 60, y = 20300, label = glue("{month(proph_2$changepoints, label = TRUE)} {day(proph_2$changepoints)}")), 
            hjust = 1, colour = pal[11], fontface = 'bold', size = 2, check_overlap = TRUE) +
  #scale_y_continuous(limits = c(0, 62000), breaks = c(20000, 40000, 60000)) +
  labs(subtitle = "Grocers") +
  xlab("") +
  ylab("visits") +
  theme_hor()

##

library(patchwork)

##

p <- n / g 
p + plot_annotation(title = 'Assessing Changepoints in the Data',
                    theme = theme(plot.title = element_text(face = 'bold', colour = 'black', hjust = 0.5))) + ggsave("changepoints.png", height = 8, width = 8, dpi = 300)

## 

cross <- 
  phila %>%
  st_join(grid) %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            id = id) %>% 
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
         y = visits) 

##

nested <-
  joint %>% 
  group_by(neighborhood) %>% 
  nest() %>%
  ungroup()

points <- function(df) {
  
  proph <- prophet(df, weekly.seasonality = TRUE)
  proph$changepoints[abs(proph$params$delta) >= 0.01]
  
}

modelled <- 
  nested %>% 
  mutate(points = map(data, points))

modelled %>% 
  filter(neighborhood != "NA") %>%
  unnest(cols = points) %>% 
  ggplot() +
  geom_point(aes(x = reorder(neighborhood, as_date(points)), as_date(points)),
             colour = pal[2]) +
  xlab("") +
  ylab("") +
  coord_flip() +
  labs(title = "Change Points Across Philadelphia", subtitle = "Testing different neighborhoods") +
  theme_rot() +
  theme(axis.text = element_text(size = 5)) +
  ggsave("changexhoods.png", height = 12, width = 6, dpi = 300)



