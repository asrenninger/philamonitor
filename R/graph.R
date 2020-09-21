########################################
## Graphing
########################################

source("R/package.R")
source("R/help.R")

new <- 
  flo %>% 
  select(safegraph_place_id, visitor_home_cbgs) %>%
  mutate(visitor_home_cbgs = map(visitor_home_cbgs, function(x){
    jsonlite::fromJSON(x) %>% 
      as_tibble()
  })) %>% 
  unnest(visitor_home_cbgs) %>%
  pivot_longer(!safegraph_place_id, names_to = "cbg", values_to = "visits") %>%
  drop_na(visits)

##

write_csv(new, "odm.csv")
st_write(phl, "phl.geojson")

##

new <- read_csv("data/processed/odm.csv")
phl <- read_sf("data/processed/phl.geojson")

sgl <- 
  phl %>% 
  transmute(safegraph_place_id = safegraph_place_id,
            locale = location_name, type = top_category, naics = str_sub(naics_code, 1, 2)) %>% 
  st_drop_geometry()

mat <- 
  new %>% left_join(sgl) %>%
  drop_na(naics)

rel <- transmute(mat,from = cbg, to = safegraph_place_id, weight = visits)

col <- 
  mat %>%
  mutate(class = case_when(str_detect(type, "Restaurants|Drinking") ~ "leisure",
                           str_detect(type, "Schools|Child") ~ "school",
                           str_detect(type, "Stores") & str_detect(type, "Food|Grocery|Liquor") ~ "grocery",
                           str_detect(type, "Stores|Dealers") & !str_detect(type, "Food|Grocery|Liquor") ~ "shopping",
                           str_detect(type, "Gasoline Stations|Automotive") ~ "automotive",
                           str_detect(type, "Real Estate") ~ "real Estate",
                           str_detect(type, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                           str_detect(type, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(type, "Real Estate") ~ "healthcare",
                           str_detect(type, "Care") & str_detect(type, "Personal") ~ "pharmacy",
                           str_detect(type, "Religious") ~ "worship",
                           TRUE ~ "other")) %>%
  group_by(class) %>% 
  summarise(n = sum(visits)) %>%
  arrange(desc(n)) %>% 
  mutate(cmap = sample(pal))

con <- 
  mat %>%
  mutate(class = case_when(str_detect(type, "Restaurants|Drinking") ~ "leisure",
                           str_detect(type, "Schools|Child") ~ "school",
                           str_detect(type, "Stores") & str_detect(type, "Food|Grocery|Liquor") ~ "grocery",
                           str_detect(type, "Stores|Dealers") & !str_detect(type, "Food|Grocery|Liquor") ~ "shopping",
                           str_detect(type, "Gasoline Stations|Automotive") ~ "automotive",
                           str_detect(type, "Real Estate") ~ "real Estate",
                           str_detect(type, "Museums|Amusement|Accommodation|Sports|Gambling") ~ "tourism", 
                           str_detect(type, "Offices|Outpatient|Nursing|Home Health|Diagnostic") & !str_detect(type, "Real Estate") ~ "healthcare",
                           str_detect(type, "Care") & str_detect(type, "Personal") ~ "pharmacy",
                           str_detect(type, "Religious") ~ "worship",
                           TRUE ~ "other")) %>%
  distinct(type, .keep_all = TRUE) %>%
  select(type, class)


nde <- 
  mat %>% 
  distinct(safegraph_place_id, .keep_all = TRUE) %>%
  select(-visits, -cbg) %>% 
  left_join(con) %>% 
  left_join(col)


graph <- graph_from_data_frame(rel, directed = TRUE)
V(graph)$type <- bipartite_mapping(graph)$type

comps <- components(graph, mode = "weak")

graph <-
  graph %>% 
  set_vertex_attr("venue", index = V(graph)[type=="TRUE"], value = nde$locale)  %>% 
  set_vertex_attr("description", index = V(graph)[type=="TRUE"], value = nde$class) %>%
  set_vertex_attr("naics", index = V(graph)[type=="TRUE"], value = nde$naics) %>%
  set_vertex_attr("cmap", index = V(graph)[type=="TRUE"], value = nde$cmap) %>%
  set_vertex_attr("venue", index = V(graph)[type=="FALSE"], value = "none")  %>% 
  set_vertex_attr("description", index = V(graph)[type=="FALSE"], value = "none") %>%
  set_vertex_attr("naics", index = V(graph)[type=="FALSE"], value = "none") %>%
  set_vertex_attr("cmap", index = V(graph)[type=="FALSE"], value = '#000000') %>%
  set_vertex_attr("comp", value = comps$membership)

#V(graph)[[type=="TRUE"]]

graph <- simplify(graph)

#graph <- delete_edges(graph, which(E(graph)$weight < 10))
#graph <- delete_vertices(graph, which(degree(graph) < 1))

#names(which(table(comps$membership) < 10))

#small <- names(which(table(comps$membership) < 10))
#small <- names(which(comps$membership == small))

#table(comps$membership)

decomp <- decompose(graph, mode = c("weak"),
                    min.vertices = 2)

lay <- layout_with_fr(decomp[[1]], weights = E(decomp[[1]])$weight)
lay <- norm_coords(lay, ymin = -1, ymax = 1, xmin = -1, xmax = 1)

png(width = 1800, height = 1800)

plot(
  main = "points of interests and neighborhood interactions",
  decomp[[1]],
  rescale = FALSE, 
  ylim = c(-1, 1), 
  xlim = c(-1, 1), 
  asp = 0,
  layout = lay * 1, 
  vertex.size = sqrt(degree(decomp[[1]])),
  vertex.label = NA,
  edge.arrow.size = 0,
  vertex.color = V(decomp[[1]])$cmap
)

dev.off()

lay <- layout_as_bipartite(decomp[[1]])
lay <- norm_coords(lay, ymin = -1, ymax = 1, xmin = -1, xmax = 1)

png(width = 1800, height = 1800)

plot(
  main = "points of interests and neighborhood interactions",
  decomp[[1]],
  rescale = FALSE, 
  ylim = c(-1, 1), 
  xlim= c(-1, 1), 
  layout = lay, 
  vertex.size = degree(decomp[[1]])/100 + 1,
  vertex.label = NA,
  edge.arrow.size = 0,
  edge.color = adjustcolor('#757575', 0.1),
  vertex.color = V(decomp[[1]])$cmap
)

dev.off()

##

library(ggraph)

##

net <- 
  ggraph(decomp[[1]], layout = lay) +
  geom_edge_link() + 
  geom_node_point(aes(colour = description, size = sqrt(degree(decomp[[1]])))) +
  coord_fixed() +
  scale_color_manual(values = col$cmap)

ggsave(net, filename = "graph.png", height = 20, width = 20, dpi = 300)

##

graph <-
  graph %>%
  set_vertex_attr("tween", value = betweenness(graph, V(graph))) %>%
  set_vertex_attr("close", value = closeness(graph, V(graph), mode = "all")) %>%
  set_vertex_attr("degri", value = degree(graph, V(graph), mode = "all"))

plot(
  graph,
  layout = lay, 
  vertex.size = degree(graph)/10 +1,
  vertex.label = NA,
  edge.arrow.size = 0,
  vertex.color = tween
)



