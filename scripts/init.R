# loading all administrative R objects and functions into environment.
library(here)
library(dplyr)

# this is where schema files are loaded.
# for example, pdf_inventory.csv is loaded into sch$pdf_inventory
# and this object is a tibble with filename that is tied to each link.
sch <- purrr::map(
  list.files(here::here("data-raw", "schema"), full.names = TRUE),
  function(x){
    if(stringr::str_detect(x, "csv$")){
      readr::read_csv(x)
    }
  }
) %>%
  setNames(
    list.files(
      here::here("data-raw", "schema"), 
               full.names = FALSE) %>% 
      stringr::str_remove("\\.[:alpha:]{1,4}$")
  )
