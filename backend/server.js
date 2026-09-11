require('dotenv').config({ path: '../new_backend.env' });
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('./db');

const app = express();
const port = process.env.PORT || 5000;
const JWT_SECRET = process.env.JWT_SECRET || 'my_super_secret_key_for_dociscan_2026';

// Middleware
app.use(cors());
app.use(express.json());
const upload = multer({ storage: multer.memoryStorage() }); // Keep files in memory to store in DB

// --- Auth Middleware ---
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Authorization header missing or malformed' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(401).json({ success: false, message: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

// --- Routes ---

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ success: true, message: 'Backend is healthy', uptime: process.uptime() });
});
app.get('/health', (req, res) => {
  res.json({ success: true, message: 'Backend is healthy', uptime: process.uptime() });
});

// Auth: Login
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ success: false, message: 'Email and password are required' });

  try {
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    let user = result.rows[0];

    // Auto-create an officer for testing if no users exist
    if (!user && email === 'officer@agency.gov.in') {
      const hash = await bcrypt.hash(password || 'password', 10);
      const insertRes = await db.query(
        'INSERT INTO users (name, email, password_hash, role) VALUES ($1, $2, $3, $4) RETURNING *',
        ['Officer Test', email, hash, 'OFFICER']
      );
      user = insertRes.rows[0];
    } else if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid email or password' });
    }

    const validPassword = await bcrypt.compare(password, user.password_hash);
    if (!validPassword) return res.status(400).json({ success: false, message: 'Invalid email or password' });

    const token = jwt.sign({ id: user.id, role: user.role, email: user.email }, JWT_SECRET, { expiresIn: '24h' });
    res.json({ success: true, token, user: { id: user.id, name: user.name, email: user.email, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Auth: Profile
app.get('/api/auth/profile', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT id, name, email, role FROM users WHERE id = $1', [req.user.id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Documents: Upload
app.post('/api/documents/upload', authenticateToken, upload.fields([{ name: 'document', maxCount: 1 }, { name: 'selfie', maxCount: 1 }]), async (req, res) => {
  const documentType = req.body.documentType || 'UNKNOWN';
  const documentFile = req.files && req.files['document'] ? req.files['document'][0] : null;
  const selfieFile = req.files && req.files['selfie'] ? req.files['selfie'][0] : null;

  try {
    const result = await db.query(
      `INSERT INTO documents (user_id, document_type, file_data, file_content_type, selfie_data, selfie_content_type) 
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, user_id, document_type, status, review_decision, uploaded_at`,
      [
        req.user.id, documentType, 
        documentFile ? documentFile.buffer : null, 
        documentFile ? documentFile.mimetype : null,
        selfieFile ? selfieFile.buffer : null,
        selfieFile ? selfieFile.mimetype : null
      ]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Documents: My Documents
app.get('/api/documents/my-documents', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('SELECT id, document_type, status, review_decision, uploaded_at FROM documents WHERE user_id = $1 ORDER BY uploaded_at DESC', [req.user.id]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Documents: Delete
app.delete('/api/documents/:id', authenticateToken, async (req, res) => {
  try {
    const result = await db.query('DELETE FROM documents WHERE id = $1 AND user_id = $2 RETURNING id', [req.params.id, req.user.id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Document not found or unauthorized' });
    res.json({ success: true, message: 'Document deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Process Document (Mock AI)
app.post('/api/documents/:id/process', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      "UPDATE documents SET status = 'PROCESSED', review_decision = 'APPROVED' WHERE id = $1 RETURNING id, status, review_decision",
      [req.params.id]
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Face Verify (Mock AI)
app.post('/api/face-verification/verify-document/:id', authenticateToken, async (req, res) => {
  try {
    res.json({ success: true, message: 'Face verified successfully', matchScore: 0.95 });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// Start server
app.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
});
