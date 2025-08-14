# check_registration_eligibility.R
# Function to check registration eligibility

check_registration_eligibility <- function(student_name, location_name, pendaftaran_data = NULL, periode_data = NULL) {
  # Check if registration period is open
  if(!is_registration_open(periode_data)) {
    return(list(eligible = FALSE, reason = "Periode pendaftaran tidak aktif"))
  }
  
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(list(eligible = TRUE, reason = ""))
    }
  }
  
  # Check if student already has active registration
  existing <- pendaftaran_data[
    pendaftaran_data$nama_mahasiswa == student_name & 
      pendaftaran_data$status_pendaftaran %in% c("Diajukan", "Disetujui"), 
  ]
  
  if(nrow(existing) > 0) {
    return(list(eligible = FALSE, reason = "Sudah terdaftar di lokasi lain atau masih dalam proses review"))
  }
  
  return(list(eligible = TRUE, reason = ""))
}