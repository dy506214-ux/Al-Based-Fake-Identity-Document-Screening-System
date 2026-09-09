import urllib.request

origins = [
    'http://localhost', 'http://localhost:3000', 'http://localhost:5000', 'http://localhost:8000',
    'http://localhost:8080', 'http://localhost:50000', 'http://127.0.0.1', 'http://127.0.0.1:3000',
    'https://localhost', 'https://sih26188-backend.onrender.com', 'http://localhost:5173'
]
for o in origins:
    req = urllib.request.Request('https://sih26188-backend.onrender.com/api/auth/login', method='OPTIONS')
    req.add_header('Origin', o)
    req.add_header('Access-Control-Request-Method', 'POST')
    try:
        r = urllib.request.urlopen(req)
        print(f'{o} -> {r.status} {r.headers.get("Access-Control-Allow-Origin")}')
    except urllib.error.HTTPError as e:
        print(f'{o} -> {e.code}')
