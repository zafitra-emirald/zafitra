# Test UI behavior for rejected users - simulate what a rejected user would see

source("global.R")

cat("🧪 Testing UI Behavior for Rejected Users\n")
cat("=========================================\n")

initialize_data_layer()

# Get current data
current_data <- refresh_pendaftaran_data()

# Find a rejected user
rejected_records <- current_data[current_data$status_pendaftaran == "Ditolak", ]

if (nrow(rejected_records) > 0) {
  test_nim <- rejected_records$nim_mahasiswa[1] 
  cat("📝 Testing UI for rejected user NIM:", test_nim, "\n")
  
  # Check their registration status
  user_registrations <- current_data[current_data$nim_mahasiswa == test_nim, ]
  cat("📊 User has", nrow(user_registrations), "total registrations:\n")
  
  for (i in 1:nrow(user_registrations)) {
    reg <- user_registrations[i, ]
    cat("  ID:", reg$id_pendaftaran, "- Status:", reg$status_pendaftaran, "- Location:", reg$pilihan_lokasi, "\n")
  }
  
  # Test eligibility for different locations
  locations <- refresh_lokasi_data()
  cat("\n📝 Testing eligibility for different locations:\n")
  
  for (j in 1:min(3, nrow(locations))) {
    location_name <- locations$nama_lokasi[j]
    eligibility <- check_registration_eligibility(test_nim, location_name, current_data, refresh_periode_data())
    cat("  Location '", location_name, "': ", eligibility$eligible, 
        if (!eligibility$eligible) paste(" (", eligibility$reason, ")") else "", "\n", sep = "")
  }
  
  # Now test the quota calculation for one location
  test_location <- locations$nama_lokasi[1]
  quota_status <- get_current_quota_status(test_location, current_data, locations)
  
  cat("\n📊 Quota status for location '", test_location, "':\n", sep = "")
  cat("  Total quota:", quota_status$total_quota, "\n")
  cat("  Used quota:", quota_status$used_quota, "\n") 
  cat("  Available quota:", quota_status$available_quota, "\n")
  cat("  Pending:", quota_status$pending, "\n")
  cat("  Approved:", quota_status$approved, "\n")
  cat("  Rejected:", quota_status$rejected, "\n")
  
  # Test if button would show
  registration_open <- is_registration_open(refresh_periode_data())
  button_would_show <- quota_status$available_quota > 0 && registration_open
  
  cat("\n📊 Registration period open:", registration_open, "\n")
  cat("📊 Would 'Daftar' button show:", button_would_show, "\n")
  
  if (!button_would_show) {
    if (!registration_open) {
      cat("❌ Issue: Registration period is closed\n")
    } else if (quota_status$available_quota <= 0) {
      cat("❌ Issue: No available quota\n")
    }
  }
  
} else {
  cat("❌ No rejected users found to test\n")
}

cat("\n🏁 UI behavior test completed!\n")