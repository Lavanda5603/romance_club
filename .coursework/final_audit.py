from docx import Document
from lxml import etree as E
from collections import Counter,defaultdict
from pathlib import Path
import re,zipfile,json
R=Path('.coursework');d=Document(R/'audit_current.docx'); ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
texts=[p.text for p in d.paragraphs]; end=next(i for i,t in enumerate(texts) if t.startswith('СПИСОК ИСПОЛЬЗ'));app=next(i for i,t in enumerate(texts) if t.startswith('ПРИЛОЖЕНИЕ'))
def sf(p,attr):
 v=getattr(p.paragraph_format,attr)
 s=p.style
 while v is None and s is not None:
  v=getattr(s.paragraph_format,attr);s=s.base_style
 return v
def rf(p,r,attr):
 v=getattr(r.font,attr)
 s=r.style
 while v is None and s is not None:
  v=getattr(s.font,attr);s=s.base_style
 s=p.style
 while v is None and s is not None:
  v=getattr(s.font,attr);s=s.base_style
 return v
out=[];out.append(f'BIB {end} APP {app} PARAS {len(texts)}')
for i,p in enumerate(d.paragraphs):
 if i<app and p.text.strip():out.append(f'P{i} [{p.style.name}] {p.text}')
refs=defaultdict(list)
for i,t in enumerate(texts[:end]):
 for m in re.finditer(r'\[(\d+(?:\s*[,;–-]\s*\d+)*)\]',t):
  for n in re.findall(r'\d+',m[1]):refs[int(n)].append((i,t[-180:]))
out.append('CITATIONS '+json.dumps(refs,ensure_ascii=False))
for i,t in enumerate(texts[24:end],24):
 if re.search(r' {2,}|\s+[,.!?;:]|[а-яА-Я]–[а-яА-Я]|[а-яА-Я],[а-яА-Я]|[а-яА-Я]\.[А-Я]',t):out.append(f'SPACE P{i}: {t}')
 s=re.sub(r'«[^»]*»','',t)
 if re.search(r'[a-zA-Z]{2,}',s):out.append(f'LATIN P{i}: {s}')
 if t.count('«')!=t.count('»'):out.append(f'QUOTES P{i}: {t}')
fonts=Counter();bodyfmt=Counter();odd=[]
for i,p in enumerate(d.paragraphs[24:end],24):
 if not p.text.strip():continue
 f=(p.style.name,str(sf(p,'alignment')),str(sf(p,'line_spacing')),round(sf(p,'first_line_indent').cm,3) if sf(p,'first_line_indent') is not None else None,str(sf(p,'space_before')),str(sf(p,'space_after')))
 bodyfmt[f]+=1
 for r in p.runs:
  if not r.text.strip():continue
  font=rf(p,r,'name');size=rf(p,r,'size');size=size.pt if size else None
  fonts[(font,size)]+=len(r.text)
  if (font!='Times New Roman' and font is not None) or size not in (14,None):odd.append((i,font,size,r.text))
out.append('FONTS '+repr(fonts));out.append('BODYFMT '+repr(bodyfmt));out.append('ODDRUNS '+repr(odd))
for ti,tab in enumerate(d.tables):
 out.append('TABLE '+str(ti)+' '+repr(Counter((rf(p,r,'name'),rf(p,r,'size').pt if rf(p,r,'size') else None) for row in tab.rows for c in row.cells for p in c.paragraphs for r in p.runs if r.text.strip())))
 out.append('\n'.join(' | '.join(c.text for c in row.cells) for row in tab.rows))
with zipfile.ZipFile(R/'audit_current.docx') as z:
 tree=E.fromstring(z.read('word/document.xml'))
 for s in tree.xpath('//w:sdt',namespaces=ns):
  tx=''.join(s.xpath('.//w:t/text()',namespaces=ns))
  if 'ВВЕДЕНИЕ' in tx:out.append('TOC '+tx)
 for typ in ['footnote','endnote']:
  ids=tree.xpath(f'//w:{typ}Reference/@w:id',namespaces=ns)
  out.append(typ+' REFS '+repr(ids))
  f='word/'+typ+'s.xml'
  if f in z.namelist():
   ft=E.fromstring(z.read(f))
   for note in ft:out.append(typ+' '+str(note.attrib)+' '+''.join(note.xpath('.//w:t/text()',namespaces=ns)))
 out.append('COMMENTS '+str('word/comments.xml' in z.namelist()))
 out.append('TRACKED '+str(len(tree.xpath('//w:ins|//w:del',namespaces=ns))))
(R/'final_audit.txt').write_text('\n'.join(out),encoding='utf8')
method=Path(r'C:/Users/User/OneDrive/учёба/4 курс/Технология разработки программного обеспечения (Коломейцева)/Методическое реководство по курсовой.docx')
m=Document(method);(R/'final_method.txt').write_text('\n'.join(p.text for p in m.paragraphs)+'\n'+'\n'.join(c.text for t in m.tables for row in t.rows for c in row.cells),encoding='utf8')
print('DONE',len(texts), 'CITATIONS',{n:len(v) for n,v in refs.items()},'FONTS',fonts,'ODD',len(odd))
