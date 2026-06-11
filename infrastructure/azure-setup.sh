#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Azure 3-Tier Web App — Full Infrastructure Setup Script
# Run: bash infrastructure/azure-setup.sh
# ─────────────────────────────────────────────────────────────

set -e

# ── Variables (edit these) ────────────────────────────────────
RESOURCE_GROUP="rg-3tier-app"
LOCATION="eastus"
SQL_SERVER="sql-server-3tier"
SQL_DB="app-database"
SQL_USER="sqladmin"
SQL_PASS="YourPassword123!"
STORAGE_ACCOUNT="storage3tierapp"
APP_PLAN="asp-3tier"
WEBAPP_NAME="webapp-3tier-demo"

echo "🔐 Logging in to Azure..."
az login

echo "📁 Creating Resource Group..."
az group create --name $RESOURCE_GROUP --location $LOCATION

echo "🗄️  Creating SQL Server..."
az sql server create \
  --name $SQL_SERVER \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user $SQL_USER \
  --admin-password $SQL_PASS

echo "🗄️  Creating SQL Database..."
az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name $SQL_DB \
  --edition GeneralPurpose \
  --compute-model Serverless \
  --family Gen5 \
  --capacity 2

echo "🔓 Allowing Azure services to access SQL..."
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER \
  --name AllowAzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

echo "📦 Creating Storage Account..."
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --kind StorageV2

echo "📦 Creating blob container..."
az storage container create \
  --name app-assets \
  --account-name $STORAGE_ACCOUNT \
  --public-access off

echo "🖥️  Creating App Service Plan..."
az appservice plan create \
  --name $APP_PLAN \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku B1 \
  --is-linux

echo "🌐 Creating Web App..."
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_PLAN \
  --name $WEBAPP_NAME \
  --runtime "NODE:18-lts"

echo "⚙️  Configuring app settings..."
STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query connectionString -o tsv)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEBAPP_NAME \
  --settings \
    DB_SERVER="${SQL_SERVER}.database.windows.net" \
    DB_NAME="$SQL_DB" \
    DB_USER="$SQL_USER" \
    DB_PASSWORD="$SQL_PASS" \
    STORAGE_CONNECTION_STRING="$STORAGE_CONN"

echo "📊 Enabling Application Insights..."
az monitor app-insights component create \
  --app insights-3tier \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --kind web

INSIGHTS_KEY=$(az monitor app-insights component show \
  --app insights-3tier \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey -o tsv)

az webapp config appsettings set \
  --resource-group $RESOURCE_GROUP \
  --name $WEBAPP_NAME \
  --settings APPINSIGHTS_INSTRUMENTATIONKEY="$INSIGHTS_KEY"

echo ""
echo "✅ All done! Your app is live at:"
az webapp show \
  --name $WEBAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query defaultHostName -o tsv
