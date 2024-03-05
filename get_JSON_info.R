
library(tidyverse)
library(rvest)
library(xml2)
library(jsonlite)

l <- "https://www.eventbrite.es/d/united-kingdom--london/events--today/?page=1"

# pull the JSON part 

json_script <- l |> read_html() |> 
  xml_find_all("//script[@type='application/ld+json']") |> pluck(1) |> xml_text()

json <- jsonlite::fromJSON(json_script)

url <- json$url 

json_1 <- url |> read_html() |> 
  xml_find_all("//script[@type='application/ld+json']") |> pluck(1) |> xml_text() 

json_1 <- jsonlite::fromJSON(json_1)

json_1$offers$priceCurrency[1]
json_1$offers$lowPrice[1]
json_1$offers$highPrice[1]
json_1$startDate
json_1$endDate

json_1$organizer$name
json_1$offers

json_1$eventStatus |> 
  str_extract_all(".org/.+$") |> 
  str_split(pattern = "/") |> 
  pluck(1) |> 
  pluck(2)


