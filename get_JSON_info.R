
library(tidyverse)
library(rvest)
library(xml2)
library(jsonlite)

l <- "https://www.eventbrite.es/d/united-kingdom--london/events--today/"

# pull the JSON part 

json_script <- l |> read_html() |> 
  xml_find_all("//script[@type='application/ld+json']") |> pluck(1) |> xml_text()

jsonlite::fromJSON(json_script)





