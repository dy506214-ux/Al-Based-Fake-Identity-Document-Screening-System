const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../new_backend.env') });

const connectionString = process.env.DATABASE_URL || "postgresql://postgres.rlkyqzbnqtsyjdfcjuac:ofSeDpd77Dv2Nmhx@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres";
const pool = new Pool({ connectionString, ssl: { rejectUnauthorized: false } });

const BASE_URL = 'https://al-based-fake-identity-document-i43e.onrender.com';

async function testHttp(path, method, headers = {}, body = null) {
  const options = {
    method,
    headers: {
      'Accept': 'application/json',
      ...headers
    }
  };
  if (body) {
    options.headers['Content-Type'] = 'application/json';
    options.body = JSON.stringify(body);
  }
  const res = await fetch(`${BASE_URL}${path}`, options);
  let data = null;
  const text = await res.text();
  try {
    data = JSON.parse(text);
  } catch (_) {
    data = text;
  }
  return {
    status: res.status,
    headers: Object.fromEntries(res.headers.entries()),
    data
  };
}

async function runAudit() {
  console.log('============================================================');
  console.log('DOCISCAN LIVE PRODUCTION BACKEND END-TO-END AUDIT');
  console.log('Target Host:', BASE_URL);
  console.log('============================================================\n');

  // 1. Health Checks
  console.log('------------------------------------------------------------');
  console.log('1. Testing Health Endpoints');
  console.log('------------------------------------------------------------');
  const h1 = await testHttp('/health', 'GET');
  console.log('GET /health -> Status:', h1.status, JSON.stringify(h1.data));
  if (h1.status !== 200) throw new Error('Health check /health failed');

  const h2 = await testHttp('/api/health', 'GET');
  console.log('GET /api/health -> Status:', h2.status, JSON.stringify(h2.data));
  if (h2.status !== 200) throw new Error('Health check /api/health failed');

  // 2. CORS Preflight
  console.log('\n------------------------------------------------------------');
  console.log('2. Testing CORS Preflight (OPTIONS) with localhost origin');
  console.log('------------------------------------------------------------');
  const preflight = await testHttp('/api/auth/registration/create-account', 'OPTIONS', {
    'Origin': 'http://localhost:60238',
    'Access-Control-Request-Method': 'POST',
    'Access-Control-Request-Headers': 'content-type,authorization'
  });
  console.log('OPTIONS Preflight Status:', preflight.status);
  console.log('Access-Control-Allow-Origin:', preflight.headers['access-control-allow-origin']);
  console.log('Access-Control-Allow-Methods:', preflight.headers['access-control-allow-methods']);
  if (preflight.status !== 204 && preflight.status !== 200) {
    throw new Error('CORS preflight failed with status ' + preflight.status);
  }

  // 3. Officer Registration
  console.log('\n------------------------------------------------------------');
  console.log('3. Registering New Real Officer via Production API');
  console.log('------------------------------------------------------------');
  const testMobile = '98' + Math.floor(10000000 + Math.random() * 90000000);
  const testEmail = 'officer_' + testMobile + '@dociscan.gov.in';
  const testPassword = 'SecurePass!2026';
  const testName = 'Inspector Test Lead';

  const reg = await testHttp('/api/auth/registration/create-account', 'POST', {
    'Origin': 'http://localhost:60238'
  }, {
    name: testName,
    mobile: testMobile,
    email: testEmail,
    password: testPassword
  });

  console.log('Registration HTTP Status:', reg.status);
  console.log('Registration Response:', JSON.stringify(reg.data, null, 2));
  if (reg.status !== 201 || !reg.data.success) {
    throw new Error('Officer registration failed: ' + JSON.stringify(reg.data));
  }
  const token = reg.data.token;
  const user = reg.data.user;

  // 4. Persistence Verification
  console.log('\n------------------------------------------------------------');
  console.log('4. Verifying Officer Record Persistence in Backend Database');
  console.log('------------------------------------------------------------');
  const officersCheck = await testHttp('/api/admin/officers', 'GET', {
    'Authorization': `Bearer ${token}`
  });
  console.log('Officers in Backend DB:', officersCheck.data.count);
  const found = officersCheck.data.data.find(o => o.email === testEmail);
  console.log('Found Registered Officer:', found);
  if (!found) {
    throw new Error('Officer record not found in backend database for ' + testEmail);
  }

  // 5. Login Verification
  console.log('\n------------------------------------------------------------');
  console.log('5. Logging In With Newly Registered Credentials');
  console.log('------------------------------------------------------------');
  const login = await testHttp('/api/auth/login', 'POST', {
    'Origin': 'http://localhost:60238'
  }, {
    email: testEmail,
    password: testPassword
  });
  console.log('Login HTTP Status:', login.status);
  console.log('Login Token Present:', !!login.data.token);
  console.log('Authenticated User Payload:', login.data.user);
  if (login.status !== 200 || !login.data.token) {
    throw new Error('Login failed for registered user: ' + JSON.stringify(login.data));
  }

  // 6. Profile Verification
  console.log('\n------------------------------------------------------------');
  console.log('6. Querying Authenticated Officer Profile (Bearer JWT)');
  console.log('------------------------------------------------------------');
  const prof = await testHttp('/api/auth/profile', 'GET', {
    'Authorization': `Bearer ${login.data.token}`
  });
  console.log('Profile HTTP Status:', prof.status);
  console.log('Profile Data:', prof.data);
  if (prof.status !== 200) {
    throw new Error('Profile retrieval failed with status ' + prof.status);
  }

  // 7. Duplicate Prevention
  console.log('\n------------------------------------------------------------');
  console.log('7. Testing Duplicate Mobile & Email Protection');
  console.log('------------------------------------------------------------');
  const dupMob = await testHttp('/api/auth/registration/create-account', 'POST', {}, {
    name: 'Duplicate Officer',
    mobile: testMobile,
    email: 'another_' + testEmail,
    password: testPassword
  });
  console.log('Duplicate Mobile Rejected Status:', dupMob.status, 'Message:', dupMob.data.message);
  if (dupMob.status < 400) throw new Error('Duplicate mobile was not blocked!');

  const dupEmail = await testHttp('/api/auth/registration/create-account', 'POST', {}, {
    name: 'Duplicate Officer',
    mobile: '98' + Math.floor(10000000 + Math.random() * 90000000),
    email: testEmail,
    password: testPassword
  });
  console.log('Duplicate Email Rejected Status:', dupEmail.status, 'Message:', dupEmail.data.message);
  if (dupEmail.status < 400) throw new Error('Duplicate email was not blocked!');

  // 8. Documents API
  console.log('\n------------------------------------------------------------');
  console.log('8. Testing Officer Documents Query');
  console.log('------------------------------------------------------------');
  const docs = await testHttp('/api/documents/my-documents', 'GET', {
    'Authorization': `Bearer ${login.data.token}`
  });
  console.log('My Documents Status:', docs.status, 'Count:', Array.isArray(docs.data.data) ? docs.data.data.length : 'N/A');
  if (docs.status !== 200) throw new Error('My documents failed with status ' + docs.status);

  // 9. Admin Stats API
  console.log('\n------------------------------------------------------------');
  console.log('9. Testing Admin Dashboard Stats');
  console.log('------------------------------------------------------------');
  const stats = await testHttp('/api/admin/stats', 'GET', {
    'Authorization': `Bearer ${login.data.token}`
  });
  console.log('Admin Stats Status:', stats.status, 'Stats:', stats.data.stats);
  if (stats.status !== 200) throw new Error('Admin stats failed with status ' + stats.status);

  console.log('\n============================================================');
  console.log('ALL LIVE END-TO-END PRODUCTION BACKEND AUDIT TESTS PASSED!');
  console.log('============================================================');
  await pool.end();
}

runAudit().catch(async (err) => {
  console.error('\n[AUDIT FAILED]:', err);
  await pool.end();
  process.exit(1);
});
