# Dev-Labsos Development Environment Setup

This guide helps you create a development version of the Labsos application called "dev-labsos" for testing purposes on your Shiny Server.

## Overview

- **Production App**: `/srv/shiny-server/labsos/` → http://103.103.20.96:3838/labsos/
- **Development App**: `/srv/shiny-server/dev-labsos/` → http://103.103.20.96:3838/dev-labsos/

## Quick Setup Steps

### 1. Connect to Your Shiny Server

```bash
# Access server via web interface
# URL: http://103.103.20.96:8787/
# Username: emir
# Password: TamtechA12A
```

### 2. Create Development Directory

Open terminal and create the dev environment:

```bash
# Switch to root
sudo su

# Create dev-labsos directory
sudo mkdir -p /srv/shiny-server/dev-labsos

# Copy existing labsos app to dev version (if it exists)
sudo cp -R /srv/shiny-server/labsos/* /srv/shiny-server/dev-labsos/

# OR create empty directory structure if labsos doesn't exist yet
sudo mkdir -p /srv/shiny-server/dev-labsos/fn
sudo mkdir -p /srv/shiny-server/dev-labsos/www/documents
sudo mkdir -p /srv/shiny-server/dev-labsos/www/images
sudo mkdir -p /srv/shiny-server/dev-labsos/data

# Set proper ownership
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/
```

### 3. Upload Your Local "dev-labsos" Code

You have several options to upload your local dev-labsos folder:

#### Option A: Via RStudio Server File Browser

1. In RStudio Server, navigate to Files tab
2. Go to `/srv/shiny-server/dev-labsos/`
3. Upload your local files:
   - `global.R`
   - `server.R`  
   - `ui.R`
   - `fn/` folder with all R files
   - `www/` folder
   - Other project files

#### Option B: Via Command Line (if files already on server)

```bash
# If your local dev-labsos is in ~/rnd/dev-labsos/
sudo cp -R ~/rnd/dev-labsos/* /srv/shiny-server/dev-labsos/

# Set ownership
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/
```

#### Option C: SCP Upload from Your Local Machine

```bash
# From your local machine, upload dev-labsos folder
scp -r /path/to/your/dev-labsos/* emir@103.103.20.96:/tmp/dev-labsos-upload/

# Then on server, move to correct location
sudo mv /tmp/dev-labsos-upload/* /srv/shiny-server/dev-labsos/
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/
```

### 4. Verify Required Packages

Ensure all R packages are installed for the shiny user:

```bash
# Switch to shiny user
su - shiny

# Start R
R
```

```r
# Install required packages (if not already installed)
install.packages(c(
  "shiny", 
  "shinydashboard", 
  "DT", 
  "dplyr", 
  "shinyjs", 
  "mongolite"
), repos="https://cran.rstudio.com/")

# Exit R
q()
```

### 5. Configure Development Settings

Create a development-specific configuration in your dev-labsos app:

#### Option A: Modify global.R for Development

Add development flags to your `global.R`:

```r
# Development environment flag
DEV_MODE <- TRUE

# Development database (optional - use separate MongoDB database)
if (DEV_MODE) {
  # You can modify mongodb_config.R to use a different database
  # or keep using the same one for testing
}
```

#### Option B: Create dev-specific MongoDB database

If you want separate data for development, modify `fn/mongodb_config.R`:

```r
# MongoDB Configuration - Development Version
MONGODB_CONFIG <- list(
  username = "labsos",
  password = "T5CmgVtU2mV4K01t",
  host = "cluster0.ejeivru.mongodb.net",
  database = "labsos_dev",  # Different database for development
  connection_string = "mongodb+srv://labsos:T5CmgVtU2mV4K01t@cluster0.ejeivru.mongodb.net/labsos_dev?retryWrites=true&w=majority"
)
```

### 6. Set Proper Permissions

```bash
# Set ownership and permissions
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/
sudo find /srv/shiny-server/dev-labsos/ -type d -exec chmod 755 {} \;
sudo find /srv/shiny-server/dev-labsos/ -type f -exec chmod 644 {} \;

# Make upload directories writable
sudo chmod 777 /srv/shiny-server/dev-labsos/www/documents/
sudo chmod 777 /srv/shiny-server/dev-labsos/www/images/
```

### 7. Test the Development App

```bash
# Switch to shiny user
su - shiny

# Navigate to dev app directory
cd /srv/shiny-server/dev-labsos/

# Test loading
R -e "source('global.R')"
```

Expected output:
```
Data successfully loaded from MongoDB
Successfully initialized MongoDB data layer
```

### 8. Restart Shiny Server

```bash
# Switch back to root
sudo su

# Restart Shiny Server
sudo systemctl restart shiny-server

# Check status
sudo systemctl status shiny-server
```

### 9. Access Development App

Your development app will be available at:

**http://103.103.20.96:3838/dev-labsos/**

## Development Workflow

### Making Changes

1. **Edit code locally** in your dev-labsos folder
2. **Upload changes** via RStudio Server file browser or SCP
3. **Test changes** at http://103.103.20.96:3838/dev-labsos/
4. **Check logs** if issues occur: `sudo tail -f /var/log/shiny-server.log`

### Sync with Production

When development testing is successful:

```bash
# Copy dev changes to production (be careful!)
sudo cp -R /srv/shiny-server/dev-labsos/* /srv/shiny-server/labsos/
sudo chown -R shiny:shiny /srv/shiny-server/labsos/
sudo systemctl restart shiny-server
```

## File Structure

Your dev-labsos should have this structure:

```
/srv/shiny-server/dev-labsos/
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
├── www/
│   ├── documents/
│   └── images/
├── data/                 # RDS fallback files
├── README.md
├── CLAUDE.md
└── DEPLOYMENT.md
```

## Troubleshooting Development App

### Check Logs

```bash
# View all Shiny Server logs
sudo tail -f /var/log/shiny-server.log

# Look for dev-labsos specific entries
sudo grep -i "dev-labsos" /var/log/shiny-server.log
```

### Common Development Issues

#### 1. App Not Loading

```bash
# Check if files exist
ls -la /srv/shiny-server/dev-labsos/

# Test R loading
su - shiny
cd /srv/shiny-server/dev-labsos/
R -e "source('global.R')"
```

#### 2. Permission Issues

```bash
# Fix ownership
sudo chown -R shiny:shiny /srv/shiny-server/dev-labsos/

# Fix permissions
sudo chmod -R 755 /srv/shiny-server/dev-labsos/
```

#### 3. Package Issues

```bash
# Install missing packages as shiny user
su - shiny
R
install.packages("missing_package", repos="https://cran.rstudio.com/")
q()
```

### Development Testing Checklist

- [ ] All files uploaded correctly
- [ ] Permissions set properly (`shiny:shiny` ownership)
- [ ] Required packages installed
- [ ] MongoDB connection working
- [ ] App loads without errors
- [ ] Admin login functional
- [ ] File uploads working
- [ ] All major features accessible

## Environment Comparison

| Feature | Production (labsos) | Development (dev-labsos) |
|---------|-------------------|--------------------------|
| **URL** | `/labsos/` | `/dev-labsos/` |
| **Database** | `labsos` | `labsos` or `labsos_dev` |
| **Purpose** | Live application | Testing & development |
| **Updates** | Stable releases | Frequent changes |
| **Data** | Production data | Test data |

## Benefits of Development Environment

1. **Safe Testing**: Test changes without affecting production
2. **Rapid Development**: Quick iterations and testing
3. **Debugging**: Easier to debug in isolated environment  
4. **Feature Testing**: Test new features before production deployment
5. **Training**: Safe environment for user training

## Next Steps

1. Set up the dev-labsos directory
2. Upload your local dev-labsos code
3. Test the development app
4. Use it for development and testing
5. Promote stable changes to production when ready

**Development URL**: http://103.103.20.96:3838/dev-labsos/
**Production URL**: http://103.103.20.96:3838/labsos/