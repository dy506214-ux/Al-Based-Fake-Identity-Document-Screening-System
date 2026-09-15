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

    const docTypes = ['AADHAAR', 'PAN', 'PASSPORT', 'VISA', 'DRIVING_LICENSE', 'OTHER_NATIONAL_ID', 'Aadhaar Card', 'Passport'];

    for (const dt of docTypes) {
      const form = new FormData();
      form.append('document', new Blob([dummyPng], { type: 'image/png' }), 'doc.png');
      form.append('face', new Blob([dummyPng], { type: 'image/png' }), 'face.png');
      form.append('selectedDocumentType', dt);

      const res = await fetch(`${BASE_URL}/api/screening/analyze`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
        },
        body: form,
      });

      const bodyText = await res.text();
      let parsed = null;
      try { parsed = JSON.parse(bodyText); } catch (_) {}

      console.log(`DocType: "${dt}" -> HTTP ${res.status}, success=${parsed?.success}, status=${parsed?.status}, risk=${parsed?.riskScore}`);
    }

  } catch (globalErr) {
    console.error('Global error:', globalErr);
  }
}

testAnalyze();
