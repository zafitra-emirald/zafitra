# is_registration_open.R
# Function to check if registration is currently open

is_registration_open <- function(periode_data = NULL) {
  if(is.null(periode_data)) {
    if(exists("periode_data")) {
      periode_data <- get("periode_data", envir = .GlobalEnv)
    } else {
      return(FALSE)
    }
  }
  
  # Find active period
  active_periods <- periode_data[periode_data$status == "Aktif", ]
  if(nrow(active_periods) == 0) return(FALSE)
  
  # Check if current date is within active period
  current_date <- Sys.Date()
  active_period <- active_periods[1, ]
  
  return(current_date >= active_period$waktu_mulai & current_date <= active_period$waktu_selesai)
}