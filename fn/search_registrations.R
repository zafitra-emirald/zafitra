# search_registrations.R
# Function to search registrations with multiple criteria

search_registrations <- function(nama = NULL, nim = NULL, tanggal = NULL, lokasi = NULL, status = NULL, pendaftaran_data = NULL) {
  if(is.null(pendaftaran_data)) {
    if(exists("pendaftaran_data")) {
      pendaftaran_data <- get("pendaftaran_data", envir = .GlobalEnv)
    } else {
      return(data.frame())
    }
  }
  
  result <- pendaftaran_data
  
  # Filter by name (partial match, case insensitive)
  if(!is.null(nama) && nama != "") {
    result <- result[grepl(nama, result$nama_mahasiswa, ignore.case = TRUE), ]
  }
  
  # Filter by NIM (partial match) - FIXED: handle empty NIMs properly
  if(!is.null(nim) && nchar(trimws(nim)) > 0) {
    # Only search records that have non-empty NIMs
    result <- result[!is.na(result$nim_mahasiswa) & 
                     result$nim_mahasiswa != "" & 
                     grepl(nim, result$nim_mahasiswa, ignore.case = TRUE), ]
  }
  
  # Filter by date (exact match)
  if(!is.null(tanggal) && !is.na(tanggal)) {
    result <- result[as.Date(result$timestamp) == tanggal, ]
  }
  
  # Filter by location
  if(!is.null(lokasi) && lokasi != "") {
    result <- result[result$pilihan_lokasi == lokasi, ]
  }
  
  # Filter by status
  if(!is.null(status) && status != "") {
    result <- result[result$status_pendaftaran == status, ]
  }
  
  return(result)
}