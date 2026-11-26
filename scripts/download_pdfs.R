# Report files ----
library(dplyr)
library(here)

# get page html
html_home <- rvest::read_html("https://oce.saccounty.gov/us/en/dce/public-safety-and-justice/reports-and-resources/jailsystemmasterplan.html")

# get all pdf files on page
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
  dplyr::mutate(base2 = utils::URLdecode(base)) %>%
  dplyr::mutate(href = dplyr::case_when(
    stringr::str_detect(href, "http") ~ href,
    .default = paste0("https://oce.saccounty.gov", href)
  ))

# categorize pdfs
links_tb <- links_tb %>%
  dplyr::mutate(stem = stringr::str_remove(
    href,
    "(?<=\\/)[^\\/]+\\.pdf$"
  )) %>%
  dplyr::mutate(type = dplyr::case_when(
    stem == "https://oce.saccounty.gov/content/dam/oce/documents/psj/jail-system-master-plan/master-plan-final-report/" ~ "final_report",
    # stem == "https://oce.saccounty.gov/content/dam/oce/documents/psj/jail-system-master-plan/master-plan-final-report/appendices/" ~ "appendix",
    stringr::str_detect(stem, "/appendices/") ~ "appendix",
    .default = "misc"
  ))
  
# download files, may time several minutes due to file size.
purrr::walk(
  1:nrow(links_tb),
  function(row){
    destfile <- here::here("data-raw", "downloads", links_tb$base[row])
    if(file.exists(destfile)) {
      return()
    }
    curl::curl_download(
      url = links_tb$href[row],
      destfile = destfile,
      quiet = FALSE
    )
  }
)


# get md5 hashes
links_tb <- links_tb %>%
  dplyr::mutate(md5 = purrr::map_chr(
    base,
    function(x){
      digest::digest(
        here::here("data-raw", "downloads", x),
        file = TRUE
        )
    }
  ))

# get pdf info
links_tb <- links_tb %>%
  dplyr::mutate(pages = purrr::map_int(
    base,
    function(x){
      qpdf::pdf_length(
        here::here("data-raw", "downloads", x)
      )
    }
  ))

# write inventory
readr::write_csv(
  links_tb,
  file = here::here("data-raw", "schema", "pdf_inventory.csv")
)
