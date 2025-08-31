# run_app_clean.R
# Runs the Labsos application with correct MongoDB configuration
# This script ensures old environment variables don't interfere

# Clear any old MongoDB environment variables that might conflict
Sys.unsetenv("MONGODB_USERNAME")
Sys.unsetenv("MONGODB_PASSWORD") 
Sys.unsetenv("MONGODB_HOST")
Sys.unsetenv("MONGODB_DATABASE")

cat("Cleared old MongoDB environment variables\n")
cat("Using default configuration from code:\n")
cat("- Database: labsos-v1\n")
cat("- Username: zafitraem_db_user\n") 
cat("- Host: cluster0.ccqv2dn.mongodb.net\n\n")

# Start the application
cat("Starting Labsos Information System...\n")
cat("MongoDB Atlas integration with RDS fallback enabled\n")
cat("Access the application at: http://localhost:3838\n")
cat("Admin credentials: adminlabsos / labsosunu4869\n")
cat("Press Ctrl+C to stop the application\n\n")

# Run the app
shiny::runApp(host = "0.0.0.0", port = 3838)