const { Pool } = require('pg');
require('dotenv').config({ path: '../new_backend.env' }); // Load from root for local dev

// Using the DATABASE_URL provided by the user
const connectionString = process.env.DATABASE_URL;

const pool = new Pool({
  connectionString,
  ssl: {
    rejectUnauthorized: false, // Required for some cloud databases like Supabase/Render
  },
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
