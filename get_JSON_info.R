
library(tidyverse)
library(rvest)
library(xml2)
library(jsonlite)

l <- "https://www.eventbrite.es/d/united-kingdom--london/events--today/?page=1"

# pull the JSON part 

json_script <- l |> read_html() |> 
  xml_find_all("//script[@type='application/ld+json']") |> pluck(2) |> xml_text()

json <- jsonlite::fromJSON(json_script)

url <- json$url 

# individual pull 
json_1 <- url |> read_html() |> 
  xml_find_all("//script[@type='application/ld+json']") |> pluck(1) |> xml_text() 

json_1 <- jsonlite::fromJSON(json_1)

json_1$offers$priceCurrency[1]
json_1$offers$lowPrice[1]
json_1$offers$highPrice[1]
json_1$organizer$description
json_1$name
json_1$description
json_1$organizer$name
json_1$url



