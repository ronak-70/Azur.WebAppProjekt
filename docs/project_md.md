# 📘 Project Documentation — Azure 3-Tier Web Application

> This document explains the full story behind this project — the architecture decisions, the deployment process, the real errors we hit, and what we learned from each one.

---

## 📌 Table of Contents

- [Why We Built This](#-why-we-built-this)
- [Architecture Deep Dive](#️-architecture-deep-dive)
- [Azure Services Explained](#-azure-services-explained)
- [Design Decisions](#-design-decisions)
- [Deployment Process](#-deployment-process)
- [Real Challenges We Faced](#-real-challenges-we-faced)
- [Security Approach](#-security-approach)
- [Monitoring & Observability](#-monitoring--observability)
- [Cost Management](#-cost-management)
- [What We Learned](#-what-we-learned)
- [What Comes Next](#-what-comes-next)

---

## 💡 Why We Built This

Most Azure tutorials teach you how to deploy one service in isolation. You follow the steps, it works, and you move on — but you never really understand how everything fits together.

We wanted something different.

We wanted to build a system where **one user action triggers multiple Azure services** — where the frontend, the database, and the file storage all communicate as a single working application. Not three separate deployments sitting next to each other, but three services that actually depend on each other.

That's what this project is. And building it the hard way — hitting real errors, reading real logs, fixing real deployment failures — is what made it worth doing.

---

## 🏗️ Architecture Deep Dive

```
┌──────────────────────────────────────────────────────────────┐
│                        USERS                                 │
│                   Web Browser (HTTPS)                        │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                   AZURE APP SERVICE                          │
│                                                              │
│   ┌─────────────────────────────────────────────────────┐   │
│   │              Node.js 20 + Express                   │   │
│   │                                                     │   │
│   │   GET  /api/items    → read from SQL                │   │
│   │   POST /api/items    → write to SQL                 │   │
│   │   DELETE /api/items  → delete from SQL              │   │
│   │   POST /api/upload   → write to Blob Storage        │   │
│   │   GET  /health       → health check                 │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                              │
│   Region: Sweden Central  |  Plan: F1 Free (Linux)          │
└──────────────┬────────────────────────────┬─────────────────┘
               │                            │
               │ mssql driver               │ @azure/storage-blob
               ▼                            ▼
┌──────────────────────────┐  ┌─────────────────────────────────┐
│   AZURE SQL DATABASE     │  │     AZURE BLOB STORAGE          │
│                          │  │                                 │
│   Server: sql-server-    │  │   Account: str3tierapp          │
│   3tier-01               │  │   Container: app-assets         │
│   Database: app-database │  │   Access: Private               │
│   Tier: Basic DTU        │  │   Redundancy: LRS               │
│   Auth: SQL Login        │  │                                 │
└──────────────────────────┘  └─────────────────────────────────┘
```

### Data Flow — What Happens When a User Saves an Item

```
1. User fills the form → clicks "Save to Azure SQL"
2. Browser sends POST /api/items → App Service receives it
3. App Service reads DB_SERVER, DB_NAME, DB_USER, DB_PASSWORD
   from Azure Environment Variables
4. mssql driver opens a TCP connection to SQL Server on port 1433
5. INSERT INTO Items executes → row is written
6. App Service responds with { message: "Item created successfully" }
7. UI shows a green toast notification
8. Items table auto-refreshes — new row appears
```

### Data Flow — What Happens When a User Uploads a File

```
1. User clicks "Upload Sample File"
2. Browser sends POST /api/upload → App Service receives it
3. App Service reads STORAGE_CONNECTION_STRING from Environment Variables
4. @azure/storage-blob SDK connects to Azure Storage
5. A .txt file is created in the app-assets container
6. Blob URL is returned → UI confirms the upload
```

---

## 🔧 Azure Services Explained

### Azure App Service

The hosting layer. Our Node.js + Express application runs here. App Service handles:
- HTTPS termination
- Automatic restarts on crash
- Environment variable injection (our secrets live here, not in code)
- Integration with GitHub Actions for CI/CD

We chose **Linux + F1 Free tier** to keep costs at zero during development. The trade-off is a daily CPU quota limit, which is fine for a portfolio project.

### Azure SQL Database

The relational data layer. We store all item records here in a single `Items` table. Key details:
- **Basic DTU tier** — the most cost-effective option (~$5/month)
- **SQL Authentication** — username + password managed in App Service Environment Variables
- **Firewall rule** — "Allow Azure services" enabled so App Service can reach the database
- **Automatic backups** — Azure SQL provides 7-day Point-in-Time Restore for free, even on Basic tier

### Azure Blob Storage

The file storage layer. When users upload a file, it goes into the `app-assets` container as a Block Blob. Key details:
- **LRS (Locally Redundant Storage)** — 3 copies within the same datacenter, lowest cost
- **Private access** — blobs are not publicly accessible, only our app can read/write
- **Connection string auth** — the storage account key is stored in App Service Environment Variables

---

## 🎯 Design Decisions

### Why Node.js and not Python or .NET?

We had existing familiarity with JavaScript. Node.js with Express is lightweight, easy to deploy on Azure App Service Linux, and the `mssql` and `@azure/storage-blob` npm packages are well-maintained official SDKs.

### Why Basic DTU and not Serverless SQL?

Serverless SQL auto-pauses after inactivity, which sounds cheaper — but the cold start delay (up to 60 seconds) makes the app feel broken when someone first loads it. Basic DTU stays always-on at a predictable ~$5/month, which is better for a demo application.

### Why F1 Free App Service Plan?

We wanted to demonstrate the full architecture without spending money. F1 has a 60-minute daily CPU quota, which is enough for a portfolio project with low traffic. In a real production environment, we would upgrade to at least B1 Basic.

### Why Sweden Central?

Azure for Students subscriptions have regional restrictions. Our policy allowed only 5 regions: `germanywestcentral`, `spaincentral`, `uaenorth`, `italynorth`, and `swedencentral`. Sweden Central had the most consistent availability during our testing.

### Why Publish Profile for CI/CD and not Service Principal?

Publish Profile authentication is simpler to set up and doesn't require Azure AD app registration. For a portfolio project, it's the right trade-off. For production workloads, a Service Principal with OIDC (federated credentials) would be the correct approach.

---

## 🚀 Deployment Process

### Infrastructure Setup

```
1. Create Resource Group (rg-3tier-lab-01) → Sweden Central
2. Create Azure SQL Server + Database (Basic DTU)
3. Create Storage Account (LRS Standard) + app-assets container
4. Create App Service Plan (F1 Free, Linux)
5. Create Web App (Node.js 20, Linux)
6. Configure SQL firewall → Allow Azure services
7. Add Environment Variables to App Service
8. Create SQL table via Query Editor
9. Enable Application Insights
10. Configure Alert rules in Azure Monitor
```

### CI/CD Pipeline

```yaml
# Every push to main triggers:
1. actions/checkout@v4       → pull the code
2. actions/setup-node@v4     → set up Node.js 18
3. npm install               → install dependencies
4. npm test                  → run tests (passWithNoTests)
5. actions/upload-artifact   → package the app
6. actions/download-artifact → prepare for deploy
7. azure/webapps-deploy@v3   → push to App Service
```

The deploy step authenticates using `AZURE_WEBAPP_PUBLISH_PROFILE`, stored as a GitHub Actions secret.

---

## 🔥 Real Challenges We Faced

This section is the honest part. These are the actual errors we hit during this project and how we resolved each one.

---

### ❌ Challenge 1 — "No tests found, exiting with code 1"

**What happened:**
The CI/CD pipeline kept failing at the test step. Jest was configured but there were no test files in the repo.

**Error:**
```
No tests found, exiting with code 1
```

**Fix:**
Added `--passWithNoTests` flag to the jest command in `package.json`:
```json
"test": "jest --passWithNoTests --coverage"
```

**Lesson:** Always configure your test runner to handle an empty test suite gracefully, especially early in a project.

---

### ❌ Challenge 2 — "Dependencies lock file is not found"

**What happened:**
GitHub Actions couldn't find `package-lock.json` because it wasn't committed to the repo.

**Error:**
```
Dependencies lock file is not found. Supported file patterns: package-lock.json
```

**Fix:**
Ran `npm install` locally to generate `package-lock.json`, then committed it. Also removed `cache: 'npm'` from the workflow until the lock file was in place.

**Lesson:** Always commit your lock file. It ensures reproducible installs across environments.

---

### ❌ Challenge 3 — Deployment 409 Conflict

**What happened:**
Two deployments were triggered in quick succession. The second one started while the first was still running, causing a conflict.

**Error:**
```
Conflict (CODE: 409) — Failed to deploy web package using OneDeploy
```

**Fix:**
Restarted the App Service from Azure Portal, then re-ran the failed workflow job.

**Lesson:** Avoid pushing multiple commits in rapid succession when CI/CD is active. Let each deployment finish before pushing again.

---

### ❌ Challenge 4 — SQL "getaddrinfo ENOTFOUND"

**What happened:**
The app could not reach the SQL server. The environment variable `DB_SERVER` contained the wrong server address.

**Error:**
```
Failed to connect to sql-3tier-lab-01.database.windows.net:1433 - getaddrinfo ENOTFOUND
```

**Root cause:**
The actual SQL server name was `sql-server-3tier-01.database.windows.net`, not `sql-3tier-lab-01.database.windows.net`.

**Fix:**
Corrected the `DB_SERVER` value in App Service Environment Variables.

**Lesson:** Always copy the server name directly from Azure Portal → SQL Server → Overview. Never type it manually.

---

### ❌ Challenge 5 — SQL "Login failed for user"

**What happened:**
Even after fixing the server address, login kept failing.

**Error:**
```
DB error: Login failed for user 'sqladmin'
```

**Root cause:**
The `DB_NAME` environment variable was set to `db-3tier-lab-01` (the resource name we chose) but the actual database name inside the SQL server was `app-database` (the name set during creation).

**Fix:**
Updated `DB_NAME` to `app-database` in App Service Environment Variables.

**Lesson:** The Azure resource name and the database name inside SQL Server are two different things. Always verify the actual database name in Query Editor.

---

### ❌ Challenge 6 — Storage "The specified container does not exist"

**What happened:**
File uploads failed because the app was looking for a container named `app-assets`, but we had only created a container named `uploads`.

**Error:**
```
Storage error: The specified container does not exist.
```

**Fix:**
Created the `app-assets` container in Azure Portal → Storage Account → Containers.

**Lesson:** Container names in your code must exactly match the container names in Azure Storage. Case-sensitive.

---

### ⚠️ Challenge 7 — Secret Accidentally Committed

**What happened:**
The `STORAGE_CONNECTION_STRING` (containing a real Azure Storage Account key) was accidentally included in `.env.example` and pushed to GitHub. GitHub's secret scanning caught it immediately.

**Fix:**
1. Did NOT click "Allow Secret"
2. Rotated the Storage Account key immediately (Azure Portal → Storage → Access Keys → Rotate)
3. Removed the real value from `.env.example`, replaced with a placeholder
4. Ensured `.env` was in `.gitignore`

**Lesson:** Never commit real credentials to any file that goes to GitHub — even example files. Use placeholders. Rotate keys immediately if this happens.

---

## 🔐 Security Approach

| What | How |
|---|---|
| Database credentials | Azure App Service Environment Variables |
| Storage connection string | Azure App Service Environment Variables |
| CI/CD authentication | GitHub Actions Secret (Publish Profile) |
| SQL access | Firewall rule: Azure services only |
| Blob Storage | Private container, no public access |
| Code | Zero secrets in source code |

---

## 📊 Monitoring & Observability

- **Application Insights** — connected to App Service, collects request traces, exceptions, and performance data
- **Azure Monitor Alerts** — CPU alert configured: if CPU Time exceeds threshold, an email notification is sent
- **App Service Log Stream** — used actively during debugging to see live application logs
- **SQL Database Backups** — automatic 7-day Point-in-Time Restore, built into Basic tier

---

## 💸 Cost Management

| Resource | Tier | Daily Cost | Monthly Cost |
|---|---|---|---|
| App Service | F1 Free | $0 | $0 |
| Azure SQL Database | Basic DTU | ~$0.15 | ~$5 |
| Storage Account | LRS Standard | ~$0.001 | ~$0.01 |
| Application Insights | Free (5GB) | $0 | $0 |
| **Total** | | **~$0.15/day** | **~$5/mo** |

**Cost optimization decisions:**
- F1 Free App Service instead of B1 Basic → saves ~$13/month
- Basic DTU SQL instead of General Purpose → saves ~$150/month
- LRS Storage instead of GRS → saves ~50% on storage costs
- Delete resource group after testing → stops all charges instantly

---

## 🎓 What We Learned

### Technical

- How Azure App Service injects environment variables at runtime
- How TCP connections from App Service to SQL Database work through Azure's internal network
- How GitHub Actions artifacts work — build once, deploy the artifact
- How Azure SQL firewall rules control inbound connections
- How Blob Storage containers, access levels, and connection strings work together
- How to read and interpret App Service Log Stream for live debugging

### Process

- Always commit `package-lock.json`
- Never commit real credentials — not even in example files
- Rotate keys immediately if they are ever exposed
- Let CI/CD deployments finish before pushing again
- Copy resource names from Azure Portal — never type them manually

### Mindset

- Real cloud projects involve real errors. Debugging is the job.
- Understanding *why* something failed is more valuable than just fixing it.
- Cost awareness is a skill. Every service choice has a price.

---

## 🔮 What Comes Next

If we were to continue developing this project, the next steps would be:

- [ ] **Azure Key Vault** — move all secrets from Environment Variables to Key Vault references
- [ ] **User Authentication** — add Microsoft Entra ID (Azure AD) login
- [ ] **Azure Queue Storage** — add async notification system when items are created
- [ ] **Azure CDN** — serve static assets faster globally
- [ ] **Custom Domain + SSL** — replace the `.azurewebsites.net` URL
- [ ] **Infrastructure as Code** — rewrite the setup using Bicep or Terraform
- [ ] **Full test suite** — add unit and integration tests with Jest + Supertest

---

*Built with curiosity, debugged with patience.*
*— Emre & Khaliq, 2026*
