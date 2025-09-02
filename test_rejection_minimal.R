# Minimal test - test rejection on existing data without creating new records

source("global.R")

cat("🧪 Minimal Rejection Test (Using Existing Data)\n")
cat("===============================================\n")

initialize_data_layer()

# Get existing data
current_data <- refresh_pendaftaran_data()
cat("📊 Found", nrow(current_data), "existing registrations\n")

if (nrow(current_data) > 0) {
  # Use the first record for testing
  test_record <- current_data[1, ]
  test_id <- test_record$id_pendaftaran
  original_status <- test_record$status_pendaftaran
  original_reason <- test_record$alasan_penolakan
  
  cat("📝 Using existing record ID:", test_id, "for testing\n")
  cat("📊 Original status:", original_status, "\n")
  cat("📊 Original reason:", original_reason, "\n")
  
  # Test rejection
  cat("\n📝 Testing rejection function...\n")
  rejection_success <- tryCatch({
    update_pendaftaran_status_mongo(test_id, "Ditolak", "Temporary test rejection")
    cat("✅ Rejection function executed\n")
    TRUE
  }, error = function(e) {
    cat("❌ Rejection failed:", e$message, "\n")
    FALSE
  })
  
  if (rejection_success) {
    # Check if update worked
    updated_data <- refresh_pendaftaran_data()
    updated_record <- updated_data[updated_data$id_pendaftaran == test_id, ]
    
    if (nrow(updated_record) > 0) {
      cat("📊 Status after rejection:", updated_record$status_pendaftaran[1], "\n")
      cat("📊 Reason after rejection:", updated_record$alasan_penolakan[1], "\n")
      
      if (updated_record$status_pendaftaran[1] == "Ditolak") {
        cat("✅ REJECTION WORKING!\n")
      } else {
        cat("❌ Rejection not working - status not updated\n")
      }
    }
    
    # IMPORTANT: Restore original data
    cat("\n🔄 Restoring original data...\n")
    restore_success <- tryCatch({
      update_pendaftaran_status_mongo(test_id, original_status, original_reason)
      cat("✅ Original data restored\n")
      TRUE
    }, error = function(e) {
      cat("❌ Failed to restore original data:", e$message, "\n")
      FALSE
    })
    
    if (restore_success) {
      # Verify restoration
      final_data <- refresh_pendaftaran_data()
      final_record <- final_data[final_data$id_pendaftaran == test_id, ]
      
      if (nrow(final_record) > 0) {
        cat("📊 Final status (should match original):", final_record$status_pendaftaran[1], "\n")
        cat("📊 Final reason (should match original):", final_record$alasan_penolakan[1], "\n")
        
        if (final_record$status_pendaftaran[1] == original_status && final_record$alasan_penolakan[1] == original_reason) {
          cat("✅ ORIGINAL DATA SUCCESSFULLY RESTORED!\n")
        } else {
          cat("❌ WARNING: Original data not fully restored\n")
        }
      }
    }
  }
  
} else {
  cat("❌ No existing data found for testing\n")
}

cat("\n🏁 Minimal rejection test completed!\n")