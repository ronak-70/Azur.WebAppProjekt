# ☁️ Azure 3-Tier Web Application

A production-ready 3-tier web application deployed on Microsoft Azure using **App Service**, **Azure SQL Database**, and **Azure Storage Account**.

![Architecture](https://img.shields.io/badge/Azure-App%20Service-0078D4?logo=microsoftazure&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18-339933?logo=nodedotjs&logoColor=white)
![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=githubactions&logoColor=white)

---

## 🏗️ Architecture

```
Users
  ↓
Azure App Service  (Node.js / Express)
  ↓
Azure SQL Database  (Relational data)
  ↓
Azure Storage Account  (Blobs / Assets)
```

---

## 📁 Project Structure

```
azure-web-app-project/
├── src/
│   ├── app.js              # Express server & API routes
│   └── public/
│       └── index.html      # Frontend UI
├── infrastructure/
│   ├── azure-setup.sh      # Full CLI setup script
│   └── setup-database.sql  # SQL table creation script
├── docs/
│   └── deployment-guide.md
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions CI/CD
├── .env.example            # Environment variables template
├── package.json
└── README.md
```

---

## 🚀 Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/azure-web-app-project.git
cd azure-web-app-project
```

### 2. Install dependencies
```bash
npm install
```

### 3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your Azure credentials
```

### 4. Set up Azure infrastructure
```bash
bash infrastructure/azure-setup.sh
```

### 5. Run database setup
Run `infrastructure/setup-database.sql` in Azure SQL Query Editor.

### 6. Run locally
```bash
npm run dev
# → http://localhost:3000
```

---

## ⚙️ CI/CD Pipeline

Push to `main` → GitHub Actions automatically:
1. Installs dependencies
2. Runs tests
3. Deploys to Azure App Service

**Setup:** Add `AZURE_WEBAPP_PUBLISH_PROFILE` to your GitHub repo secrets.
Get it from: Azure Portal → App Service → **Download publish profile**.

---

## 🌐 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| GET | `/api/items` | Get all items from SQL |
| POST | `/api/items` | Create a new item |
| POST | `/api/upload` | Upload file to Blob Storage |

---

## 💰 Estimated Cost

| Resource | Tier | Monthly Cost |
|----------|------|-------------|
| App Service | B1 Basic | ~$13 |
| Azure SQL | Serverless Gen5 | ~$5–15 |
| Storage Account | LRS Standard | ~$0.02/GB |
| Application Insights | Pay-as-you-go | ~$0–5 |
| **Total** | | **~$18–33/mo** |

> Use **F1 Free** App Service plan + **free Azure SQL tier** to keep costs at $0 for learning.

---

## 🧹 Cleanup

```bash
az group delete --name rg-3tier-app --yes --no-wait
```

---

## 📄 License

MIT
