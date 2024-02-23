# Data mining from Eventbrite

# libraries ----
library(httr2)
library(tidyverse)
library(rvest)
library(xml2)
library(dotenv)

## user agent----

 ## user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15")

# webscraping ----

link0 <- "https://www.eventbrite.es/d/spain--madrid/events--today/"
link1 <- "https://www.eventbrite.es/d/spain--madrid/events--today/?page=1"
link2 <- "https://www.eventbrite.es/d/spain--madrid/events--today/?page=2"

html_link0 <- link0 |> read_html()
html_link1 <- link1 |> read_html()
html_link2 <- link2 |> read_html()

## direct xpath copy&paste ----
direct <- "/html/body/div[2]/div/div[2]/div/div/div/div[1]/div/main/div/div[1]/section[1]/div/section/div/div/section/ul/li[1]/div/div[2]/section/div/section[2]/div/a"

event_direct <-  html_link2 %>%
  xml_find_all(direct)

event_direct |> 
  xml_text()

direct2 <- "/html/body/div[2]/div/div[2]/div/div/div/div[1]/div/main/div/div[1]/section[1]/div/section/div/div/section/ul/li[1]/div/div[2]/section/div/section[2]/div/p[1]"

event_direct2 <-  html_link %>%
  xml_find_all(direct2)

event_time <- event_direct2 |> 
  xml_text() |> 
  str_extract_all("\\d.+$") |> 
  purrr::pluck(1)
event_time

lubridate::as_datetime("7:00 PM", tz = "Europe/Madrid",
                       format = "%I:%M %p")

## more general method ----

y <- html_link2 |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//h2") |> 
  xml_text()

z = seq(1,40,by=2)
y[z]


todays_event_times <- html_link2 |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']")

todays_event_times |> 
  xml_text()

# function for getting titles: ----

get_event_titles <- function(link, page_num) {
  
  link_with_page_num <- paste0(link, "?page=", page_num)
  
  html_link <- link_with_page_num |> read_html()
  
  html_link <- html_link |> 
    xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//h2") |> 
    xml_text()
  
  return(html_link[seq(from=1, to=40, by=2)])
}

## test it out

good <- get_event_titles(link0, page_num = 4) # no NA's
ok <-  get_event_titles(link0, page_num = 5) # a couple NA's
notgood <- get_event_titles(link0, page_num = 6) # all NA's 

## function to check for if the page exists ----

which(is.na(notgood))
which(!is.na(ok)) 

total_pages <- html_link0 |> 
  xml_find_all("//li[@class='eds-pagination__navigation-minimal eds-l-mar-hor-3']") |> 
  xml_text() |> 
  str_extract_all("\\d+$") |> 
  pluck(1)

total_pages <- as.numeric(total_pages)
total_pages

check_pages <- function(link){
  
  html_link <- link |> read_html()
  
  total_pages <- html_link |> 
    xml_find_all("//li[@class='eds-pagination__navigation-minimal eds-l-mar-hor-3']") |> 
    xml_text() |> 
    str_extract_all("\\d+$") |> 
    pluck(1)
  
  total_pages <- as.numeric(total_pages)
  return(total_pages)
  
}

check_pages(link0)

#' here's the idea. using the function above `get_event_titles`,
#' get the titles until an `NA` is detected. then stop scraping pages. 
#' if `page=1` has an NA, don't scrape `page=2`
#' 
#' next step, build this and an argument for the city/location: 
#'  - madrid
#'  - barcelona 
#'  - paris
#'  - amsterdam 
#'  - berlin
#'  - sevilla 
#'  - ... 

get_all_titles <- function(link) {
  
  all_titles <- c()
  num_pages <- check_pages(link = link)
  
  for (i in 1:num_pages) {
    
    all_titles <- c(all_titles, get_event_titles(link = link, page_num = i)) 
  }

  
  return(all_titles[!is.na(all_titles)])
    
}

get_all_titles(link0)



