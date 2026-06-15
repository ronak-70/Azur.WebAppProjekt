# ☁️ Azure 3-Tier Web Application

> 🚀 A hands-on cloud project demonstrating enterprise-grade Azure architecture —
> built from scratch to understand how real-world cloud applications actually work.

<br/>

![Azure](https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-20_LTS-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Express](https://img.shields.io/badge/Express.js-404D59?style=for-the-badge&logo=express&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white)
![Azure DevOps](https://img.shields.io/badge/Azure_DevOps-0078D4?style=for-the-badge&logo=azuredevops&logoColor=white)
![SQL](https://img.shields.io/badge/Azure_SQL-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Storage](https://img.shields.io/badge/Blob_Storage-0089D6?style=for-the-badge&logo=microsoftazure&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-brightgreen?style=for-the-badge)

<br/>

🔗 **Live Demo →** [webapp-3tier-mr.azurewebsites.net](https://webapp-3tier-mr-cqd4d0abavh4cqcz.swedencentral-01.azurewebsites.net)

---

## 👀 Preview

![App Preview](./docs/screenshots/12-live-app-ui.png)

---

## 🧠 The Story

This project started with a simple question:

> **"How does a real cloud application actually connect all its pieces?"**

Most tutorials show you how to deploy one service in isolation. This project is different — it connects **multiple Azure services** so they work together as a single system. A user action on the frontend writes to a SQL database, sends a Queue notification, and uploads a file to Blob Storage — all monitored in real time.

I built it, broke it, fixed it, and deployed it — all using Azure's free and low-cost tiers.

> 💬 *"I didn't just follow a tutorial — I hit real errors, debugged live deployments, and figured it out. That's the whole point."*

---

## 🏗️ Architecture

![Architecture diagram](./docs/screenshots/01-architecture-diagram.png)

<details>
<summary>Text version</summary>

```
┌─────────────────────────────────────────────────────┐
│                      Users                          │
│                   (Web Browser)                     │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS
┌──────────────────────▼──────────────────────────────┐
│              Azure App Service                      │
│           Node.js 20 + Express REST API             │
│              Sweden Central Region                  │
└──────────┬───────────────────────┬──────────────────┘
           │ SQL Connection        │ Storage Connection
┌──────────▼──────────┐  ┌────────▼────────────────────┐
│  Azure SQL Database │  │   Azure Blob Storage        │
│   (Relational data) │  │   + Queue Storage           │
└─────────────────────┘  └─────────────────────────────┘
```

</details>

**Key principle:** Every service talks to the next one. This is not three isolated deployments — it's one connected system.

Two CI/CD pipelines — **GitHub Actions** and **Azure DevOps** — both deploy to App Service on every push to `main`, running in parallel.

---

## ✨ Features

- ✅ **Full CRUD** — Create, Read, Delete items via Azure SQL
- ✅ **Queue Notifications** — Every new item triggers an Azure Queue message
- ✅ **File Upload** — Store files in Azure Blob Storage
- ✅ **RBAC** — Role-based access control via Microsoft Entra ID
- ✅ **Live Health Check** — Real-time App Service status in the UI
- ✅ **Dual CI/CD** — GitHub Actions + Azure DevOps Pipelines running in parallel
- ✅ **Approval Gate** — Manual approval required before every Production deploy
- ✅ **Modern UI** — Tailwind CSS, toast notifications, loading states
- ✅ **Secure Config** — All secrets in Azure Environment Variables, never in code
- ✅ **Monitoring** — Azure Monitor + Application Insights connected

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/health` | App health check |
| `GET` | `/api/items` | Fetch all items from SQL |
| `POST` | `/api/items` | Create a new item + Queue notification|
| `DELETE` | `/api/items/:id` | Delete an item by ID |
| `POST` | `/api/upload` | Upload file to Blob Storage |

---

## 📁 Project Structure

```
azure-web-app-project/
├── src/
│   ├── app.js                  # Express server & all API routes
│   └── public/
│       └── index.html          # Frontend (Tailwind CSS)
├── infrastructure/
│   ├── azure-setup.sh          # Full Azure CLI setup script
│   └── setup-database.sql      # SQL table schema
├── docs/
│   ├── PROJECT.md              # Detailed project documentation
│   └── screenshots/            # Screenshots used throughout this README
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD
├── azure-pipelines.yml         # Azure DevOps Pipeline (multi-stage)
├── .env.example                # Environment variable template
├── package.json
└── README.md
```

---

<details>
<summary>🚀 <strong>Quick Start — click to expand</strong></summary>

<br/>

**1. Clone the repo**
```bash
git clone https://github.com/okayemre/azure-web-app-project.git
cd azure-web-app-project
```

**2. Install dependencies**
```bash
npm install
```

**3. Set up environment variables**
```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `DB_SERVER` | Azure SQL Server hostname |
| `DB_NAME` | Database name |
| `DB_USER` | SQL admin username |
| `DB_PASSWORD` | SQL admin password |
| `STORAGE_CONNECTION_STRING` | Azure Storage connection string |

**4. Create SQL table**

Run in Azure SQL Query Editor:
```sql
CREATE TABLE Items (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(MAX),
    createdAt DATETIME DEFAULT GETDATE()
);
```

**5. Run locally**
```bash
npm run dev
# → http://localhost:3000
```

</details>

---

<details>
<summary>⚙️ <strong>CI/CD Pipelines — click to expand</strong></summary>

<br/>

This project uses **two parallel CI/CD pipelines** — both trigger on every push to `main`.

### Pipeline 1 — GitHub Actions (`deploy.yml`)

```
git push origin main
        ↓
GitHub Actions starts
        ↓
npm install + npm test
        ↓
Deploy to Azure App Service
        ↓
✅ Live in ~1 minute
```

**One-time setup:**

1. Go to Azure Portal → App Service → **Download publish profile**
2. Go to GitHub → Settings → Secrets → **New repository secret**
3. Name: `AZURE_WEBAPP_PUBLISH_PROFILE`
4. Value: paste the publish profile content

---

### Pipeline 2 — Azure DevOps (`azure-pipelines.yml`)

```
git push origin main
        ↓
Azure DevOps Pipeline starts
        ↓
Build & Test stage:
  npm install + npm test + zip artifact
        ↓
Deploy to Production stage:
  Manual approval gate → Deploy to App Service
        ↓
✅ Live after approval
```

**One-time setup:**

1. Create Azure DevOps organization at [dev.azure.com](https://dev.azure.com)
2. Create Service Connection (Azure Resource Manager)
3. Connect GitHub repo via OAuth
4. Run pipeline — Azure DevOps auto-detects `azure-pipelines.yml`

See the [screenshot gallery](#-screenshot-gallery) below for the pipeline run and service connection in action.

</details>

---

<details>
<summary>💰 <strong>Cost Breakdown — click to expand</strong></summary>

<br/>

This project runs at near-zero cost using free and low-cost tiers:

| Resource | Tier | Monthly Cost |
|----------|------|-------------|
| Azure App Service | F1 Free | **$0** |
| Azure SQL Database | Basic DTU | ~$5 |
| Azure Storage Account | LRS Standard | ~$0.01 |
| Application Insights | Free tier (5GB) | **$0** |
| Azure DevOps | Free tier (5 users) | **$0** |
| **Total** | | **~$5/mo** |

> 💡 Delete the resource group after testing to stop all charges instantly:
> ```bash
> az group delete --name rg-3tier-app --yes --no-wait
> ```

</details>

---

## 📸 Screenshot Gallery

A closer look at the Azure resources, configuration, data layer, security, and CI/CD pipelines behind this project. Click any section to expand.

### ☁️ Azure Resources

<details>
<summary><strong>Resource group — all provisioned resources</strong></summary>

![Resource group overview](./docs/screenshots/02-resource-group-overview.png)

All resources in `rg-3tier-app`, Sweden Central: App Service, App Service Plan, SQL Server + Database, Storage Account, and two Managed Identities used by Azure DevOps.

</details>

<details>
<summary><strong>App Service overview</strong></summary>

![App Service overview](./docs/screenshots/03-app-service-overview.png)

`webapp-3tier-mr` — Linux, F1 Free tier, connected to the GitHub repository for continuous deployment.

</details>

<details>
<summary><strong>Environment variables</strong></summary>

![Environment variables](./docs/screenshots/04-environment-variables.png)

All secrets — database credentials and the storage connection string — are stored as App Service environment variables, never in source code. Values are hidden in this view.

</details>

### 🗄️ Data & Storage

<details>
<summary><strong>Azure SQL — query editor</strong></summary>

![SQL query editor](./docs/screenshots/05-sql-query-editor.png)

Running `SELECT * FROM Items` directly against `app-database` using the Azure Portal Query Editor.

</details>

<details>
<summary><strong>SQL firewall rules</strong></summary>

![SQL firewall rules](./docs/screenshots/06-sql-firewall-rules.png)

"Allow Azure services and resources to access this server" is enabled, so App Service can reach the database without exposing it to the public internet.

</details>

<details>
<summary><strong>Blob Storage — app-assets container</strong></summary>

![Blob storage containers](./docs/screenshots/07-blob-storage-containers.png)

Uploaded files are stored in the private `app-assets` container inside the `str3tierapp` storage account.

</details>

<details>
<summary><strong>Queue Storage — item-notifications</strong></summary>

![Queue storage message](./docs/screenshots/08-queue-storage-message.png)

Every new item creates a JSON message in the `item-notifications` queue — the async, decoupled notification layer.

</details>

### 🔐 Security & Access

<details>
<summary><strong>RBAC — role assignments</strong></summary>

![RBAC IAM](./docs/screenshots/09-rbac-iam.png)

Access control for `rg-3tier-app`: Owner roles plus a Reader role assigned via Microsoft Entra ID.

</details>

### ⚙️ CI/CD Pipelines

<details>
<summary><strong>Azure DevOps — pipeline run</strong></summary>

![Azure DevOps pipeline run](./docs/screenshots/10-azure-devops-pipeline.png)

A multi-stage pipeline: Build & Test, then Deploy to Production — gated behind a manual approval step.

</details>

<details>
<summary><strong>Azure DevOps — service connection</strong></summary>

![Azure DevOps service connection](./docs/screenshots/11-azure-devops-service-connection.png)

`azure-connection` — an Azure Resource Manager service connection authenticated via Workload Identity Federation, with no stored passwords or secrets.

</details>

---

## 🎓 What I Learned

- 🔗 How to connect multiple Azure services into one working system
- 📨 How Azure Queue Storage enables async event-driven communication
- 🔐 How to secure resources with RBAC and Microsoft Entra ID
- 🚀 How to build CI/CD pipelines with both GitHub Actions and Azure DevOps
- 🏗️ How multi-stage pipelines with approval gates work in production
- 🔥 How to debug live deployments using App Service Log Stream
- 🌐 How Azure SQL firewall rules and network access work
- 💸 How to optimize cloud costs using free and low-cost tiers
- 🛠️ How to solve real deployment errors the hard way

---

## 📖 Documentation

For a detailed explanation of the architecture, deployment steps, and design decisions, see:

👉 **[docs/PROJECT.md](./docs/PROJECT.md)**

---

## 📄 License

MIT © 2026
