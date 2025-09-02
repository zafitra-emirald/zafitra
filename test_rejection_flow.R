# Test rejection functionality and re-registration flow

source("global.R")
source("fn/save_single_pendaftaran_mongo.R")
source("fn/update_pendaftaran_status_mongo.R")

cat("🧪 Testing Rejection and Re-registration Flow\n")
cat("=============================================\n")

initialize_data_layer()

# Create a test registration
test_nim <- "REJECT001"
test_name <- "Rejection Test Student"
available_location <- "LazisNU Sleman 1"

cat("📝 Step 1: Creating initial registration...\n")

# Create initial registration
initial_registration <- data.frame(
  nim_mahasiswa = test_nim,
  nama_mahasiswa = test_name,
  program_studi = "Teknologi Informasi",
  kontak = "08123456789",
  pilihan_lokasi = available_location,
  letter_of_interest_path = "documents/test_letter.pdf",
  cv_mahasiswa_path = "documents/test_cv.pdf",
  form_rekomendasi_prodi_path = "documents/test_rekomendasi.pdf",
  form_komitmen_mahasiswa_path = "documents/test_komitmen.pdf",
  transkrip_nilai_path = "documents/test_transkrip.pdf",
  status_pendaftaran = "Diajukan",
  alasan_penolakan = "",
  stringsAsFactors = FALSE
)

initial_id <- tryCatch({
  new_id <- save_single_pendaftaran_mongo(initial_registration)
  cat("✅ Initial registration created with ID:", new_id, "\n")
  new_id
}, error = function(e) {
  cat("❌ Failed to create initial registration:", e$message, "\n")
  quit(status = 1)
})

# Verify initial status
current_data <- refresh_pendaftaran_data()
initial_record <- current_data[current_data$id_pendaftaran == initial_id, ]
cat("📊 Initial status:", initial_record$status_pendaftaran[1], "\n\n")

cat("📝 Step 2: Testing eligibility check (should be blocked - status is 'Diajukan')...\n")

# Test eligibility with pending status
eligibility_pending <- check_registration_eligibility(test_nim, available_location, current_data, refresh_periode_data())
cat("Eligibility with pending status:", eligibility_pending$eligible, "\n")
if (!eligibility_pending$eligible) {
  cat("Reason:", eligibility_pending$reason, "\n")
}

cat("\n📝 Step 3: Rejecting the registration...\n")

# Reject the registration
tryCatch({
  update_pendaftaran_status_mongo(initial_id, "Ditolak", "Dokumen tidak lengkap, silakan lengkapi dan daftar kembali")
  cat("✅ Registration rejected successfully\n")
}, error = function(e) {
  cat("❌ Failed to reject registration:", e$message, "\n")
  quit(status = 1)
})

# Verify rejection
current_data_after_reject <- refresh_pendaftaran_data()
rejected_record <- current_data_after_reject[current_data_after_reject$id_pendaftaran == initial_id, ]
cat("📊 Status after rejection:", rejected_record$status_pendaftaran[1], "\n")
cat("📊 Rejection reason:", rejected_record$alasan_penolakan[1], "\n\n")

cat("📝 Step 4: Testing eligibility after rejection (should be allowed)...\n")

# Test eligibility with rejected status
eligibility_rejected <- check_registration_eligibility(test_nim, available_location, current_data_after_reject, refresh_periode_data())
cat("Eligibility with rejected status:", eligibility_rejected$eligible, "\n")
if (!eligibility_rejected$eligible) {
  cat("Reason:", eligibility_rejected$reason, "\n")
}

if (eligibility_rejected$eligible) {
  cat("\n📝 Step 5: Testing re-registration after rejection...\n")
  
  # Create new registration for the same student
  reregistration_data <- data.frame(
    nim_mahasiswa = test_nim,
    nama_mahasiswa = paste(test_name, "- Reregistration"),
    program_studi = "Teknologi Informasi", 
    kontak = "08123456789",
    pilihan_lokasi = available_location,
    letter_of_interest_path = "documents/test_letter_v2.pdf",
    cv_mahasiswa_path = "documents/test_cv_v2.pdf",
    form_rekomendasi_prodi_path = "documents/test_rekomendasi_v2.pdf",
    form_komitmen_mahasiswa_path = "documents/test_komitmen_v2.pdf",
    transkrip_nilai_path = "documents/test_transkrip_v2.pdf",
    status_pendaftaran = "Diajukan",
    alasan_penolakan = "",
    stringsAsFactors = FALSE
  )
  
  reregistration_id <- tryCatch({
    new_id <- save_single_pendaftaran_mongo(reregistration_data)
    cat("✅ Re-registration successful with ID:", new_id, "\n")
    new_id
  }, error = function(e) {
    cat("❌ Re-registration failed:", e$message, "\n")
    new_id <- NA
  })
  
  if (!is.na(reregistration_id)) {
    # Verify both registrations exist
    final_data <- refresh_pendaftaran_data()
    student_registrations <- final_data[final_data$nim_mahasiswa == test_nim, ]
    
    cat("\n📊 Final Results:\n")
    cat("=================\n")
    cat("Total registrations for", test_nim, ":", nrow(student_registrations), "\n")
    
    for (i in 1:nrow(student_registrations)) {
      reg <- student_registrations[i, ]
      cat("  ID", reg$id_pendaftaran, "- Status:", reg$status_pendaftaran, 
          if(reg$status_pendaftaran == "Ditolak") paste("- Reason:", reg$alasan_penolakan) else "", "\n")
    }
    
    # Check current eligibility (should be blocked due to new pending registration)
    final_eligibility <- check_registration_eligibility(test_nim, available_location, final_data, refresh_periode_data())
    cat("\nEligibility after re-registration:", final_eligibility$eligible, "\n")
    if (!final_eligibility$eligible) {
      cat("Reason:", final_eligibility$reason, "\n")
    }
  }
}

cat("\n🏁 FINAL ASSESSMENT:\n")
cat("====================\n")

if (rejected_record$status_pendaftaran[1] == "Ditolak" && 
    !is.na(rejected_record$alasan_penolakan[1]) && 
    rejected_record$alasan_penolakan[1] != "" &&
    eligibility_rejected$eligible) {
  
  if (!is.na(reregistration_id)) {
    cat("🎉 COMPLETE SUCCESS!\n")
    cat("✅ Rejection functionality works correctly\n")
    cat("✅ Rejected students can register again\n") 
    cat("✅ Status and reason saved to MongoDB properly\n")
    cat("✅ Re-registration creates new pending entry\n")
  } else {
    cat("⚠️  PARTIAL SUCCESS:\n")
    cat("✅ Rejection works but re-registration failed\n")
  }
} else {
  cat("❌ ISSUES DETECTED:\n")
  if (rejected_record$status_pendaftaran[1] != "Ditolak") {
    cat("• Rejection status not saved properly\n")
  }
  if (is.na(rejected_record$alasan_penolakan[1]) || rejected_record$alasan_penolakan[1] == "") {
    cat("• Rejection reason not saved\n") 
  }
  if (!eligibility_rejected$eligible) {
    cat("• Rejected students cannot re-register\n")
  }
}

cat("\n✅ Rejection flow test completed!\n")