const express = require('express');
const path = require('path');
const { BlobServiceClient } = require('@azure/storage-blob');
const sql = require('mssql');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// ── SQL Database Config ──────────────────────────────────────────────────────
const dbConfig = {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER,
  database: process.env.DB_NAME,
  options: {
    encrypt: true,
    trustServerCertificate: false,
  },
};

// ── Routes ───────────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Get all items from DB
app.get('/api/items', async (req, res) => {
  try {
    const pool = await sql.connect(dbConfig);
    const result = await pool.request().query('SELECT * FROM Items');
    res.json(result.recordset);
  } catch (err) {
    console.error('DB error:', err.message);
    res.status(500).json({ error: 'Database error', details: err.message });
  }
});

// Create a new item
app.post('/api/items', async (req, res) => {
  const { name, description } = req.body;
  try {
    const pool = await sql.connect(dbConfig);
    await pool.request()
      .input('name', sql.NVarChar, name)
      .input('description', sql.NVarChar, description)
      .query('INSERT INTO Items (name, description) VALUES (@name, @description)');
    res.status(201).json({ message: 'Item created successfully' });
  } catch (err) {
    console.error('DB error:', err.message);
    res.status(500).json({ error: 'Database error', details: err.message });
  }
});

// Upload file to Azure Blob Storage
app.post('/api/upload', async (req, res) => {
  try {
    const connStr = process.env.STORAGE_CONNECTION_STRING;
    const blobClient = BlobServiceClient.fromConnectionString(connStr);
    const containerClient = blobClient.getContainerClient('app-assets');
    const blobName = `upload-${Date.now()}.txt`;
    const blockBlob = containerClient.getBlockBlobClient(blobName);
    await blockBlob.upload('Sample content', 14);
    res.json({ message: 'File uploaded', blobName });
  } catch (err) {
    console.error('Storage error:', err.message);
    res.status(500).json({ error: 'Storage error', details: err.message });
  }
});

// Delete item
app.delete('/api/items/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const pool = await sql.connect(dbConfig);
    await pool.request()
      .input('id', sql.Int, id)
      .query('DELETE FROM Items WHERE id = @id');
    res.json({ message: 'Item deleted' });
  } catch (err) {
    console.error('DB error:', err.message);
    res.status(500).json({ error: 'Database error' });
  }
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

module.exports = app;
