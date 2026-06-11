#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Azure 3-Tier Web App — Full Infrastructure Setup Script
# Built by Emre & Khaliq — 2026
#
# Usage:
#   1. Fill in the variables below
#   2. Run: bash infrastructure/azure-setup.sh
#
# Requirements:
#   - Azure CLI installed (az --version)
#   - Azure for Students subscription
#   - Supported regions: swedencentral, germanywestcentral,
#     spaincentral, italynorth, uaenorth
# ─────────────────────────────────────────────────────────────

set -e

# ── Variables (edit before running) ──────────────────────────
RESOURCE_GROUP="rg-3tier-lab-01"
LOCATION="swedencentral"          # Azure for Students supported region
SQL_SERVER="sql-server-3tier-01"
SQL_DB="app-database"
SQL_USER="sqladmin"
SQL_PASS=""                       # ← Fill in a strong password before running
STORAGE_ACCOUNT="str3tierapp"     # Must be lowercase, globally unique
APP_PLAN="asp-3tier-lab-01"
WEBAPP_NAME="webapp-3tier-mr"     # Must be globally unique

# ── Validation ────────────────────────────────────────────────
if [ -z "$SQL_PASS" ]; then
  echo "❌ ERROR: SQL_PASS is empty. Please set a password before running."
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Azure 3-Tier Web App — Infrastructure Setup"
echo "  Region: $LOCATION"
echo "  Resource Group: $RESOURCE_GROUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Step 1: Login ─────────────────────────────────────────────
echo "🔐 [1/9] Logging in to Azure..."
az login --output none
echo "✅ Logged in."

# ── Step 2: Resource Group ────────────────────────────────────
echo "📁 [2/9] Creating Resource Group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none
echo "✅ Resource Group: $RESOURCE_GROUP"

# ── Step 3: SQL Server ────────────────────────────────────────
echo "🗄️  [3/9] Creating Azure SQL Server..."
az sql server create \
  --name "$SQL_SERVER" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --admin-user "$SQL_USER" \
  --admin-password "$SQL_PASS" \
  --output none
echo "✅ SQL Server: ${SQL_SERVER}.database.windows.net"

# ── Step 4: SQL Database (Basic DTU — most cost-effective) ────
echo "🗄️  [4/9] Creating Azure SQL Database (Basic DTU)..."
az sql db create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "$SQL_DB" \
  --edition Basic \
  --capacity 5 \
  --output none
# Note: Basic DTU (~$5/mo) chosen over Serverless to avoid cold start delays
echo "✅ SQL Database: $SQL_DB (Basic, 5 DTU)"

# ── Step 5: SQL Firewall ──────────────────────────────────────
echo "🔓 [5/9] Opening SQL Firewall for Azure services..."
az sql server firewall-rule create \
  --resource-group "$RESOURCE_GROUP" \
  --server "$SQL_SERVER" \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0 \
  --output none
echo "✅ Firewall rule set — Azure services can now connect."

# ── Step 6: Storage Account ───────────────────────────────────
echo "📦 [6/9] Creating Storage Account..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --output none

echo "📦 Creating Blob Container (app-assets)..."
az storage container create \
  --name "app-assets" \
  --account-name "$STORAGE_ACCOUNT" \
  --public-access off \
  --output none
echo "✅ Storage Account: $STORAGE_ACCOUNT | Container: app-assets"

# ── Step 7: App Service Plan (F1 Free) ────────────────────────
echo "🖥️  [7/9] Creating App Service Plan (F1 Free)..."
az appservice plan create \
  --name "$APP_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku F1 \
  --is-linux \
  --output none
# Note: F1 Free has 60 min/day CPU quota — suitable for dev/portfolio
echo "✅ App Service Plan: $APP_PLAN (F1 Free, Linux)"

# ── Step 8: Web App (Node.js 20) ─────────────────────────────
echo "🌐 [8/9] Creating Web App..."
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_PLAN" \
  --name "$WEBAPP_NAME" \
  --runtime "NODE:20-lts" \
  --output none
echo "✅ Web App: https://${WEBAPP_NAME}.azurewebsites.net"

# ── Step 9: Environment Variables ────────────────────────────
echo "⚙️  [9/9] Configuring App Settings..."

# Get Storage Connection String
STORAGE_CONN=$(az storage account show-connection-string \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query connectionString \
  --output tsv)

az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings \
    DB_SERVER="${SQL_SERVER}.database.windows.net" \
    DB_NAME="$SQL_DB" \
    DB_USER="$SQL_USER" \
    DB_PASSWORD="$SQL_PASS" \
    STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
  --output none
echo "✅ Environment Variables configured."

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Setup Complete!"
echo ""
echo "  🌐 App URL:"
az webapp show \
  --name "$WEBAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query defaultHostName \
  --output tsv
echo ""
echo "  📋 Next steps:"
echo "  1. Run setup-database.sql in Azure SQL Query Editor"
echo "  2. Add AZURE_WEBAPP_PUBLISH_PROFILE to GitHub Secrets"
echo "  3. Push your code to trigger CI/CD"
echo ""
echo "  🧹 To delete all resources when done:"
echo "  az group delete --name $RESOURCE_GROUP --yes --no-wait"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
