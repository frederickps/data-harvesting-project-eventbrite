# Data mining from Eventbrite

# libraries ----
library(httr2)
library(tidyverse)
library(rvest)
library(xml2)

## token key ----
token_key <- "TCQQTBU3YTHBD5S7YLT7"

url_example <- "https://www.eventbriteapi.com/v3/users/me/?token=TCQQTBU3YTHBD5S7YLT7"

## user agent----

set_config(
  user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15")
)

## api me ----

resp_me <- url_example %>% 
  request() %>% 
  req_perform() %>% 
  resp_body_json(simplifyVector = TRUE)

resp_me

# api 
## nevermind 



# webscraping ----

# link <- "https://www.eventbrite.es/d/spain--madrid/all-events/"
link <- "https://www.eventbrite.es/d/spain--madrid/events--today/?page=1"

html_link <- link |> read_html()

direct <- "/html/body/div[2]/div/div[2]/div/div/div/div[1]/div/main/div/div[1]/section[1]/div/section/div/div/section/ul/li[1]/div/div[2]/section/div/section[2]/div/a"

event_direct <-  html_link %>%
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

html_link |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//h2") |> 
  xml_text()



todays_event_times <- html_link |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']")
todays_event_times |> 
  xml_text()




