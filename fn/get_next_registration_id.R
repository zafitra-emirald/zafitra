# get_next_registration_id.R
# Function to generate next registration ID

get_next_registration_id <- function(pendaftaran_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(1)
    }
  }
  
  if(nrow(pendaftaran_data) == 0) {
    return(1)
  } else {
    return(max(pendaftaran_data$id_pendaftaran, na.rm = TRUE) + 1)
  }
}