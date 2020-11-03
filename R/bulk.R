########################################
## Bulk wrangling
########################################

library(tidyverse)
library(vroom)
library(fs)
library(glue)

##

files <- dir_ls("data/places_2020/09/Core-USA-Sep-CORE_POI-2020_08-2020-09-08")
files <- files[3:7]

##

map_df(files, vroom) %>% 
  glimpse() %>% 
  write_csv("places_complete.csv")

##

nums <- str_pad(paste(1:9), width = 2, pad = "0", side = 'left')
mons <- c("jan", "fed", "mar", "apr", "may", "jun", "july", "aug", "sep", "oct", "nov", "dec")

##

map(nums[7:9], function(x){
  trail <- glue("data/patterns_2020_monthly/2020/{x}")
  files <- dir_ls(trail, recurse = TRUE, type = 'file')
  files <- files[!str_detect(files, "_SUCCESS")]
  
  print(files)
  
  map_df(files, vroom) %>% 
    write_csv(glue("2020_{x}.csv"))
  
})
