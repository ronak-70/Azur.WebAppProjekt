# Deployment Guide

## Prerequisites
- Azure account at portal.azure.com
- Node.js 18+ installed
- Azure CLI installed (`az --version`)
- GitHub account

## Step-by-Step GUI Deployment

### 1. Resource Group
Portal → Resource Groups → + Create → `rg-3tier-app` → East US

### 2. Azure SQL Database
Portal → SQL databases → + Create → attach new server `sql-server-3tier` → Serverless compute

### 3. Storage Account
Portal → Storage accounts → + Create → `storage3tierapp` → LRS → create container `app-assets`

### 4. App Service Plan
Portal → App Service plans → + Create → `asp-3tier` → Linux → B1

### 5. Web App
Portal → App Services → + Create → Web App → Node 18 LTS → link to `asp-3tier`

### 6. Connection Strings
App Service → Configuration → Application settings → add DB_SERVER, DB_NAME, DB_USER, DB_PASSWORD, STORAGE_CONNECTION_STRING

### 7. Application Insights
App Service → Application Insights → Turn On → Create new

### 8. GitHub Actions CI/CD
- Download publish profile from App Service → Overview → Download publish profile
- GitHub repo → Settings → Secrets → New secret → `AZURE_WEBAPP_PUBLISH_PROFILE`
- Push to main branch → pipeline runs automatically

## Verify
App Service → Browse → your app opens at `webapp-3tier-demo.azurewebsites.net`
