const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../new_backend.env') });
require('dotenv').config({ path: path.resolve(__dirname, '.env') });

// Fallback to Supabase connection string if DATABASE_URL not set in env
const connectionString = process.env.DATABASE_URL || "postgresql://postgres:ofSeDpd77Dv2Nmhx@db.rlkyqzbnqtsyjdfcjuac.supabase.co:5432/postgres";

const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false, // Required for Supabase / Render
  },
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
