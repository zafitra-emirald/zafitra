# Test registration eligibility for rejected users

source("global.R")

cat("🧪 Testing Registration Eligibility for Rejected Users\n")
cat("======================================================\n")

initialize_data_layer()

# Get current data
current_data <- refresh_pendaftaran_data()
cat("📊 Total registrations:", nrow(current_data), "\n")

# Check status distribution
status_counts <- table(current_data$status_pendaftaran)
cat("📊 Status distribution:\n")
print(status_counts)

# Find a rejected record if any exists
rejected_records <- current_data[current_data$status_pendaftaran == "Ditolak", ]
cat("\n📊 Found", nrow(rejected_records), "rejected records\n")

if (nrow(rejected_records) > 0) {
  # Test eligibility for a rejected user
  test_record <- rejected_records[1, ]
  test_nim <- test_record$nim_mahasiswa
  
  cat("📝 Testing eligibility for rejected user:", test_nim, "\n")
  
  # Get available locations
  locations <- refresh_lokasi_data()
  test_location <- locations$nama_lokasi[1]
  
  cat("📝 Testing registration to location:", test_location, "\n")
  
  # Test eligibility
  eligibility <- check_registration_eligibility(test_nim, test_location, current_data, refresh_periode_data())
  
  cat("📊 Eligibility result:", eligibility$eligible, "\n")
  if (!eligibility$eligible) {
    cat("📊 Reason:", eligibility$reason, "\n")
  }
  
  # Let's also check what registrations this NIM has
  nim_registrations <- current_data[current_data$nim_mahasiswa == test_nim, ]
  cat("\n📊 All registrations for NIM", test_nim, ":\n")
  for (i in 1:nrow(nim_registrations)) {
    reg <- nim_registrations[i, ]
    cat("  ID:", reg$id_pendaftaran, "- Status:", reg$status_pendaftaran, "\n")
  }
  
  # Test the specific logic
  existing_active <- current_data[
    !is.na(current_data$nim_mahasiswa) & 
    current_data$nim_mahasiswa == test_nim & 
    current_data$status_pendaftaran %in% c("Diajukan", "Disetujui"), 
  ]
  
  cat("\n📊 Active registrations for this NIM:", nrow(existing_active), "\n")
  if (nrow(existing_active) > 0) {
    cat("📊 Active registration statuses:\n")
    for (i in 1:nrow(existing_active)) {
      cat("  Status:", existing_active$status_pendaftaran[i], "\n")
    }
  }
  
} else {
  cat("❌ No rejected records found to test\n")
  
  # Create a test rejection to verify the flow
  if (nrow(current_data) > 0) {
    test_record <- current_data[1, ]
    test_id <- test_record$id_pendaftaran
    test_nim <- test_record$nim_mahasiswa
    original_status <- test_record$status_pendaftaran
    
    cat("\n📝 Creating temporary rejection for testing...\n")
    cat("📝 Using record ID:", test_id, "NIM:", test_nim, "\n")
    cat("📝 Original status:", original_status, "\n")
    
    # Temporarily reject
    tryCatch({
      update_pendaftaran_status_mongo(test_id, "Ditolak", "Temporary test rejection")
      cat("✅ Temporary rejection applied\n")
      
      # Test eligibility
      updated_data <- refresh_pendaftaran_data()
      locations <- refresh_lokasi_data()
      test_location <- locations$nama_lokasi[1]
      
      eligibility <- check_registration_eligibility(test_nim, test_location, updated_data, refresh_periode_data())
      cat("📊 Eligibility after rejection:", eligibility$eligible, "\n")
      if (!eligibility$eligible) {
        cat("📊 Reason:", eligibility$reason, "\n")
      }
      
      # Restore original status
      cat("\n🔄 Restoring original status...\n")
      update_pendaftaran_status_mongo(test_id, original_status, "")
      cat("✅ Original status restored\n")
      
    }, error = function(e) {
      cat("❌ Test failed:", e$message, "\n")
    })
  }
}

cat("\n🏁 Eligibility debug test completed!\n")