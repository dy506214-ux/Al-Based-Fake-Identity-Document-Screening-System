const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, 'new_backend.env') });

const connectionString = process.env.DATABASE_URL || "postgresql://postgres.rlkyqzbnqtsyjdfcjuac:ofSeDpd77Dv2Nmhx@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres";
const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });

async function showAllUsers() {
  console.log('\n===================================================================================================');
  console.log('                    DOCISCAN - ALL REGISTERED OFFICERS (SUPABASE POSTGRESQL)');
  console.log('===================================================================================================\n');

  try {
    const result = await pool.query(
      'SELECT id, name, email as login_id, mobile, role, status, to_char(created_at, \'YYYY-MM-DD HH24:MI:SS\') as registered_on FROM users ORDER BY created_at DESC'
    );

    if (result.rows.length === 0) {
      console.log('No registered users found in the database.');
    } else {
      console.table(result.rows);
      console.log(`\nTotal Registered Officers in Database: ${result.rows.length}`);
    }
  } catch (err) {
    console.error('Error fetching users from Supabase PostgreSQL:', err.message);
  } finally {
    await pool.end();
    console.log('\n===================================================================================================\n');
  }
}

showAllUsers();
