exec(open('.coursework/final_audit.py',encoding='utf-8-sig').read().split('out=[];')[0])
print('NONSTANDARD PARAGRAPHS')
for i,p in enumerate(d.paragraphs[24:end],24):
 if p.text.strip() and (sf(p,'line_spacing') not in (1.5,2.0,None) or (p.style.name in ('Normal','List Paragraph') and sf(p,'first_line_indent') is not None and sf(p,'first_line_indent').cm not in (0,) and abs(sf(p,'first_line_indent').cm-1.25)>.02)):
  print(i,p.style.name,p.text, 'spacing',sf(p,'line_spacing'),'after',sf(p,'space_after'))
print('TEXT DASH')
for i,p in enumerate(d.paragraphs[:end]):
 if re.search(r'–\S|\S–',p.text) and not re.search(r'\d[–-]\d',p.text):print(i,p.text)
print('TABLE ANOMALIES')
for ti,t in enumerate(d.tables):
 for ri,row in enumerate(t.rows):
  for ci,c in enumerate(row.cells):
   for p in c.paragraphs:
    if re.search(r' {2,}|–\S',p.text):print(ti,ri,ci,p.text)
    s=re.sub(r'«[^»]*»','',p.text)
    if ti not in (7,12) and re.search('[A-Za-z]{2,}',s):print('LATIN',ti,ri,ci,s)
print('FOOTNOTE MARKS')
with zipfile.ZipFile(R/'audit_current.docx') as z:
 tree=E.fromstring(z.read('word/document.xml'))
 for p in tree.xpath('//w:p[w:r/w:footnoteReference]',namespaces=ns):
  print(''.join(p.xpath('.//w:t/text()',namespaces=ns)),p.xpath('.//w:footnoteReference/@w:id',namespaces=ns))
 print('STYLE FOOTNOTE',[(s.name,s.font.name,s.font.size.pt if s.font.size else None,s.paragraph_format.line_spacing) for s in d.styles if 'footnote' in s.name.lower()])
 ft=E.fromstring(z.read('word/footnotes.xml'))
 print('NOTE SIZE',Counter(ft.xpath('//w:sz/@w:val',namespaces=ns)),'FONTS',Counter(ft.xpath('//w:rFonts/@w:ascii',namespaces=ns)))
 print('HYPERLINK URLS',re.findall(r'Target="([^"]+)"[^>]*TargetMode="External"',z.read('word/_rels/document.xml.rels').decode()))
print('SECTIONS',[(s.footer_distance.cm,s.header_distance.cm) for s in d.sections])
