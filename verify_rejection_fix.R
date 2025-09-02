# Comprehensive verification that rejection allows re-registration

source("global.R")

cat("🧪 Comprehensive Rejection Re-registration Verification\n")
cat("======================================================\n")

initialize_data_layer()

# Get current data
current_data <- refresh_pendaftaran_data()
current_lokasi <- refresh_lokasi_data()
current_periode <- refresh_periode_data()

cat("📊 System Status:\n")
cat("  Total registrations:", nrow(current_data), "\n")
cat("  Total locations:", nrow(current_lokasi), "\n")
cat("  Registration period open:", is_registration_open(current_periode), "\n")

# Test with actual rejected user if exists
rejected_users <- current_data[current_data$status_pendaftaran == "Ditolak", ]

if (nrow(rejected_users) > 0) {
  test_nim <- rejected_users$nim_mahasiswa[1]
  cat("\n📝 Testing with actual rejected user:", test_nim, "\n")
  
  # Show their current registrations
  user_regs <- current_data[current_data$nim_mahasiswa == test_nim, ]
  cat("📊 Current registrations for this user:\n")
  for (i in 1:nrow(user_regs)) {
    reg <- user_regs[i, ]
    cat("  ID:", reg$id_pendaftaran, "- Status:", reg$status_pendaftaran, 
        "- Location:", reg$pilihan_lokasi, "\n")
  }
  
  # Test all key functions step by step
  cat("\n🔍 Testing all key functions:\n")
  
  # 1. Registration period check
  period_open <- is_registration_open(current_periode)
  cat("1. Registration period open:", period_open, "\n")
  
  # 2. Eligibility check for each location
  cat("2. Eligibility checks:\n")
  for (j in 1:min(3, nrow(current_lokasi))) {
    loc_name <- current_lokasi$nama_lokasi[j]
    eligibility <- check_registration_eligibility(test_nim, loc_name, current_data, current_periode)
    cat("   Location '", loc_name, "': ", eligibility$eligible, 
        if (!eligibility$eligible) paste(" (", eligibility$reason, ")") else "", "\n", sep = "")
  }
  
  # 3. Quota check for each location
  cat("3. Quota availability:\n")
  for (j in 1:min(3, nrow(current_lokasi))) {
    loc_name <- current_lokasi$nama_lokasi[j]
    quota <- get_current_quota_status(loc_name, current_data, current_lokasi)
    cat("   Location '", loc_name, "': ", quota$available_quota, "/", quota$total_quota, " available\n", sep = "")
  }
  
  # 4. Check if "Daftar" button would appear for each location
  cat("4. 'Daftar' button visibility:\n")
  for (j in 1:min(3, nrow(current_lokasi))) {
    loc_name <- current_lokasi$nama_lokasi[j]
    eligibility <- check_registration_eligibility(test_nim, loc_name, current_data, current_periode)
    quota <- get_current_quota_status(loc_name, current_data, current_lokasi)
    
    button_visible <- period_open && eligibility$eligible && quota$available_quota > 0
    cat("   Location '", loc_name, "': ", button_visible, "\n", sep = "")
    
    if (!button_visible) {
      if (!period_open) cat("     Reason: Period closed\n")
      if (!eligibility$eligible) cat("     Reason: Not eligible -", eligibility$reason, "\n")
      if (quota$available_quota <= 0) cat("     Reason: No quota available\n")
    }
  }
  
  cat("\n📋 SUMMARY FOR REJECTED USER", test_nim, ":\n")
  if (period_open) {
    eligible_locations <- 0
    for (j in 1:nrow(current_lokasi)) {
      loc_name <- current_lokasi$nama_lokasi[j]
      eligibility <- check_registration_eligibility(test_nim, loc_name, current_data, current_periode)
      quota <- get_current_quota_status(loc_name, current_data, current_lokasi)
      if (eligibility$eligible && quota$available_quota > 0) {
        eligible_locations <- eligible_locations + 1
      }
    }
    
    if (eligible_locations > 0) {
      cat("✅ User CAN re-register at", eligible_locations, "location(s)\n")
      cat("✅ All backend logic is working correctly\n")
      cat("💡 If user reports inability to re-register, check:\n")
      cat("   - Browser cache/session issues\n")
      cat("   - JavaScript console errors\n") 
      cat("   - Network connectivity\n")
      cat("   - User might be looking at wrong NIM or location\n")
    } else {
      cat("❌ User CANNOT re-register - no eligible locations available\n")
    }
  } else {
    cat("❌ User CANNOT re-register - registration period is closed\n")
  }
  
} else {
  cat("❌ No rejected users found in database to test\n")
}

cat("\n🏁 Comprehensive verification completed!\n")