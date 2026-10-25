from docx import Document
from collections import Counter
D=Document('.coursework/audit_current.docx')
ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
def attrs(e):return {k.split('}')[-1]:v for k,v in e.attrib.items()}
for i in [24,25,44,45,46,130,152,174,197,232,248]:
 p=D.paragraphs[i]
 print(i,p.text[:60],'pr',[(e.tag.split('}')[-1],attrs(e)) for e in p._p.pPr] if p._p.pPr is not None else [],'runs',[(r.text[:20],[(e.tag.split('}')[-1],attrs(e)) for e in r._r.rPr] if r._r.rPr is not None else []) for r in p.runs if r.text.strip()][:3])
print('LATIN OUTSIDE QUOTES')
import re
for i,p in enumerate(D.paragraphs[24:256],24):
 s=re.sub('«[^»]*»','',p.text)
 if re.search('[a-zA-Z]{2,}',s):print(i,s)
