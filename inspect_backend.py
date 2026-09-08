import urllib.request, json

token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhYTA2YWYxNGFlYjFiMDMzYmFlZTMwNyIsInJvbGUiOiJPRkZJQ0VSIiwiaWF0IjoxNzg4ODk4MDQ1LCJleHAiOjE3ODg5ODQ0NDV9.43kixRiIEadM1RbTVT1XUW9cTodPPs7L80g4hmAmqXs'

boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW'
body = (
    f'--{boundary}\r\n'
    f'Content-Disposition: form-data; name="documentType"\r\n\r\n'
    f'PASSPORT\r\n'
    f'--{boundary}\r\n'
    f'Content-Disposition: form-data; name="document"; filename="doc.png"\r\n'
    f'Content-Type: image/png\r\n\r\n'
    f'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82\r\n'
    f'--{boundary}\r\n'
    f'Content-Disposition: form-data; name="selfie"; filename="selfie.png"\r\n'
    f'Content-Type: image/png\r\n\r\n'
    f'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82\r\n'
    f'--{boundary}--\r\n'
).encode('latin1')

req = urllib.request.Request(
    'https://sih26188-backend.onrender.com/api/documents/upload',
    data=body,
    headers={
        'Authorization': f'Bearer {token}',
        'Content-Type': f'multipart/form-data; boundary={boundary}',
    }
)
try:
    res = urllib.request.urlopen(req)
    data = json.loads(res.read().decode())
    print('UPLOAD WITH SELFIE:', json.dumps(data, indent=2))
except urllib.error.HTTPError as e:
    print('UPLOAD ERROR:', e.code, e.read().decode())




