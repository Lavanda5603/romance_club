from pypdf import PdfReader
from pathlib import Path
import re
r=PdfReader('.coursework/audit_current.pdf')
print('PAGES',len(r.pages))
for i,p in enumerate(r.pages):
 t=p.extract_text()
 if i<4:print('PAGE',i+1,t[:15000])
 hs=[l for l in t.splitlines() if re.match(r'^(?:[123](?:\.\d+)*\s|ВВЕДЕНИЕ|Рисунок\s+\d|Таблица\s+\d|ПРИЛОЖЕНИЕ)',l.strip())]
 print('HEADS',i+1,' | '.join(hs))
Path('.coursework/audit_pdftext.txt').write_text('\n'.join(f'PAGE {i+1}\n'+p.extract_text() for i,p in enumerate(r.pages)),encoding='utf-8')
