########################################
## Explorations
########################################

source("R/package.R")
source("help.R")

##

library(fs)

##

files <- dir_ls("data/patterns_2020/07/Core-USA-July2020-Release-CORE_POI-2020_06-2020-07-13/")
files <- files[3:7]

##

poi <- map_df(files, vroom)

##

poi <- lazy_dt(poi)
poi <- poi %>% 
  filter(city == "Philadelphia" & region == "PA") %>%
  as_tibble()

##
