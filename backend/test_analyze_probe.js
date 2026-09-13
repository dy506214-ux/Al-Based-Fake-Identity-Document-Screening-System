const BASE_URL = 'https://al-based-fake-identity-document-i43e.onrender.com';

async function testAnalyze() {
  try {
    const loginRes = await fetch(`${BASE_URL}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'officer@test.com',
        password: '123456',
      }),
    });
    const loginData = await loginRes.json();
    console.log('Login status:', loginRes.status, 'Token:', loginData.token ? 'YES' : 'NO');
    const token = loginData.token;

    const dummyPng = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'base64'
    );

    console.log('\n--- Test 1: Single file "document" with selectedDocumentType ---');
    const form1 = new FormData();
    form1.append('document', new Blob([dummyPng], { type: 'image/png' }), 'doc.png');
    form1.append('selectedDocumentType', 'PASSPORT');

    const res1 = await fetch(`${BASE_URL}/api/screening/analyze`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: form1,
    });
    console.log('Test 1 Status:', res1.status, 'Response:', await res1.text());

    console.log('\n--- Test 2: Two files "document" and "face" with selectedDocumentType ---');
    const form2 = new FormData();
    form2.append('document', new Blob([dummyPng], { type: 'image/png' }), 'doc.png');
    form2.append('face', new Blob([dummyPng], { type: 'image/png' }), 'face.png');
    form2.append('selectedDocumentType', 'PASSPORT');

    const res2 = await fetch(`${BASE_URL}/api/screening/analyze`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: form2,
    });
    console.log('Test 2 Status:', res2.status, 'Response:', await res2.text());

  } catch (globalErr) {
    console.error('Global error:', globalErr);
  }
}

testAnalyze();
