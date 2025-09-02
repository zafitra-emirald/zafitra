# Rollback all pendaftaran_data status to "Diajukan" and clear rejection reasons

source("global.R")

cat("🔄 Rolling back all pendaftaran_data status to 'Diajukan'...\n")
cat("======================================================\n")

initialize_data_layer()

# Get current data to see what needs to be rolled back
current_data <- refresh_pendaftaran_data()

cat("📊 Current status distribution:\n")
status_summary <- table(current_data$status_pendaftaran)
print(status_summary)

cat("\n🔄 Starting rollback process...\n")

# Connect to MongoDB
pendaftaran_conn <- get_mongo_connection("pendaftaran")

# Update all records to have status "Diajukan" and empty rejection reason
update_result <- pendaftaran_conn$update(
  query = '{}',  # Match all documents
  update = '{"$set": {"status_pendaftaran": "Diajukan", "alasan_penolakan": ""}}',
  multiple = TRUE  # Update all matching documents
)

cat("📊 Update result:\n")
cat("  Modified count:", update_result$modifiedCount, "\n")
cat("  Matched count:", update_result$matchedCount, "\n")

# Verify the rollback
verification_data <- pendaftaran_conn$find()
pendaftaran_conn$disconnect()

cat("\n📊 Status distribution after rollback:\n")
final_status_summary <- table(verification_data$status_pendaftaran)
print(final_status_summary)

# Check for any remaining rejection reasons
remaining_reasons <- sum(verification_data$alasan_penolakan != "" & !is.na(verification_data$alasan_penolakan))
cat("\nRecords with rejection reasons remaining:", remaining_reasons, "\n")

if (all(verification_data$status_pendaftaran == "Diajukan") && remaining_reasons == 0) {
  cat("\n✅ ROLLBACK SUCCESSFUL!\n")
  cat("✅ All registrations now have status 'Diajukan'\n")
  cat("✅ All rejection reasons cleared\n")
} else {
  cat("\n❌ ROLLBACK INCOMPLETE!\n")
  if (!all(verification_data$status_pendaftaran == "Diajukan")) {
    cat("❌ Some records still have non-'Diajukan' status\n")
  }
  if (remaining_reasons > 0) {
    cat("❌ Some records still have rejection reasons\n")
  }
}

cat("\n🏁 Rollback process completed!\n")