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
  test %>%
  group_by(neighborhood) %>%
  nest() %>%
  mutate(plot = map(data, spark)) %>%
  select(-data)

top10 <- 
  test %>%
  select(neighborhood, visits) %>%
  group_by(neighborhood) %>%
  mutate(best = max(visits),
         worst = min(visits),
         last = last(visits)) %>%
  select(-visits) %>%
  mutate_if(is.numeric, round) %>%
  mutate(change = (last - best) / best) %>%
  slice(1) %>%
  ungroup() %>%
  left_join(plots) %>%
  arrange(desc(change)) %>%
  drop_na(neighborhood) %>%
  slice(1:20)

top10_plots <- select(top10, neighborhood, plot)
top10 <- select(top10, neighborhood, best, worst, last, change)
 
bot10 <- 
  test %>%
  select(neighborhood, visits) %>%
  group_by(neighborhood) %>%
  mutate(best = max(visits),
         worst = min(visits),
         last = last(visits)) %>%
  select(-visits) %>%
  mutate_if(is.numeric, round) %>%
  mutate(change = (last - best) / best) %>%
  slice(1) %>%
  ungroup() %>%
  left_join(plots) %>%
  arrange(change) %>%
  slice(1:20)

bot10_plots <- select(bot10, neighborhood, plot)
bot10 <- select(bot10, neighborhood, best, worst, last, change)

##

library(gt)

##

bot10 %>% 
  mutate(ggplot = NA) %>% 
  gt() %>% 
  tab_header(title = html("<b>Neighborhood Visitors: bottom twenty</b>"),
             subtitle = md("Change in footfall in select neighborhoods in Philadelphia<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Decline is the percent fall from best to last"))  %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`neighborhood`))) %>% 
  data_color(columns = vars(`change`),
             colors = scales::col_numeric(c(rev(pal[2:10])), domain = NULL)) %>% 
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
  tab_header(title = html("<b>Neighborhood Visitors: top twenty</b>"),
             subtitle = md("Change in footfall in select neighborhoods in Philadelphia<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: Decline is the percent fall from best to last")) %>% 
  tab_style(style = list(cell_text(weight = "bold")),
            locations = cells_column_labels(vars(`neighborhood`))) %>% 
  data_color(columns = vars(`change`),
             colors = scales::col_numeric(c(rev(pal[2:10])), domain = NULL)) %>% 
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

dizz <- 
  grid %>% 
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
  mutate(month = month(date_range_start, label = TRUE)) %>%
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
  scale_fill_manual(values = pal[2:10],
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
  bind_rows(
    odmat %>%
      filter(cbg %in% shape$GEOID) %>%
      filter(month == 1) %>%
      group_by(safegraph_place_id) %>%
      summarise(connections = n()) %>%
      left_join(phila) %>%
      select(location_name, connections) %>%
      arrange(desc(connections)) %>%
      slice(1:10) %>%
      mutate(period = "before (January)"),
    odmat %>%
      filter(cbg %in% shape$GEOID) %>%
      filter(month == 8) %>%
      group_by(safegraph_place_id) %>%
      summarise(connections = n()) %>%
      left_join(phila) %>%
      select(location_name, connections) %>%
      arrange(desc(connections)) %>%
      slice(1:10) %>%
      mutate(period = "after (August)"))

gt(data = change, rowname_col = "location_name", groupname_col = "period") %>%
  tab_header(title = html("<b>Points of Interest: best and worst</b>"),
             subtitle = md("Change in unique visitor origin neighborhoods<br><br>")) %>%
  tab_source_note(source_note = md("**Data**: SafeGraph | **Note**: This is a count of unique desire lines, not total visitors"))  %>% 
  data_color(
    columns = vars(`connections`),
    colors = scales::col_numeric(
      palette = rev(pal)[2:10],
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
  mutate(month = month(start, label = TRUE)) %>% 
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
  scale_fill_gradientn(colors = pal[2:10],
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
  filter(str_detect(location_name, "Comcast") & !str_detect(location_name, "XFINITY")) 

datum <- 
  odmat %>%
  mutate(month = month(start, label = TRUE)) %>% 
  filter(safegraph_place_id %in% comcast$safegraph_place_id) %>% 
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
  scale_fill_gradientn(colors = pal[2:10],
                       name = "visits",
                       guide = guide_continuous) +
  facet_wrap(~ month, nrow = 1) +
  labs(title = 'Visitors to the Comcast Center', subtitle = "Devices by neighborhood of origin") +
  theme_map() +
  theme(legend.position = 'bottom') +
  ggsave("comcast.png", height = 4, width = 14, dpi = 300)

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
  st_transform(3702) %>%
  st_coordinates()

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

ggplot() +
  geom_sf(data = background, 
          aes(), fill = NA, colour = '#000000', lwd = 0.5) +
  geom_point(data = datum %>%
               filter(type != "other" & type != "automotive"), aes(x = X, y = Y, colour = type, size = visits), alpha = 0.5) +
  scale_color_manual(values = sample(pal),
                    guide = 'none') +
  scale_size_continuous(range = c(0, 6), guide = 'none') +
  facet_wrap(~ type, nrow = 2) + 
  labs(title = "Points of Interest", subtitle = "Venues by use category") +
  theme_map() +
  theme(legend.position = 'bottom',
        legend.text = element_text(angle = 45)) +
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

proph <- prophet(ready, weekly.seasonality = TRUE, changepoint.prior.scale = 0.9, n.changepoints = 4)

blank <- make_future_dataframe(proph, periods = 365 - nrow(ready))  
preds <- predict(proph, blank)

ggplot() +
  geom_line(data = preds,
            aes(as_date(ds), yhat),  colour = pal[2], size = 1, alpha = 0.25) +
  geom_line(data = preds,
            aes(as_date(ds), trend), colour = pal[2], size = 2) +
  geom_point(data = ready, 
             aes(ds, y), colour = pal[4]) +
  geom_vline(xintercept = as_date(proph$changepoints), linetype = 2, colour = pal[11], size = 1) +
  labs(title = "Change Point Detection: leisure activities",
       subtitle = "Fitting a Bayesian model to the data",
       x = "", y = "visits") +
  theme_hor() +
  ggsave("changepoints.png", height = 6, width = 10, dpi = 300)

##

library(rayshader)
library(rayrender)
library(scales)

##

joint %>%
  filter(month == "Jul") %>%
  raster::rasterize()
  
  

##

