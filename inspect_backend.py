import re, glob

for f in ['backend_dashboard.html', 'backend_officer.html', 'backend_review.html']:
    txt = open(f, encoding='utf-8').read()
    endpoints = set(re.findall(r'[\'"`](/api/[^\'"`\s?]+)', txt))
    print(f'=== {f} ===')
    for ep in sorted(endpoints):
        print('  ', ep)
