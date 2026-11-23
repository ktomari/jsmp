# Report files ----
library(dplyr)
library(here)

html_home <- rvest::read_html("https://oce.saccounty.gov/us/en/dce/public-safety-and-justice/reports-and-resources/jailsystemmasterplan.html")

links_tb <- rvest::html_elements(html_home, "a") %>%
  rvest::html_attr("href") %>%
  tibble::tibble(href = .) %>%
  dplyr::filter(!is.na(href)) %>%
  dplyr::mutate(base = purrr::map_chr(
    href,
    function(x){
      stringr::str_split_1(x, "\\/") %>%
        dplyr::last()
    }
  )) %>%
  dplyr::filter(stringr::str_detect(base, "\\.pdf$")) %>%
  dplyr::mutate(href = dplyr::case_when(
    stringr::str_detect(href, "http") ~ href,
    .default = paste0("https://oce.saccounty.gov", href)
  ))
  
purrr::walk(
  1:nrow(links_tb),
  function(row){
    curl::curl_download(
      url = links_tb$href[row],
      destfile = here::here("data-raw", "downloads", links_tb$base[row]),
      quiet = FALSE
    )
  }
)

# write inventory
readr::write_csv(
  links_tb,
  file = here::here("data-raw", "schema", "pdf_inventory.csv")
)
