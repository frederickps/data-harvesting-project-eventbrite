# here are the functions for pulling data: 

library(tidyverse)
library(rvest)
library(xml2)


load_cities_list <- function() {
  
  cities_list <- tribble(~input, ~text,
                         "madrid", "spain--madrid",
                         "roma", "italy--roma",
                         "london", "united-kingdom--london",
                         "lyon", "france--lyon",
                         "paris", "france--paris",
                         "barcelona", "spain--barcelona",
                         "torino", "italy--torino",
                         "sevilla", "spain--sevilla",
                         "cadiz", "spain--cádiz",
  )
}

create_url <- function(city) {
  
  url_city <- cities_list$text[cities_list$input == city]
  
  url_root <- "https://www.eventbrite.es/d/"
  url_suffix <- "/events--today/"
  
  url <- paste0(url_root, url_city, url_suffix)
  
  return(url)
}

get_event_titles <- function(link, page_num) {
  
  link_with_page_num <- paste0(link, "?page=", page_num) # adds page number info to url 

  html_link <- link_with_page_num |> 
    read_html() |> 
    xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//h2") |> 
    xml_text()
  
  # remove the repeating titles 
  titles <- html_link[seq(from=1, to=40, by=2)]
  
  return(titles)
}

count_pages <- function(link){
  
  total_pages <- link |> 
    read_html() |> 
    xml_find_all("//li[@class='eds-pagination__navigation-minimal eds-l-mar-hor-3']") |> 
    xml_text() |> 
    str_extract_all("\\d+$") |> 
    pluck(1)
  
  total_pages <- as.numeric(total_pages)
  return(total_pages) # returns the number of available pages as an integer
}

get_all_titles <- function(link) {
  
  all_titles <- c() # creates empty vector
  
  pages_count <- count_pages(link = link) # gets number of available pages at this link 
  
  pages_count <- min(10, pages_count) # don't pull more than 10 pages at once
  
  for (i in 1:pages_count) {
    
    Sys.sleep(5)
    # loops through number of pages 
    # gets a new batch of titles from page i 
    titles <- get_event_titles(link = link, page_num = i)
    
    # adds it to the full vector of titles 
    all_titles <- c(all_titles, titles) 
  }
  
  # returns only titles that are not NA 
  return(all_titles[!is.na(all_titles)]) 
  
}

## examples -> 

l <- "https://www.eventbrite.es/d/united-kingdom--london/events--today/"
count_pages(l)
get_all_titles(link = l)

load_cities_list()
l <- create_url(city = "sevilla")
get_all_titles(l)


#

html_link <- link_with_page_num |> 
  read_html()

titles <-
  "https://www.eventbrite.es/d/united-kingdom--london/events--today/" |> 
  read_html() |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//h2") |> 
  xml_text()

event_info <-
  "https://www.eventbrite.es/d/united-kingdom--london/events--today/" |> 
  read_html() |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//p") |> 
  xml_text()

event_info

link_event_page <-
  "https://www.eventbrite.es/d/united-kingdom--london/events--today/" |> 
  read_html() |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//a") |> 
  xml_attr("href")

link_event_page[seq(from=1, to=40, by=2)]
  

"https://www.eventbrite.es/d/united-kingdom--london/events--today/" |> 
  read_html() |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']/div[@class='discover-horizontal-event-card__price-wrapper']/p") |> 
  xml_text()



