# get_current_quota_status.R
# Function to get current quota status for a location

get_current_quota_status <- function(location_name, pendaftaran_data = NULL, lokasi_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    }
  }
  
  if(is.null(lokasi_data)) {
    if(exists("lokasi_data")) {
      lokasi_data <- get("lokasi_data", envir = .GlobalEnv)
    }
  }
  
  # Get location info
  lokasi <- lokasi_data[lokasi_data$nama_lokasi == location_name, ]
  if(nrow(lokasi) == 0) {
    return(list(
      total_quota = 0,
      used_quota = 0,
      available_quota = 0,
      pending = 0,
      approved = 0,
      rejected = 0
    ))
  }
  
  # Count registrations for this location
  registrations <- pendaftaran_data[pendaftaran_data$pilihan_lokasi == location_name, ]
  
  pending <- sum(registrations$status_pendaftaran == "Diajukan", na.rm = TRUE)
  approved <- sum(registrations$status_pendaftaran == "Disetujui", na.rm = TRUE)
  rejected <- sum(registrations$status_pendaftaran == "Ditolak", na.rm = TRUE)
  
  # Used quota includes both pending and approved
  used_quota <- pending + approved
  available_quota <- max(0, lokasi$kuota_mahasiswa - used_quota)
  
  return(list(
    total_quota = lokasi$kuota_mahasiswa,
    used_quota = used_quota,
    available_quota = available_quota,
    pending = pending,
    approved = approved,
    rejected = rejected
  ))
}