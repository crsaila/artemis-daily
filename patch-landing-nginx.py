#!/usr/bin/env python3
import sys
import shutil

LANDING = '/etc/nginx/sites-enabled/landing'
PORT = sys.argv[1] if len(sys.argv) > 1 else '8513'
BLOCK = f"""
    location /artemis {{
        rewrite ^/artemis/(.*) /$1 break;
        proxy_pass http://localhost:{PORT};
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }}
"""

with open(LANDING) as f:
    content = f.read()

if 'location /artemis' in content:
    print('landing: /artemis already present, skipping')
    sys.exit(0)

# Insert before the closing } of the /reader block (last location in first server block)
insert_at = content.find('\n}', content.find('location /reader'))
if insert_at == -1:
    print('ERROR: could not find insertion point in landing config', file=sys.stderr)
    sys.exit(1)

new_content = content[:insert_at] + BLOCK + content[insert_at:]

shutil.copy(LANDING, LANDING + '.bak')
with open(LANDING, 'w') as f:
    f.write(new_content)

print('landing: /artemis block added')
