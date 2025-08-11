# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Labsos (Laboratorium Sosial) Information System** built with R Shiny. It's a web application for managing social laboratory programs where students can register for community service locations. The system includes both student-facing registration features and admin management capabilities.

## Key Technologies & Dependencies

- **R Shiny**: Main web framework using `shiny`, `shinydashboard`
- **Data handling**: `DT` (DataTables), `dplyr` for data manipulation
- **UI enhancement**: `shinyjs` for JavaScript functionality
- **Data storage**: RDS files for persistent storage (file-based, no database)

## Project Structure

The repository contains two versions:
- **Root level**: `global.R`, `ui.R`, `server.R` (main application)
- **labsosv4/**: Subdirectory with version 4 files (appears to be a duplicate/version)

### Core Architecture

1. **global.R**: Global configuration, constants, data loading/saving functions, authentication
2. **ui.R**: Complete UI definition with custom CSS, modals, dashboard layout
3. **server.R**: Server-side logic with reactive values, event handling, CRUD operations

### Data Models

The system manages four main data entities stored as RDS files:
- **kategori_data.rds**: Categories (Pendidikan, Kesehatan, Teknologi)
- **periode_data.rds**: Registration periods with date ranges and status
- **lokasi_data.rds**: Locations with descriptions, quotas, and program studi mappings
- **pendaftaran_data.rds**: Student registrations with documents and status

### Key Functions & Modules

1. **Authentication**: Simple admin login (admin/admin123)
2. **Master Data Management**: CRUD operations for categories, periods, locations
3. **Student Registration**: Multi-step registration with document uploads
4. **Data Persistence**: File-based storage with automatic data loading/saving

## Development Commands

This is an R Shiny application. Common commands:

```r
# Run the application
shiny::runApp()

# Or run from specific directory
shiny::runApp("labsosv4/")

# Install required packages if missing
install.packages(c("shiny", "shinydashboard", "DT", "dplyr", "shinyjs"))
```

## Code Patterns & Architecture

### Reactive Pattern
- Uses `reactiveValues()` for state management
- `observeEvent()` for handling user interactions
- `renderUI()`, `renderDataTable()` for dynamic content

### Data Flow
1. **Initialization**: `load_or_create_data()` creates default data if files don't exist
2. **CRUD Operations**: Add/Edit/Delete functions with validation
3. **File Storage**: Automatic saving to RDS files in `data/` directory
4. **File Uploads**: Documents saved to `www/documents/`, images to `www/images/`

### UI Architecture
- **Dashboard Layout**: Two-panel sidebar with conditional menus
- **Modal System**: Custom modal dialogs for registration and confirmations
- **Card-based Design**: Location cards with hover effects and responsive layout
- **Custom CSS**: Extensive styling for professional appearance

### Security & Validation
- Basic admin authentication (hardcoded credentials)
- File upload validation (PDF documents, image formats)
- Registration period validation
- Duplicate registration prevention
- Category usage checking before deletion

## Important Constants & Configuration

- **Program Studi Options**: Fixed list of 11 academic programs in `global.R:17-29`
- **Admin Credentials**: Username "admin", Password "admin123" in `global.R:32-36`
- **File Paths**: 
  - Data: `data/*.rds`
  - Documents: `www/documents/`
  - Images: `www/images/`

## Development Notes

- **No Database**: Uses RDS files for persistence - simple but not scalable
- **File Security**: Uploads stored in `www/` directory (publicly accessible)
- **Single Admin**: Only one admin user supported
- **No Testing**: No automated tests present
- **Version Control**: Two versions present (root and labsosv4) - labsosv4 appears newer

## Common Development Tasks

When working with this codebase:
1. **Adding new fields**: Update data frames in `global.R`, UI forms, and server validation
2. **UI changes**: Modify custom CSS in `ui.R:4-171` for styling
3. **New features**: Follow the modular pattern with clear section comments
4. **Data migration**: Handle data structure changes in `load_or_create_data()`
5. **File handling**: Ensure proper directory creation and file path management