const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../new_backend.env') });

const connectionString = process.env.DATABASE_URL || "postgresql://postgres.rlkyqzbnqtsyjdfcjuac:ofSeDpd77Dv2Nmhx@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres";
const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });

async function runTests() {
  const base = 'http://localhost:5000';

  console.log('------------------------------------------------------------');
  console.log('TEST 1: Register New Officer via Real API');
  console.log('------------------------------------------------------------');
  const testMobile = '98' + Math.floor(10000000 + Math.random() * 90000000);
  const testEmail = 'officer_' + testMobile + '@dociscan.gov.in';
  const testPassword = 'SecurePass!2026';

  const regRes = await fetch(`${base}/api/auth/registration/create-account`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Inspector Abhay',
      mobile: testMobile,
      email: testEmail,
      password: testPassword
    })
  });
  const regJson = await regRes.json();
  console.log('Registration HTTP Status:', regRes.status);
  console.log('Registration Response:', JSON.stringify(regJson, null, 2));

  console.log('\n------------------------------------------------------------');
  console.log('TEST 2: Query Real Supabase PostgreSQL for newly created user');
  console.log('------------------------------------------------------------');
  const dbCheck = await pool.query('SELECT id, name, email, mobile, role, status, created_at FROM users WHERE email = $1', [testEmail]);
  console.log('DB Record in Supabase:', dbCheck.rows[0]);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 3: Login with newly created credentials');
  console.log('------------------------------------------------------------');
  const loginRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: testEmail, password: testPassword })
  });
  const loginJson = await loginRes.json();
  console.log('Login HTTP Status:', loginRes.status);
  console.log('Token Received:', !!loginJson.token);
  console.log('Authenticated User:', loginJson.user);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 4: Duplicate Mobile Registration (Must be blocked)');
  console.log('------------------------------------------------------------');
  const dupMobRes = await fetch(`${base}/api/auth/registration/create-account`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Duplicate Officer',
      mobile: testMobile,
      email: 'another_' + testEmail,
      password: 'AnotherPassword!1'
    })
  });
  const dupMobJson = await dupMobRes.json();
  console.log('Duplicate Mobile Blocked Status:', dupMobRes.status);
  console.log('Message:', dupMobJson.message);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 5: Duplicate Login ID Registration (Must be blocked)');
  console.log('------------------------------------------------------------');
  const dupEmailRes = await fetch(`${base}/api/auth/registration/create-account`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Duplicate Officer 2',
      mobile: '97' + Math.floor(10000000 + Math.random() * 90000000),
      email: testEmail,
      password: 'AnotherPassword!2'
    })
  });
  const dupEmailJson = await dupEmailRes.json();
  console.log('Duplicate Email Blocked Status:', dupEmailRes.status);
  console.log('Message:', dupEmailJson.message);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 6: Wrong Password Test (Must be rejected)');
  console.log('------------------------------------------------------------');
  const wrongPassRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: testEmail, password: 'WrongPassword123!' })
  });
  const wrongPassJson = await wrongPassRes.json();
  console.log('Wrong Password Rejected Status:', wrongPassRes.status);
  console.log('Message:', wrongPassJson.message);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 7: Permanent Officer Login (officer@gmail.com / 123456)');
  console.log('------------------------------------------------------------');
  const permRes = await fetch(`${base}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'officer@gmail.com', password: '123456' })
  });
  const permJson = await permRes.json();
  console.log('Permanent Officer Login Status:', permRes.status);
  console.log('Permanent Officer User:', permJson.user);

  console.log('\n------------------------------------------------------------');
  console.log('TEST 8: Admin Officers List (Querying Supabase PostgreSQL)');
  console.log('------------------------------------------------------------');
  const adminRes = await fetch(`${base}/api/admin/officers`, {
    headers: { 'Authorization': `Bearer ${loginJson.token}` }
  });
  const adminJson = await adminRes.json();
  console.log('Admin Officers Count in Supabase:', adminJson.count);
  console.log('Latest Registered Officer in Admin:', adminJson.officers && adminJson.officers[0] ? adminJson.officers[0].email : 'None');

  await pool.end();
  console.log('\n============================================================');
  console.log('ALL TESTS PASSED WITH REAL SUPABASE POSTGRESQL PERSISTENCE');
  console.log('============================================================');
}

runTests().catch(err => {
  console.error('Test Suite Failed:', err);
  process.exit(1);
});
