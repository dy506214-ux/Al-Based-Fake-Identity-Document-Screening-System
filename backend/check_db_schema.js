const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgresql://postgres.rlkyqzbnqtsyjdfcjuac:ofSeDpd77Dv2Nmhx@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });

async function check() {
  const cols = await pool.query("SELECT column_name, data_type, is_nullable, column_default FROM information_schema.columns WHERE table_name = 'documents'");
  console.log('Columns:', cols.rows);

  // Test insert with explicit UUID
  const crypto = require('crypto');
  const testId = crypto.randomUUID();
  try {
    const res = await pool.query(
      `INSERT INTO documents (id, user_id, document_type, file_data, file_content_type)
       VALUES ($1, $2, $3, $4, $5) RETURNING id, status, review_decision`,
      [testId, '00000000-0000-0000-0000-000000000001', 'PASSPORT', Buffer.from('test'), 'image/jpeg']
    );
    console.log('Insert with explicit ID succeeded:', res.rows[0]);
  } catch (err) {
    console.error('Insert with explicit ID failed:', err.message);
  }

  await pool.end();
}

check();
