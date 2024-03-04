# here are the functions for pulling data: 

library(tidyverse)
library(rvest)
library(xml2)
library(jsonlite)

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
  
  cities_list <- load_cities_list()  # loading city list into function
  
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


get_event_links <- function(link, page_num) {
  
  link_with_page_num <- paste0(link, "?page=", page_num) # adds page number info to url 
  
  html_link <- link_with_page_num |> 
    read_html() |>
    xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']//a") |> 
    xml_attr("href")
  
  # remove the repeating titles 
  links <- unique(html_link)
  
  return(links)
}


get_all_event_links <- function(link) {
  
  all_event_links <- c() # creates empty vector
  
  pages_count <- count_pages(link = link) # gets number of available pages at this link 
  
  pages_count <- min(10, pages_count) # don't pull more than 10 pages at once
  
  for (i in 1:pages_count) {
    
    Sys.sleep(2)
    # loops through number of pages 
    # gets a new batch of event links from page i 
    links <- get_event_links(link = link, page_num = i)
    
    # adds it to the full vector of titles 
    all_event_links <- c(all_event_links, links) 
  }
  
  # returns only event links that are not NA and that are unique
  return(unique(all_event_links[!is.na(all_event_links)]))
  
}

convert_time_format <- function(time_string) {
  # Check if "pm" or "PM" is present in the input string
  if (str_detect(time_string, "pm|PM")) {
    # Extract hours and minutes from the input string
    time_parts <- str_match(time_string, "(\\d+):(\\d+) - (\\d+):(\\d+)(pm)?")
    start_hour <- as.integer(time_parts[2])
    start_minute <- as.integer(time_parts[3])
    end_hour <- as.integer(time_parts[4])
    end_minute <- as.integer(time_parts[5])
    
    # Convert to 24-hour format
    if (start_hour != 12) {
      start_hour <- start_hour + 12
    }
    if (end_hour != 12) {
      end_hour <- end_hour + 12
    }
    
    # Return the time string in the desired format
    result <- sprintf("%02d:%02d - %02d:%02d", start_hour, start_minute, end_hour, end_minute)
  } else {
    # Return the original time string if "pm" or "PM" is not present
    result <- time_string
  }
  
  return(result)
}


get_event_info <- function(link) {
  
shared_df <- data.frame(Duration = character(), 
                        Ticket_Type = character(),
                        Refund_Policy = character(), 
                        Description = character(),
                        StartTime = character(),
                        Currency = character(),
                        LowPrice = numeric(),
                        HighPrice = numeric(),
                        EventStatus = character(),
                        stringsAsFactors = FALSE)

all_links <- get_all_event_links(link)

# Loop over each link in 'test_object'
for (i in seq_along(all_links)) {
  
  link <- all_links[i]
  html <- link |> read_html()
  
  # Read HTML and extract duration if there is information, if not NA
  duration <- if (html |> 
                  xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
                  length() == 0) {
    NA
  } else {
    html |>
      xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |>
      xml_text() %>%
      .[[1]]
  }
    
  
  # Extract ticket type
  ticket_type <- if (html |> 
    xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
    length() == 0) {
      "Sold out"
    } else {
      html |> 
        xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
        xml_text() %>%
        .[[2]]
    }
  
  # Extract refund policy
  refund_policy <- if (html |> 
    xml_find_all("//div[@class = 'Layout-module__module___2eUcs Layout-module__refundPolicy___fQ8I7']//section[@class = 'event-details__section']/div") |> 
    length() == 0) {
      NA
    } else {
      html |> 
        xml_find_all("//div[@class = 'Layout-module__module___2eUcs Layout-module__refundPolicy___fQ8I7']//section[@class = 'event-details__section']/div") |> 
        xml_text() %>%
        .[[2]]
    }
  
  # Extract description
  description <- if (html |> 
    xml_find_all("//div[@class = 'eds-text--left']//p") |> 
    length() == 0){
      NA
    } else {
      html |> 
        xml_find_all("//div[@class = 'eds-text--left']//p") |> 
        xml_text() |> 
        discard(~.x == "") |> 
        paste(collapse = " ") 
    }
  
  # Extract start time
  pre_converted_time <- if (
    html |> 
    xml_find_all("//div[@class = 'date-info']//span") |>
    length() == 0) {
    NA
  } else {
    html |> 
      xml_find_all("//div[@class = 'date-info']//span") |> 
      xml_text() |>  
      str_extract_all("\\b(?:\\d+:\\d+(?:pm|PM|am|AM)?|(?:\\d+:)?\\d+pm|\\d+PM|\\d+am|\\d+AM|\\d+ - \\d+:\\d+(?:pm|PM|am|AM)?|\\d+ - \\d+(?:pm|PM|am|AM)?)") %>%
      .[[1]] %>%
      paste0(collapse = " - ")  %>% 
      {if (str_detect(., "\\b\\d{1}(?![0-9]|:)(?:pm|PM|am|AM)")) { # Matches single-digit numbers not followed by another digit or colon, followed by "pm" or "am"
        gsub("\\b(\\d{1})(pm|PM|am|AM)", "0\\1:00\\2", .)
      } else if (str_detect(., "\\b(\\d{1}):?")) { # Matches singular numbers followed by a colon
        gsub("\\b(\\d{1}):", "0\\1:", .)
      } else if (str_detect(., "\\d{1} - \\d{1}(?:pm|PM|am|AM)?")){
        gsub("(\\d{1,2}) - (\\d{1,2})(pm|PM|am|AM)", "0\\1:00 - 0\\2:00\\3", .)
      } else if (str_detect(., "\\d{1}(?:pm|PM|am|AM)?")){
        if_else(str_detect(., "pm|PM"), gsub("(\\d{1})(pm|PM|am|AM)?", "0\\1:00 - 00:00pm", .), 
                gsub("(\\d{1})(pm|PM|am|AM)?", "0\\1:00 - 00:00", .))
      } else if (str_detect(., "\\d{1}")) {
        gsub("(\\d{1})", "0\\1:00", .)
      } else {
        paste(.)
      }
      } %>%
      gsub("\\b(\\d)( - |$)", "0\\1:00\\2", .) %>%
      gsub("^\\b(\\d{2}:\\d{2})(pm|am|PM|AM)$", "\\1 - 00:00\\2", .) %>%
      gsub("^(\\d{2}:\\d{2})$", "\\1 - 00:00\\2", .)
  }
  
  startime <- convert_time_format(pre_converted_time)
  
  # Add duration, ticket type, refund policy, and description to the shared data frame
  shared_df[i, "Duration"] <- duration
  shared_df[i, "Ticket_Type"] <- ticket_type
  shared_df[i, "Refund_Policy"] <- refund_policy
  shared_df[i, "Description"] <- description
  shared_df[i, "StartTime"] <- starttime

  # pull json data 
  json <- 
    html |> 
    xml_find_all("//script[@type='application/ld+json']") |> 
    pluck(1) |> 
    xml_text()
  json <- fromJSON(json)
  
  shared_df[i, "LowPrice"] <- json$offers$lowPrice[1]
  shared_df[i, "HighPrice"] <- json$offers$highPrice[1]
  shared_df[i, "Currency"] <- json$offers$priceCurrency[1]
  shared_df[i, "Organizer"] <- json$organizer$name
  shared_df[i, "EventStatus"] <- json$eventStatus
  shared_df[i, "StartTime"] <- lubridate::as_datetime(json$startDate)
  shared_df[i, "EndTime"] <- lubridate::as_datetime(json$endDate)
  shared_df[i, "Title"] <- json$name
  shared_df[i, "Subtitle"] <- json$description
  shared_df[i, "url"] <- json$url
  
}

return(shared_df)
}







## examples ----

l <- "https://www.eventbrite.es/d/united-kingdom--london/events--today/"
count_pages(l)
get_all_titles(link = l)

# getting event links
load_cities_list()
l <- create_url(city = "madrid")

test_object <- get_all_event_links(l)
df <- get_event_info(l)

# Testing ground ----

# if else function

link <- "https://www.eventbrite.com/e/48-wurzburger-gypsy-jazz-session-tickets-797993759817?aff=ebdssbdestsearch&keep_tld=1"

link <- "https://www.eventbrite.com/e/breakout-frankfurt-tickets-826263906587?aff=ebdssbdestsearch&keep_tld=1"

duration <- if (link |> 
                read_html() |> 
                xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
                length() == 0) {
  NA
} else {
  link |>
    read_html() |>
    xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |>
    xml_text() %>%
    .[[1]]
}

ticket_type <- if (link |> 
                   read_html() |> 
                   xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
                   length() == 0) {
  "Sold out"
} else {
  link |> 
    read_html() |> 
    xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
    xml_text() %>%
    .[[2]]
}

# start and end
link <- "https://www.eventbrite.com/e/london-startup-networking-tickets-849932459867?aff=ebdssbdestsearch"

link <- "https://www.eventbrite.com/e/an-evening-of-poetry-and-prose-with-mike-parker-and-hanan-issa-tickets-761231332407?aff=ebdssbdestsearch"

link <- "https://www.eventbrite.com/e/penny-lecture-james-mac-tickets-819956039587?aff=ebdssbdestsearch&keep_tld=1"

link <- "https://www.eventbrite.com/e/healing-breathwork-accelerate-emotional-and-physical-healing-bexley-tickets-820692071077?aff=ebdssbdestsearch"

pre_converted_time <-
  link |> 
  read_html() |> 
  xml_find_all("//div[@class = 'date-info']//span") |> 
  xml_text() |>  
  str_extract_all("\\b(?:\\d+:\\d+(?:pm|PM|am|AM)?|(?:\\d+:)?\\d+pm|\\d+PM|\\d+am|\\d+AM|\\d+ - \\d+:\\d+(?:pm|PM|am|AM)?|\\d+ - \\d+(?:pm|PM|am|AM)?)") %>%
  .[[1]] %>%
  paste0(collapse = " - ")  %>% 
  {if (str_detect(., "\\b\\d{1}(?![0-9]|:)(?:pm|PM|am|AM)")) { # Matches single-digit numbers not followed by another digit or colon, followed by "pm" or "am"
    gsub("\\b(\\d{1})(pm|PM|am|AM)", "0\\1:00\\2", .)
  } else if (str_detect(., "\\b(\\d{1}):?")) { # Matches singular numbers followed by a colon
    gsub("\\b(\\d{1}):", "0\\1:", .)
  } else if (str_detect(., "\\d{1} - \\d{1}(?:pm|PM|am|AM)?")){
    gsub("(\\d{1,2}) - (\\d{1,2})(pm|PM|am|AM)", "0\\1:00 - 0\\2:00\\3", .)
  } else if (str_detect(., "\\d{1}(?:pm|PM|am|AM)?")){
    if_else(str_detect(., "pm|PM"), gsub("(\\d{1})(pm|PM|am|AM)?", "0\\1:00 - 00:00pm", .), 
            gsub("(\\d{1})(pm|PM|am|AM)?", "0\\1:00 - 00:00", .))
  } else if (str_detect(., "\\d{1}")) {
    gsub("(\\d{1})", "0\\1:00", .)
  } else {
    paste(.)
  }
  } %>%
  gsub("\\b(\\d)( - |$)", "0\\1:00\\2", .)


string <- "March 5, 15:00 18:00"

string |>  
  str_extract_all("\\b(?:\\d+:\\d+(?:pm|PM|am|AM)?|(?:\\d+:)?\\d+pm|\\d+PM|\\d+am|\\d+AM|\\d+ - \\d+:\\d+(?:pm|PM|am|AM)?|\\d+ - \\d+(?:pm|PM|am|AM)?)") %>%
  .[[1]] %>%
  paste0(collapse = " - ")  %>% 
  {if (str_detect(., "\\b\\d{1}(?![0-9]|:)(?:pm|PM|am|AM)")) { # Matches single-digit numbers not followed by another digit or colon, followed by "pm" or "am"
    gsub("\\b(\\d{1})(pm|PM|am|AM)", "0\\1:00\\2", .)
  } else if (str_detect(., "\\b(\\d{1}):?")) { # Matches singular numbers followed by a colon
    gsub("\\b(\\d{1}):", "0\\1:", .)
  } else if (str_detect(., "\\d{1} - \\d{1}(?:pm|PM|am|AM)?")){
    gsub("(\\d{1,2}) - (\\d{1,2})(pm|PM|am|AM)", "0\\1:00 - 0\\2:00\\3", .)
  } else if (str_detect(., "\\d{1}(?:pm|PM|am|AM)?")){
    if_else(str_detect(., "pm|PM"), gsub("(\\d{1})(pm|PM|am|AM)?", "0\\1:00 - 00:00pm", .), 
            gsub("(\\d{1})(am|AM)?", "0\\1:00 - 00:00", .))
  } else if (str_detect(., "\\d{1}")) {
    gsub("(\\d{1})", "0\\1:00", .)
  } else {
    paste(.)
  }
  } %>%
  gsub("\\b(\\d)( - |$)", "0\\1:00\\2", .) %>%
  gsub("^\\b(\\d{2}:\\d{2})(pm|am|PM|AM)$", "\\1 - 00:00\\2", .) %>%
  gsub("^(\\d{2}:\\d{2})$", "\\1 - 00:00\\2", .)


converted_time <- convert_time_format(pre_converted_time) |> 
  str_split("-") %>%
  .[[1]] |> 
  trimws() %>%
  .[[1]]

# needed for return one 
convert_time_format <- function(time_string) {
  # Check if "pm" or "PM" is present in the input string
  if (str_detect(time_string, "pm|PM")) {
    # Extract hours and minutes from the input string
    time_parts <- str_match(time_string, "(\\d+):(\\d+) - (\\d+):(\\d+)(pm)?")
    start_hour <- as.integer(time_parts[2])
    start_minute <- as.integer(time_parts[3])
    end_hour <- as.integer(time_parts[4])
    end_minute <- as.integer(time_parts[5])
    
    # Convert to 24-hour format
    if (start_hour != 12) {
      start_hour <- start_hour + 12
    }
    if (end_hour != 12) {
      end_hour <- end_hour + 12
    }
    
    # Return the time string in the desired format
    result <- sprintf("%02d:%02d - %02d:%02d", start_hour, start_minute, end_hour, end_minute)
  } else {
    # Return the original time string if "pm" or "PM" is not present
    result <- time_string
  }
  
  return(result)
}

# duration
duration <-
  link |> 
  read_html() |> 
  xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
  xml_text() %>% 
  .[[1]]

link |> 
  read_html() |> 
  xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
  xml_text() %>% 
  .[[1]]


# ticket type
ticket_type <-
  link |> 
  read_html() |> 
  xml_find_all("//li[@class = 'eds-text-bm eds-text-weight--heavy css-1eys03p']/text()") |> 
  xml_text() %>% 
  .[[2]]


# refund policy
refund_policy <-
  link |> 
  read_html() |> 
  xml_find_all("//div[@class = 'Layout-module__module___2eUcs Layout-module__refundPolicy___fQ8I7']//section[@class = 'event-details__section']/div") |> 
  xml_text() %>%
  .[[2]]

# description
description <- 
  link |> 
  read_html() |> 
  xml_find_all("//div[@class = 'eds-text--left']//p") |> 
  xml_text() |> 
  discard(~.x == "") |> 
  paste(collapse = " ")


#

"https://www.eventbrite.es/e/psychedelic-fridays-32-the-last-chapter-tickets-811257622387?aff=ebdssbdestsearch&keep_tld=1" |> 
  read_html() |> 
  xml_find_all("//div[@class = 'date-info']//span") |> 
  xml_text() |>  
  str_extract_all("(\\d+:)?\\d+(?:pm|PM|am|AM)?\\b")%>%
  .[[1]] |> 
  paste(collapse = " - ")

event-details__main-inner

"https://www.eventbrite.com/e/swiftogeddon-the-taylor-swift-club-night-tickets-769590464797?aff=ebdssbdestsearch&keep_tld=1" |> 
  read_html() |> 
  xml_find_all("//ul[@class = css-1i6cdnn]//span") |> 
  xml_text()


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
unique(link_event_page)


  

"https://www.eventbrite.es/d/united-kingdom--london/events--today/" |> 
  read_html() |> 
  xml_find_all("//section[@class='event-card-details']//div[@class='Stack_root__1ksk7']/div[@class='discover-horizontal-event-card__price-wrapper']/p") |> 
  xml_text()



