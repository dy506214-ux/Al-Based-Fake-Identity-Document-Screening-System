const BASE_URL = 'https://al-based-fake-identity-document-i43e.onrender.com';

async function run() {
  // 1. Register fresh test officer to get JWT
  const testMobile = '98' + Math.floor(10000000 + Math.random() * 90000000);
  const testEmail = 'probe_officer_' + testMobile + '@dociscan.gov.in';
  const testPassword = 'Password@123';

  const regRes = await fetch(`${BASE_URL}/api/auth/registration/create-account`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Inspector Probe Officer',
      mobile: testMobile,
      email: testEmail,
      password: testPassword
    })
  });
  console.log('Registration status:', regRes.status);
  const regData = await regRes.json();
  const token = regData.token;
  console.log('Token exists:', !!token);

  // 2. Upload Document
  const dummyPng = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==', 'base64');
  const docBlob = new Blob([dummyPng], { type: 'image/png' });
  const form = new FormData();
  form.append('document', docBlob, 'document.png');
  form.append('documentType', 'OTHER_NATIONAL_ID');

  console.log('\nUploading document...');
  const uploadRes = await fetch(`${BASE_URL}/api/documents/upload`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: form
  });
  console.log('Upload status:', uploadRes.status);
  const uploadData = await uploadRes.json();
  console.log('Upload response:', JSON.stringify(uploadData, null, 2));

  const docId = uploadData.document?._id || uploadData.document?.id || uploadData.id;
  console.log('Doc ID:', docId);

  if (docId) {
    // 3. Face verification / attach face
    console.log('\nAttaching face photo to document ' + docId + '...');
    const faceForm = new FormData();
    faceForm.append('selfie', new Blob([dummyPng], { type: 'image/png' }), 'selfie.png');

    const faceRes = await fetch(`${BASE_URL}/api/face-verification/verify-document/${docId}`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` },
      body: faceForm
    });
    console.log('Face verification status:', faceRes.status);
    const faceText = await faceRes.text();
    console.log('Face verification response:', faceText);

    // 4. Process document
    console.log('\nProcessing document screening for ' + docId + '...');
    const procRes = await fetch(`${BASE_URL}/api/documents/${docId}/process`, {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    console.log('Process status:', procRes.status);
    const procText = await procRes.text();
    console.log('Process response:', procText);
  }

  // 5. Test Direct Screening Pipeline (/api/screening/analyze)
  console.log('\nTesting direct screening /api/screening/analyze...');
  const directForm = new FormData();
  directForm.append('document', new Blob([dummyPng], { type: 'image/png' }), 'doc.png');
  directForm.append('face', new Blob([dummyPng], { type: 'image/png' }), 'face.png');
  directForm.append('selectedDocumentType', 'OTHER_NATIONAL_ID');

  const directRes = await fetch(`${BASE_URL}/api/screening/analyze`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` },
    body: directForm
  });
  console.log('Direct screening status:', directRes.status);
  const directText = await directRes.text();
  console.log('Direct screening response:', directText);
}

run().catch(console.error);
