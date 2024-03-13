# Data Harvesting Final Project 
 > By Frederick Peña Sims & Eric Hausken-Brates

![Static Badge](https://img.shields.io/badge/R_code-%23276DC3?logo=R&labelColor=white&logoColor=%23276DC3)
![Static Badge](https://img.shields.io/badge/HTML-grey?logo=htmx&logoColor=gray&labelColor=white)
![Static Badge](https://img.shields.io/badge/JSON-grey?logo=htmx&logoColor=gray&labelColor=white)

## At a glance

This is a robust scraper for the event-ticket website eventbrite.es. The functions allow you to plug in a city name and generate a .csv file with all events from the previously specified date. The 'date' folder contains sample data that we have scraped, while the .rmd file contains all functions and code to read all data into one single data frame in R.

## Get familiar with Eventbrite url & html 

The Eventbrite url is formatted so that you can select the city you want. You can also select the date of events and page number. Some cities have over 100 pages of events, with each page having 20 events. 

`https://www.eventbrite.es/d/country--city/events--tomorrow/?page=000`

We created a function `load_cities_list()` so that you can get the correct format for the following cities. We decided to scrape the events for the following day but you can manually adjust this in the url from `events--tomorrow/` to `events--today/`.

 * Madrid 🇪🇸
 * Barcelona 🇪🇸 
 * Bilbao 🇪🇸
 * Cádiz 🇪🇸
 * Granada 🇪🇸
 * Malaga 🇪🇸
 * Marbella 🇪🇸
 * San Sebastian 🇪🇸
 * Valladolid 🇪🇸
 * Vigo 🇪🇸
 * Zaragoza 🇪🇸
 * Roma 🇮🇹
 * Lisbon 🇵🇹
 * London 🏴󠁧󠁢󠁥󠁮󠁧󠁿
 * Glasgow 🏴󠁧󠁢󠁳󠁣󠁴󠁿
 * Dublin 🇮🇪
 * Sydney 🇦🇺
 * Paris 🇫🇷
 * Lyon 🇫🇷
 * Marseille 🇫🇷
 * San Francisco 🇺🇸
 * Berlin 🇩🇪
 * Amsterdam 🇳🇱
 * Warsaw 🇵🇱
 * Santiago 🇨🇱
 * Buenos Aires 🇦🇷
 * Lima 🇵🇪

The list currently includes 15 countries from four continents (Europe, N.America, S.America, Australia). Of course, you may add more cities at your pleasure following our example.

### Required packages

```
library(tidyverse)
library(rvest)
library(xml2)
library(jsonlite)
library(httr)
library(tm)
library(tidytext)
library(forcats)
```

## Functions available: 

#### Create the url from the list above
`create_url(cityname)` 
Returns the url for tomorrow's events in the format needed for the functions below. 

#### How many pages of events for *cityname* ? 
`count_pages(url)`
Returns the number of pages for a city. 

#### Get links to the individual events 
`get_event_links(url, page_num)`
Returns a list of strings with the urls. 

#### Get all the event links for all pages 
`get_all_event_links(url)`
Returns a list of strings the urls for all pages. 

### Get all the data 
`get_event_info(url, cityname)`
This function returns all the event data for all the events on all pages for a specific city and date. 
It creates a dataframe and exports it as a .CSV file with the name `cityname_DATE.csv`. 

Currently, the dataframe includes the following info: 
* event duration
* ticket type
* refund policy
* description
* lowest price
* highest price
* currency
* organizer name
* event status (not useful)
* start time
* end time
* event title
* subtitle
* url
* city

## Disclaimer 🛑 

This project was built with the academic purpose of practicing data harvesting techniques. We have not and will not use this project for commercial purposes. We do not condone anyone using this code for commercial purposes. Our intention of sharing this repository is to showcase our skills. 

