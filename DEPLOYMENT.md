# Labsos Shiny Server Deployment Guide

This guide provides step-by-step instructions for deploying the Labsos Information System to your cloud Shiny Server.

## Server Information

- **Server URL**: http://103.103.20.96:8787/
- **SSH User**: `emir`
- **SSH Password**: `TamtechA12A`
- **Shiny Server Path**: `/srv/shiny-server/`
- **Log Location**: `/var/log/shiny-server/`

## Prerequisites

- Access to the cloud Shiny Server
- Local copy of the Labsos project
- MongoDB Atlas credentials configured in the application

## Deployment Steps

### 1. Connect to Shiny Server

Access your cloud Shiny Server through the web interface:

```
URL: http://103.103.20.96:8787/
Username: emir
Password: TamtechA12A
```

### 2. Open Terminal and Switch to Root

In the RStudio Server interface, open a terminal and switch to root user:

```bash
# Switch to root user
sudo su

# Then switch to the shiny user
su - shiny
```

### 3. Install Required R Packages

Install all necessary R packages as the shiny user:

```bash
# Start R as shiny user
R
```

Within the R console, install the required packages:

```r
# Core Shiny packages
install.packages(c(
  "shiny", 
  "shinydashboard", 
  "DT", 
  "dplyr", 
  "shinyjs", 
  "mongolite"
), repos="https://cran.rstudio.com/")

# Additional utility packages
install.packages(c(
  "tidyverse", 
  "jsonlite", 
  "httr", 
  "promises", 
  "future"
), repos="https://cran.rstudio.com/")

# Optional packages (if needed)
install.packages(c(
  "leaflet", 
  "openssl", 
  "lubridate",
  "echarts4r",
  "openxlsx"
), repos="https://cran.rstudio.com/")

# Exit R when done
q()  # Answer "n" when asked to save workspace
```

### 4. Create Application Directory

Create the directory structure for your application:

```bash
# Switch back to root if needed
sudo su

# Create the labsos directory on Shiny Server
sudo mkdir -p /srv/shiny-server/labsos

# Set proper permissions
sudo chown -R shiny:shiny /srv/shiny-server/labsos/
```

### 5. Upload Application Files

You have several options to upload your application files:

#### Option A: Upload via RStudio Server Interface
1. Use the RStudio Server file browser
2. Navigate to `/srv/shiny-server/labsos/`
3. Upload your project files (global.R, server.R, ui.R, fn/ folder, etc.)

#### Option B: Copy from existing directory (if files already on server)
```bash
# If your files are in ~/rnd/labsos/, copy them:
sudo cp -R ~/rnd/labsos/* /srv/shiny-server/labsos/

# Change ownership to shiny user
sudo chown -R shiny:shiny /srv/shiny-server/labsos/
```

#### Option C: Use SCP/SFTP from local machine
```bash
# From your local machine, copy files to server
scp -r /path/to/your/labsos/* emir@103.103.20.96:/tmp/labsos/

# Then on server, move files to correct location
sudo mv /tmp/labsos/* /srv/shiny-server/labsos/
sudo chown -R shiny:shiny /srv/shiny-server/labsos/
```

### 6. Verify File Structure

Ensure your application has the correct file structure:

```bash
# Check the directory structure
ls -la /srv/shiny-server/labsos/
```

Expected structure:
```
/srv/shiny-server/labsos/
├── global.R
├── server.R
├── ui.R
├── run_app.R
├── migrate_rds_to_mongodb.R
├── fn/
│   ├── mongodb_config.R
│   ├── load_or_create_data_mongo.R
│   ├── save_*_data_mongo.R
│   ├── data_layer_wrapper.R
│   ├── backup_stubs.R
│   └── *.R
├── data/                 # RDS backup files (fallback)
├── www/
│   ├── documents/
│   └── images/
├── Requirement/
├── README.md
├── CLAUDE.md
└── DEPLOYMENT.md
```

### 7. Set Proper Permissions

Ensure all files have correct ownership and permissions:

```bash
# Set ownership to shiny user and group
sudo chown -R shiny:shiny /srv/shiny-server/labsos/

# Set proper permissions for directories
sudo find /srv/shiny-server/labsos/ -type d -exec chmod 755 {} \;

# Set proper permissions for files
sudo find /srv/shiny-server/labsos/ -type f -exec chmod 644 {} \;

# Make sure www directories are writable (for file uploads)
sudo chmod -R 755 /srv/shiny-server/labsos/www/
sudo mkdir -p /srv/shiny-server/labsos/www/documents/
sudo mkdir -p /srv/shiny-server/labsos/www/images/
sudo chmod 777 /srv/shiny-server/labsos/www/documents/
sudo chmod 777 /srv/shiny-server/labsos/www/images/
```

### 8. Test Application Locally

Before restarting the server, test if the app can load:

```bash
# Switch to shiny user
su - shiny

# Navigate to app directory
cd /srv/shiny-server/labsos/

# Test loading the application
R -e "source('global.R')"
```

You should see:
```
Data successfully loaded from MongoDB
Successfully initialized MongoDB data layer
```

### 9. Restart Shiny Server

Restart the Shiny Server to apply changes:

```bash
# Switch back to root
sudo su

# Restart Shiny Server
sudo systemctl restart shiny-server

# Check if service is running
sudo systemctl status shiny-server
```

### 10. Access Your Application

Your application should now be available at:

```
http://103.103.20.96:3838/labsos/
```

**Admin Login Credentials:**
- Username: `adminlabsos`
- Password: `labsosunu4869`

## Troubleshooting

### Check Application Logs

If the application doesn't load, check the Shiny Server logs:

```bash
# View recent Shiny Server logs
sudo tail -f /var/log/shiny-server.log

# Check application-specific logs
sudo ls -la /var/log/shiny-server/
sudo tail -f /var/log/shiny-server/labsos-*.log
```

### Common Issues and Solutions

#### 1. Package Not Found Errors
```bash
# Install missing packages as shiny user
su - shiny
R
# Install the missing package
install.packages("package_name", repos="https://cran.rstudio.com/")
q()
```

#### 2. Permission Errors
```bash
# Fix ownership
sudo chown -R shiny:shiny /srv/shiny-server/labsos/

# Fix directory permissions
sudo chmod -R 755 /srv/shiny-server/labsos/
```

#### 3. MongoDB Connection Issues
- Check internet connectivity on the server
- Verify MongoDB Atlas credentials in the application
- The application will automatically fallback to RDS files if MongoDB is unavailable

#### 4. File Upload Issues
```bash
# Ensure www directories are writable
sudo chmod 777 /srv/shiny-server/labsos/www/documents/
sudo chmod 777 /srv/shiny-server/labsos/www/images/
```

#### 5. Application Not Starting
```bash
# Check if required files exist
ls -la /srv/shiny-server/labsos/global.R
ls -la /srv/shiny-server/labsos/server.R
ls -la /srv/shiny-server/labsos/ui.R

# Test R script loading
su - shiny
cd /srv/shiny-server/labsos/
R -e "source('global.R')"
```

### View Detailed Logs

```bash
# Real-time log monitoring
sudo tail -f /var/log/shiny-server.log

# Check for specific errors
sudo grep -i error /var/log/shiny-server.log

# Check for application-specific logs
sudo find /var/log/shiny-server/ -name "*labsos*" -exec tail {} \;
```

### Restart Services if Needed

```bash
# Restart Shiny Server
sudo systemctl restart shiny-server

# Check service status
sudo systemctl status shiny-server

# If needed, restart the entire system
sudo reboot
```

## Configuration Notes

### Shiny Server Configuration

The main configuration file is located at `/etc/shiny-server/shiny-server.conf`. Typical configuration:

```
server {
  listen 3838;
  
  location / {
    site_dir /srv/shiny-server;
    log_dir /var/log/shiny-server;
    directory_index on;
  }
}
```

### Memory and Performance

For better performance with MongoDB operations:

```bash
# Check available memory
free -h

# Monitor application performance
htop
```

## Maintenance

### Regular Updates

1. **Update R packages periodically:**
   ```bash
   su - shiny
   R
   update.packages(repos="https://cran.rstudio.com/")
   q()
   ```

2. **Monitor application logs regularly:**
   ```bash
   sudo tail -f /var/log/shiny-server.log
   ```

3. **Backup important data** (though MongoDB Atlas provides cloud backup)

### Data Migration

If you need to migrate existing RDS data to MongoDB on the server:

```bash
su - shiny
cd /srv/shiny-server/labsos/
R -e "source('migrate_rds_to_mongodb.R')"
```

## Security Considerations

1. **File Permissions**: Ensure only necessary files are world-readable
2. **MongoDB Credentials**: Keep credentials secure and consider using environment variables
3. **File Uploads**: Monitor the www/documents/ directory for security
4. **Regular Updates**: Keep R packages and system updated

## Support

For issues:
1. Check logs in `/var/log/shiny-server/`
2. Verify all packages are installed correctly
3. Test MongoDB connectivity
4. Check file permissions and ownership
5. Restart Shiny Server service

**Success URL**: http://103.103.20.96:3838/labsos/