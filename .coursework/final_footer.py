from docx import Document
from pypdf import PdfReader
from lxml import etree as E
import zipfile,re
D=Document('.coursework/audit_current.docx');r=PdfReader('.coursework/audit_current.pdf');ns={'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
for n in [1,2,3,4,22,30,37,54,55]:
 print('PAGE',n,'TAIL',repr(r.pages[n-1].extract_text()[-180:]))
for i,s in enumerate(D.sections):
 print('SECTION',i,'footer/header',s.footer_distance.cm,s.header_distance.cm,'different',s.different_first_page_header_footer)
 for key in ['footer','first_page_footer','header','first_page_header']:
  f=getattr(s,key);print(key,'linked',f.is_linked_to_previous,'text',repr('\n'.join(p.text for p in f.paragraphs)),f._element.xml[:500])
with zipfile.ZipFile('.coursework/audit_current.docx') as z:
 ft=E.fromstring(z.read('word/footnotes.xml'))
 print('FOOTNOTE SIZES',ft.xpath('//w:sz/@w:val',namespaces=ns),'FONTNAMES',ft.xpath('//w:rFonts/@w:ascii',namespaces=ns))
 print('NOTE STYLE',[(s.name,s.font.name,s.font.size.pt if s.font.size else None) for s in D.styles if 'footnote' in s.name.lower()])
 print('SECTS',re.findall('<w:sectPr.*?</w:sectPr>',z.read('word/document.xml').decode(),re.S))
# explicit references excluding captions
for kind in ['рисунк','таблиц','[Пп]риложени']:
 print('REFERENCE',kind)
 for i,p in enumerate(D.paragraphs[:353]):
  if re.search(kind,p.text) and not re.match(r'^(Рисунок|Таблица|Продолжение)',p.text):print(i,p.text[:240])
