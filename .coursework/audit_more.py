from docx import Document
from pathlib import Path
from collections import Counter
import re,zipfile
r=Path('.coursework');d=Document(r/'audit_current.docx')
for name in ['Normal','List Paragraph','Heading 1','Heading 2','Heading 3','Caption','Body Text']:
 s=d.styles[name]; f=s.paragraph_format
 print('STYLE',name,s.font.name,s.font.size.pt if s.font.size else None,'space',f.line_spacing,'indent',f.first_line_indent.cm if f.first_line_indent else None)
for i,p in enumerate(d.paragraphs[:256]):
 if p.text.strip() and (re.search(r' {2,}|[–—][А-Яа-яA-Za-z]|[а-яА-Я][A-Za-z]|[A-Za-z][а-яА-Я]',p.text) or ('PWA' in p.text and '«PWA' not in p.text)):
  print('SPACE',i,p.text[:300])
print('TABLEFONTS')
for i,t in enumerate(d.tables[:10]):
 fs=Counter((rr.font.name,rr.font.size.pt if rr.font.size else None) for row in t.rows for c in row.cells for p in c.paragraphs for rr in p.runs if rr.text.strip())
 print(i,fs)
with zipfile.ZipFile(r/'audit_current.docx') as z:
 from lxml import etree
 tree=etree.fromstring(z.read('word/document.xml'));ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
 for s in tree.xpath('//w:sdt',namespaces=ns):
  tx=''.join(s.xpath('.//w:t/text()',namespaces=ns))
  if 'ВВЕДЕНИЕ' in tx:print('TOC',tx[:13000])
 print('FIELDS',tree.xpath('//w:instrText/text()',namespaces=ns)[:20])
# original compare
old=Document(r'C:\Users\User\OneDrive\учёба\4 курс\Технология разработки программного обеспечения (Коломейцева)\КР_Устюжанина_23-03ИСиП_2026.docx')
(r/'audit_original.txt').write_text('\n'.join(p.text for p in old.paragraphs),encoding='utf-8')
print('old paragraphs',len(old.paragraphs))
