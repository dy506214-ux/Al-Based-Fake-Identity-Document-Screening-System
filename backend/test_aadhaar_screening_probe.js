const BASE_URL = 'https://al-based-fake-identity-document-i43e.onrender.com';

async function testAadhaarScreening() {
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
    console.log('Login success:', loginData.success, 'Token:', !!loginData.token);
    const token = loginData.token;

    // Create a dummy 100x100 PNG image
    const dummyPng = Buffer.from(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      'base64'
    );

    console.log('\n--- Sending Aadhaar Card screening request with document + face ---');
    const form = new FormData();
    form.append('document', new Blob([dummyPng], { type: 'image/png' }), 'aadhaar_card.png');
    form.append('face', new Blob([dummyPng], { type: 'image/png' }), 'face_photo.png');
    form.append('selectedDocumentType', 'AADHAAR');

    const res = await fetch(`${BASE_URL}/api/screening/analyze`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
      },
      body: form,
    });

    console.log('Analyze Status:', res.status);
    const resText = await res.text();
    console.log('Analyze Response Body:', resText);
  } catch (err) {
    console.error('Test Error:', err);
  }
}

testAadhaarScreening();
