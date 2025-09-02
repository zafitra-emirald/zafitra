# update_pendaftaran_status_mongo.R
# Function to atomically update pendaftaran status in MongoDB

source("fn/mongodb_config.R")

update_pendaftaran_status_mongo <- function(registration_id, new_status, rejection_reason = "") {
  
  # Validate input parameters
  if (is.null(registration_id) || is.na(registration_id)) {
    stop("Registration ID is required")
  }
  
  if (is.null(new_status) || new_status == "") {
    stop("New status is required")
  }
  
  valid_statuses <- c("Diajukan", "Disetujui", "Ditolak")
  if (!new_status %in% valid_statuses) {
    stop(paste("Invalid status. Must be one of:", paste(valid_statuses, collapse = ", ")))
  }
  
  tryCatch({
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    
    # First, verify the registration exists
    existing_reg <- pendaftaran_conn$find(paste0('{"id_pendaftaran": ', as.integer(registration_id), '}'))
    
    if (nrow(existing_reg) == 0) {
      pendaftaran_conn$disconnect()
      stop(paste("Registration with ID", registration_id, "not found"))
    }
    
    # Prepare update data
    update_data <- list(
      status_pendaftaran = new_status,
      alasan_penolakan = if (new_status == "Ditolak") as.character(rejection_reason) else ""
    )
    
    # Perform atomic update
    update_result <- pendaftaran_conn$update(
      query = paste0('{"id_pendaftaran": ', as.integer(registration_id), '}'),
      update = paste0('{"$set": ', jsonlite::toJSON(update_data, auto_unbox = TRUE), '}')
    )
    
    # Verify the update was successful
    updated_reg <- pendaftaran_conn$find(paste0('{"id_pendaftaran": ', as.integer(registration_id), '}'))
    
    if (nrow(updated_reg) == 0) {
      pendaftaran_conn$disconnect()
      stop("Update verification failed - record not found after update")
    }
    
    if (updated_reg$status_pendaftaran[1] != new_status) {
      pendaftaran_conn$disconnect()
      stop("Update verification failed - status not updated correctly")
    }
    
    pendaftaran_conn$disconnect()
    
    cat("✅ Registration", registration_id, "status updated to:", new_status, "\n")
    return(TRUE)
    
  }, error = function(e) {
    stop(paste("MongoDB status update failed:", e$message))
  })
}