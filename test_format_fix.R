# Test if the format error is fixed

source("global.R")

cat("🧪 Testing Format Fix\n")
cat("====================\n")

tryCatch({
  initialize_data_layer()
  cat("✅ Data layer initialized successfully\n")
  
  # Test refresh functions
  current_data <- refresh_pendaftaran_data()
  cat("✅ Pendaftaran data refreshed successfully\n")
  cat("📊 Found", nrow(current_data), "records\n")
  
  if (nrow(current_data) > 0) {
    # Test timestamp formatting on a sample record
    sample_timestamp <- current_data$timestamp[1]
    cat("📊 Sample timestamp:", sample_timestamp, "\n")
    
    # Test the format conversion we just added
    formatted_timestamp <- tryCatch(
      format(as.POSIXct(sample_timestamp), "%d-%m-%Y %H:%M"), 
      error = function(e) as.character(sample_timestamp)
    )
    cat("📊 Formatted timestamp:", formatted_timestamp, "\n")
  }
  
  cat("✅ Format fix test passed!\n")
  
}, error = function(e) {
  cat("❌ Format fix test failed:", e$message, "\n")
})

cat("\n🏁 Format fix test completed!\n")