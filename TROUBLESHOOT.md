# Shiny App Troubleshooting Guide

## "Page not found" Error Solutions

When you get "Page not found" error, it usually means the Shiny app failed to start. Here's how to diagnose and fix it:

## Step 1: Check Shiny Server Status

Connect to your server and check if Shiny Server is running:

```bash
# Connect to server: http://103.103.20.96:8787/
# Username: emir, Password: TamtechA12A

# In terminal:
sudo systemctl status shiny-server
```

Expected output should show "active (running)". If not:
```bash
sudo systemctl start shiny-server
sudo systemctl enable shiny-server
```

## Step 2: Verify Directory Structure

Check if your app directory exists and has the required files:

```bash
# Check if directory exists
ls -la /srv/shiny-server/

# Should show folders like: labsos/ or dev-labsos/
# Check your specific app directory
ls -la /srv/shiny-server/dev-labsos/
```

Required files for a Shiny app:
- ✅ `server.R` (required)
- ✅ `ui.R` (required)  
- ✅ `global.R` (optional but you have it)

If files are missing:
```bash
# Create basic structure
sudo mkdir -p /srv/shiny-server/dev-labsos
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/
```

## Step 3: Check Application Logs

This is the most important step - check what error is preventing the app from starting:

```bash
# View real-time Shiny Server logs
sudo tail -f /var/log/shiny-server.log

# Or check recent logs
sudo tail -100 /var/log/shiny-server.log

# Look for your specific app
sudo grep -i "dev-labsos\|labsos" /var/log/shiny-server.log
```

## Step 4: Test R Script Loading

Test if your app can load without errors:

```bash
# Switch to shiny user
sudo su
su - shiny

# Navigate to your app directory
cd /srv/shiny-server/dev-labsos/

# Test loading the global.R file
R -e "source('global.R')"
```

Common errors you might see:
- **Package not found**: Install missing packages
- **File not found**: Check if all files are uploaded
- **Permission denied**: Fix ownership/permissions
- **MongoDB connection failed**: Check internet/credentials

## Step 5: Fix Common Issues

### Issue A: Missing Packages

If logs show package errors:
```bash
su - shiny
R
```

Install missing packages:
```r
# Core packages
install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "shinyjs", "mongolite"), repos="https://cran.rstudio.com/")

# Check if packages load
library(shiny)
library(shinydashboard) 
library(mongolite)

q()  # Exit R
```

### Issue B: File Permissions

If logs show permission errors:
```bash
# Fix ownership
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/

# Fix directory permissions
sudo find /srv/shiny-server/dev-labsos/ -type d -exec chmod 755 {} \;

# Fix file permissions
sudo find /srv/shiny-server/dev-labsos/ -type f -exec chmod 644 {} \;

# Make upload directories writable
sudo chmod 777 /srv/shiny-server/dev-labsos/www/documents/
sudo chmod 777 /srv/shiny-server/dev-labsos/www/images/
```

### Issue C: Missing Files

Ensure you have the minimum required files:

```bash
# Check required files exist
ls -la /srv/shiny-server/dev-labsos/server.R
ls -la /srv/shiny-server/dev-labsos/ui.R
ls -la /srv/shiny-server/dev-labsos/global.R
```

If missing, create a basic test app:

**Basic server.R:**
```r
function(input, output) {
  output$test <- renderText("Hello from dev-labsos!")
}
```

**Basic ui.R:**
```r
fluidPage(
  titlePanel("Dev Labsos Test"),
  textOutput("test")
)
```

### Issue D: MongoDB Connection Issues

If logs show MongoDB errors, create a simplified version for testing:

**Modify global.R to disable MongoDB temporarily:**
```r
# Comment out MongoDB initialization
# load_or_create_data_mongo()

# Use RDS fallback instead
load_or_create_data()
```

## Step 6: Create Minimal Test App

If the full app isn't working, create a minimal test first:

```bash
# Create simple test app
sudo mkdir -p /srv/shiny-server/test-app
sudo chown -R shiny:shiny /srv/shiny-server/test-app/
```

Create simple files:

**test-app/ui.R:**
```r
library(shiny)
fluidPage(
  titlePanel("Test App"),
  h3("If you see this, Shiny Server is working!"),
  p("Server time:", textOutput("time"))
)
```

**test-app/server.R:**
```r
library(shiny)
function(input, output) {
  output$time <- renderText({
    as.character(Sys.time())
  })
}
```

Test access: http://103.103.20.96:3838/test-app/

## Step 7: Restart Services

After making changes:
```bash
# Restart Shiny Server
sudo systemctl restart shiny-server

# Check status
sudo systemctl status shiny-server

# If needed, restart system
sudo reboot
```

## Step 8: Check URLs

Make sure you're using the correct URL format:

- ✅ Correct: `http://103.103.20.96:3838/dev-labsos/`
- ❌ Wrong: `http://103.103.20.96:3838/dev-labsos` (missing trailing slash)
- ❌ Wrong: `http://103.103.20.96:8787/dev-labsos/` (wrong port)

## Diagnostic Commands Summary

Run these commands to gather diagnostic information:

```bash
# 1. Check Shiny Server status
sudo systemctl status shiny-server

# 2. Check if directory exists
ls -la /srv/shiny-server/dev-labsos/

# 3. Check file ownership
ls -la /srv/shiny-server/dev-labsos/server.R

# 4. View recent logs
sudo tail -50 /var/log/shiny-server.log

# 5. Test R script loading
su - shiny -c "cd /srv/shiny-server/dev-labsos && R -e 'source(\"global.R\")'"

# 6. Check port 3838 is listening
sudo netstat -tulpn | grep :3838
```

## Quick Recovery Steps

If nothing works, try this complete reset:

```bash
# 1. Stop Shiny Server
sudo systemctl stop shiny-server

# 2. Remove problematic app
sudo rm -rf /srv/shiny-server/dev-labsos/

# 3. Create fresh directory
sudo mkdir -p /srv/shiny-server/dev-labsos
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/

# 4. Upload files again (via RStudio Server file browser)

# 5. Set permissions
sudo chmod -R 755 /srv/shiny-server/dev-labsos/

# 6. Start Shiny Server
sudo systemctl start shiny-server

# 7. Check logs
sudo tail -f /var/log/shiny-server.log
```

## Success Checklist

✅ Shiny Server service is running  
✅ App directory exists with proper ownership  
✅ Required files (server.R, ui.R) are present  
✅ All R packages are installed  
✅ No errors in Shiny Server logs  
✅ Correct URL format used  
✅ App loads successfully  

## Next Steps

1. **Run diagnostic commands** above
2. **Check logs** for specific error messages  
3. **Fix identified issues** (packages, permissions, files)
4. **Test with minimal app** first if needed
5. **Restart services** after changes
6. **Access your app** at correct URL

**Remember**: The logs at `/var/log/shiny-server.log` will tell you exactly what's wrong!