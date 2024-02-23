## turns out the eventbrite API is not useful for what we need 

## token key ----

dotenv::load_dot_env(file = "a.env")
token_key <- Sys.getenv("EVENTBRITE_TOKEN")

url_example <- paste0("https://www.eventbriteapi.com/v3/users/me/?token=",token_key)


## api me   ----

resp_me <- url_example %>% 
  request() %>% 
  req_perform() %>% 
  resp_body_json(simplifyVector = TRUE)

resp_me

# api 
## nevermind 

