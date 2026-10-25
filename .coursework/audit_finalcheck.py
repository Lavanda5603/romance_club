from pypdf import PdfReader
from collections import Counter
from docx import Document
from pathlib import Path
r=PdfReader('.coursework/audit_current.pdf')
c=Counter();odd=[]
for i,p in enumerate(r.pages[3:37],4):
 def visitor(t,cm,tm,font,size):
  if t.strip():
   name=(font or {}).get('/BaseFont','?');c[(str(name),round(size,2))]+=len(t)
   if 'Times' not in str(name) and len(t.strip())>2:odd.append((i,str(name),size,t[:100]))
 p.extract_text(visitor_text=visitor)
print('PDFFONTS',c,'ODD',odd[:30])
d=Document('.coursework/audit_current.docx')
for i,p in enumerate(d.paragraphs):
 if 348<=i<=374:print(i,p.text)
# compare core old risky claims
s=Path('.coursework/audit_original.txt').read_text(encoding='utf8')
for l in s.splitlines():
 if any(x in l for x in ['Ни один','на рынке нет','3-4 часов','оригинального алгоритма','Научная новизна']):print('OLD',l[:600])
