from docx import Document
from collections import Counter
import json,re
from pathlib import Path
root=Path(r'C:\flutter_projects\romance_club\.coursework')
d=Document(root/'audit_current.docx')
lines=[]
for i,p in enumerate(d.paragraphs):
 if p.text.strip(): lines.append(f'P{i} [{p.style.name}] {p.text}')
(root/'audit_text.txt').write_text('\n'.join(lines),encoding='utf-8')
for t in d.tables:
 lines.append('TABLE\n'+'\n'.join(' | '.join(c.text for c in r.cells) for r in t.rows))
(root/'audit_all.txt').write_text('\n'.join(lines),encoding='utf-8')
print('sections',len(d.sections),'tables',len(d.tables),'images',len(d.inline_shapes))
for s in d.sections:
 print('PAGE mm',*[round(x.mm,2) for x in [s.page_width,s.page_height,s.left_margin,s.right_margin,s.top_margin,s.bottom_margin]])
stop=next((i for i,p in enumerate(d.paragraphs) if re.match(r'^3\s+РЕАЛ',p.text)),len(d.paragraphs))
fonts=Counter(); sizes=Counter(); odd=[]
for i,p in enumerate(d.paragraphs[:stop]):
 for r in p.runs:
  if not r.text.strip():continue
  fonts[r.font.name]+=len(r.text);sizes[str(r.font.size.pt if r.font.size else None)]+=len(r.text)
  if r.font.name and r.font.name!='Times New Roman':odd.append((i,r.font.name,r.text[:100]))
print('STOP',stop,'fonts',fonts,'sizes',sizes,'odd',odd[:30])
print('default',d.styles['Normal'].font.name,d.styles['Normal'].font.size)
for i,p in enumerate(d.paragraphs[:stop]):
 if re.search(r'Рисунок\s+\d|Таблица\s+\d|рисунк|таблиц|[Пп]риложени|ВВЕДЕНИЕ|^\d[.\s]',p.text):print(i,p.text[:230])
