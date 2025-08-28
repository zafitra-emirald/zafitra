# backup_stubs.R  
# Stub functions for backup functionality (disabled after MongoDB migration)

# Stub function to prevent errors
list_available_backups <- function() {
  data.frame(
    data_type = character(0),
    file_path = character(0),
    stringsAsFactors = FALSE
  )
}

# Stub function to prevent errors  
get_backup_summary <- function() {
  data.frame(
    `Data Type` = character(0),
    `Total Backups` = integer(0),
    `Latest Backup` = character(0),
    `Oldest Backup` = character(0),
    `Total Size (MB)` = numeric(0),
    stringsAsFactors = FALSE
  )
}

# Stub function to prevent errors
emergency_restore <- function(create_restore_backup = TRUE) {
  list(
    success = FALSE,
    error = "Backup/restore functionality has been disabled. System now uses MongoDB Atlas.",
    restored_files = list()
  )
}

# Stub function to prevent errors  
restore_from_backup <- function(backup_files, create_restore_backup = TRUE) {
  list(
    success = FALSE,
    error = "Backup/restore functionality has been disabled. System now uses MongoDB Atlas.",
    restored_files = list()
  )
}

# Stub function to prevent errors
get_latest_backups <- function() {
  list(
    kategori_data = NULL,
    periode_data = NULL,
    lokasi_data = NULL,
    pendaftaran_data = NULL
  )
}