# check_category_usage.R
# Function to check if kategori can be deleted (used in lokasi)

check_category_usage <- function(kategori_id, lokasi_data = NULL) {
  if(is.null(lokasi_data)) {
    if(exists("lokasi_data")) {
      lokasi_data <- get("lokasi_data", envir = .GlobalEnv)
    } else {
      return(list(can_delete = TRUE, reason = ""))
    }
  }
  
  if(exists("kategori_data")) {
    kategori_name <- kategori_data[kategori_data$id_kategori == kategori_id, "nama_kategori"]
    if(length(kategori_name) == 0) return(list(can_delete = FALSE, reason = "Kategori tidak ditemukan"))
    
    usage_count <- sum(lokasi_data$kategori_lokasi == kategori_name)
    
    if(usage_count > 0) {
      return(list(can_delete = FALSE, reason = paste("Kategori digunakan oleh", usage_count, "lokasi")))
    }
  }
  
  return(list(can_delete = TRUE, reason = ""))
}