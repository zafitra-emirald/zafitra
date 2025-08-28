# check_registration_eligibility.R
# Function to check registration eligibility

check_registration_eligibility <- function(nim_mahasiswa, location_name, pendaftaran_data = NULL, periode_data = NULL) {
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
  
  # Check if student (by NIM) already has active registration (Diajukan or Disetujui)
  # Only allow registration if all previous registrations are rejected
  existing_active <- pendaftaran_data[
    !is.na(pendaftaran_data$nim_mahasiswa) & 
    pendaftaran_data$nim_mahasiswa == nim_mahasiswa & 
    pendaftaran_data$status_pendaftaran %in% c("Diajukan", "Disetujui"), 
  ]
  
  if(nrow(existing_active) > 0) {
    existing_status <- existing_active$status_pendaftaran[1]
    if(existing_status == "Diajukan") {
      return(list(eligible = FALSE, reason = "Anda sudah memiliki pendaftaran yang sedang diproses. Tunggu hasil review sebelum mendaftar lagi."))
    } else if(existing_status == "Disetujui") {
      return(list(eligible = FALSE, reason = "Anda sudah diterima di lokasi lain. Tidak dapat mendaftar di lokasi lain."))
    }
  }
  
  return(list(eligible = TRUE, reason = ""))
}