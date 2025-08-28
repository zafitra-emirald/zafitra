# run_app.R
# Convenient script to run the Labsos Shiny application

# Enable auto-reload for development (comment out for production)
options(shiny.autoreload = TRUE)

# Enable reactlog for debugging (comment out for production)
# options(shiny.reactlog = TRUE)

# Run the application
cat("Starting Labsos Information System...\n")
cat("MongoDB Atlas integration with RDS fallback enabled\n")
cat("Access the application at: http://localhost:3838\n")
cat("Admin credentials: adminlabsos / labsosunu4869\n")
cat("Press Ctrl+C to stop the application\n\n")

# Start the app
shiny::runApp(
  port = 3838, 
  host = "0.0.0.0",  # Allow network access
  launch.browser = TRUE  # Auto-open browser
)