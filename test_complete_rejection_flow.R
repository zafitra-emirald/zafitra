# Test complete rejection and re-registration flow

source("global.R")

cat("🧪 Testing Complete Rejection and Re-registration Flow\n")
cat("=====================================================\n")

initialize_data_layer()

# Step 1: Create a test user registration
test_nim <- paste0("FLOW_TEST_", format(Sys.time(), "%Y%m%d_%H%M%S"))
current_lokasi <- refresh_lokasi_data()
test_location <- current_lokasi$nama_lokasi[1]
different_location <- current_lokasi$nama_lokasi[2]

cat("📝 Step 1: Creating initial registration for NIM:", test_nim, "\n")
cat("📝 Location:", test_location, "\n")

initial_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = "Complete Flow Test Student",
  program_studi = "Informatika",
  kontak = "08999888777",
  pilihan_lokasi = test_location,
  letter_of_interest_path = "documents/flow_test_letter.pdf",
  cv_mahasiswa_path = "documents/flow_test_cv.pdf",
  form_rekomendasi_prodi_path = "documents/flow_test_rekomendasi.pdf",
  form_komitmen_mahasiswa_path = "documents/flow_test_komitmen.pdf",
  transkrip_nilai_path = "documents/flow_test_transkrip.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

# Create initial registration using the queue system (like real users)
initial_registration_list <- as.list(initial_registration[1, ])

# Manually insert to avoid the save function issues we had earlier
pendaftaran_conn <- get_mongo_connection("pendaftaran")
existing_data <- pendaftaran_conn$find(fields = '{"id_pendaftaran": 1}')
new_id <- if (nrow(existing_data) == 0) 1 else max(existing_data$id_pendaftaran, na.rm = TRUE) + 1

initial_registration_list$id_pendaftaran <- as.integer(new_id)
initial_registration_list$timestamp <- as.character(Sys.time())

insert_result <- pendaftaran_conn$insert(initial_registration_list)
pendaftaran_conn$disconnect()

cat("✅ Initial registration created with ID:", new_id, "\n")

# Step 2: Reject the registration
cat("\n📝 Step 2: Rejecting the registration...\n")
update_pendaftaran_status_mongo(new_id, "Ditolak", "Test rejection - documents incomplete")

# Refresh data
updated_data <- refresh_pendaftaran_data()
rejected_record <- updated_data[updated_data$id_pendaftaran == new_id, ]
cat("📊 Status after rejection:", rejected_record$status_pendaftaran[1], "\n")

# Step 3: Test eligibility for re-registration at SAME location
cat("\n📝 Step 3: Testing re-registration eligibility at SAME location...\n")
same_location_eligibility <- check_registration_eligibility(test_nim, test_location, updated_data, refresh_periode_data())
cat("📊 Same location eligibility:", same_location_eligibility$eligible, "\n")
if (!same_location_eligibility$eligible) {
  cat("📊 Reason:", same_location_eligibility$reason, "\n")
}

# Step 4: Test eligibility for re-registration at DIFFERENT location  
cat("\n📝 Step 4: Testing re-registration eligibility at DIFFERENT location...\n")
different_location_eligibility <- check_registration_eligibility(test_nim, different_location, updated_data, refresh_periode_data())
cat("📊 Different location eligibility:", different_location_eligibility$eligible, "\n")
if (!different_location_eligibility$eligible) {
  cat("📊 Reason:", different_location_eligibility$reason, "\n")
}

# Step 5: Test quota status for both locations
cat("\n📝 Step 5: Checking quota status for both locations...\n")
quota_same <- get_current_quota_status(test_location, updated_data, current_lokasi)
quota_different <- get_current_quota_status(different_location, updated_data, current_lokasi)

cat("📊 Same location quota:", quota_same$available_quota, "/", quota_same$total_quota, "\n")
cat("📊 Different location quota:", quota_different$available_quota, "/", quota_different$total_quota, "\n")

# Step 6: Simulate actual re-registration attempt
if (same_location_eligibility$eligible && quota_same$available_quota > 0) {
  cat("\n📝 Step 6: Simulating re-registration at same location...\n")
  
  reregistration_data <- data.frame(
    nim_mahasiswa = test_nim,
    nama_mahasiswa = "Complete Flow Test Student - Reregistration",
    program_studi = "Informatika",
    kontak = "08999888777", 
    pilihan_lokasi = test_location,
    letter_of_interest_path = "documents/flow_test_letter_v2.pdf",
    cv_mahasiswa_path = "documents/flow_test_cv_v2.pdf",
    form_rekomendasi_prodi_path = "documents/flow_test_rekomendasi_v2.pdf",
    form_komitmen_mahasiswa_path = "documents/flow_test_komitmen_v2.pdf",
    transkrip_nilai_path = "documents/flow_test_transkrip_v2.pdf",
    status_pendaftaran = "Diajukan",
    alasan_penolakan = "",
    stringsAsFactors = FALSE
  )
  
  # Try to insert the re-registration
  reregistration_list <- as.list(reregistration_data[1, ])
  reregistration_list$id_pendaftaran <- as.integer(new_id + 1000)  # Use different ID
  reregistration_list$timestamp <- as.character(Sys.time())
  
  pendaftaran_conn <- get_mongo_connection("pendaftaran")
  reregister_result <- tryCatch({
    pendaftaran_conn$insert(reregistration_list)
    pendaftaran_conn$disconnect()
    cat("✅ Re-registration successful!\n")
    TRUE
  }, error = function(e) {
    pendaftaran_conn$disconnect()
    cat("❌ Re-registration failed:", e$message, "\n")
    FALSE
  })
  
  if (reregister_result) {
    # Verify both registrations exist
    final_data <- refresh_pendaftaran_data()
    user_final_regs <- final_data[final_data$nim_mahasiswa == test_nim, ]
    
    cat("📊 Final registrations for user:\n")
    for (i in 1:nrow(user_final_regs)) {
      reg <- user_final_regs[i, ]
      cat("  ID:", reg$id_pendaftaran, "- Status:", reg$status_pendaftaran, "- Location:", reg$pilihan_lokasi, "\n")
    }
    
    # Clean up both registrations
    cat("\n🧹 Cleaning up test registrations...\n")
    pendaftaran_conn <- get_mongo_connection("pendaftaran")
    pendaftaran_conn$remove(paste0('{"nim_mahasiswa": "', test_nim, '"}'))
    pendaftaran_conn$disconnect()
    cat("🗑️ Test registrations cleaned up\n")
  }
  
} else {
  cat("❌ Re-registration would be blocked\n")
  if (!same_location_eligibility$eligible) {
    cat("  Reason: Eligibility -", same_location_eligibility$reason, "\n")
  }
  if (quota_same$available_quota <= 0) {
    cat("  Reason: No quota available\n")
  }
  
  # Clean up initial registration
  cat("\n🧹 Cleaning up initial test registration...\n")
  pendaftaran_conn <- get_mongo_connection("pendaftaran")
  pendaftaran_conn$remove(paste0('{"id_pendaftaran": ', as.integer(new_id), '}'))
  pendaftaran_conn$disconnect()
  cat("🗑️ Initial test registration cleaned up\n")
}

cat("\n🏁 Complete flow test finished!\n")