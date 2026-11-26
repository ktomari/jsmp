get_pdf_geom_interactive <- function(path_pdf, pg, iter, height, width){
  # Note, get height and width from magick::image_info(image_read_pdf())
  out <- list()
  
  # get tabulapdf's page dimensions first
  page_dims <- tabulapdf::get_page_dims(
    file = path_pdf,
    pages = pg 
  )
  
  # iteratively and interactively get dims
  for(i in 1:iter){
    message(paste0("Page: ", pg, ". Make selection ", i, "/", iter))
    
    area <- tabulapdf::locate_areas(
      file = path_pdf, 
      pages = pg
    )[[1]]
    
    y_off <- (height * area["top"]/page_dims[[1]][2])
    x_off <- (width * area["left"]/page_dims[[1]][1])
    
    df <- tibble::tibble(
      pg = pg,
      iter = i,
      y_off = y_off,
      height = ((height * area["bottom"]/page_dims[[1]][2]) - y_off),
      x_off = x_off,
      width = ((width * area["right"]/page_dims[[1]][1]) - x_off)
    )
    
    out <- append(out, list(df))
    
  }
  
  # return
  out %>%
    dplyr::bind_rows()
}