const BASE_URL = 'https://al-based-fake-identity-document-i43e.onrender.com';

async function testFileCount() {
  const loginRes = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'officer@test.com', password: '123456' }),
  });
  const token = (await loginRes.json()).token;

  const dummyPng = Buffer.from(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    'base64'
  );

  console.log('--- Test A: 2 files (document + face) ---');
  const formA = new FormData();
  formA.append('document', new Blob([dummyPng]), 'doc.png');
  formA.append('face', new Blob([dummyPng]), 'face.png');
  formA.append('selectedDocumentType', 'AADHAAR');
  const resA = await fetch(`${BASE_URL}/api/screening/analyze`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: formA,
  });
  console.log('Test A (2 files) Status:', resA.status);

  console.log('\n--- Test B: 3 files (document + face + selfie) ---');
  const formB = new FormData();
  formB.append('document', new Blob([dummyPng]), 'doc.png');
  formB.append('face', new Blob([dummyPng]), 'face.png');
  formB.append('selfie', new Blob([dummyPng]), 'selfie.png');
  formB.append('selectedDocumentType', 'AADHAAR');
  const resB = await fetch(`${BASE_URL}/api/screening/analyze`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: formB,
  });
  console.log('Test B (3 files) Status:', resB.status, await resB.text());
}

testFileCount();
