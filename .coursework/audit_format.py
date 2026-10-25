from docx import Document
from pathlib import Path
from lxml import etree
D=Document('.coursework/audit_current.docx')
for i in [24,25,44,45,46,130,152,174,197,232,248,256]:
 p=D.paragraphs[i];print(i,p.text[:70]);print(p._p.xml[:1800])
from pypdf import PdfReader
p=Path('.coursework/audit_current.pdf')
print('pdfexists',p.exists())
