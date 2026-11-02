exec(open('.coursework/final_audit.py',encoding='utf-8-sig').read().split('out=[];')[0])
import difflib
report=[]
def add(*v):report.append(' '.join(map(str,v)))
old=Document(R/'review_before_latest.docx')
add('TEXT CHANGES', '\n'.join(difflib.unified_diff([p.text for p in old.paragraphs],[p.text for p in d.paragraphs],n=0)))
for i,p in enumerate(d.paragraphs[24:end],24):
 t=p.text.strip()
 if not t:continue
 if p.style.name.startswith('Heading'):add('HEADING',i,t,'line',sf(p,'line_spacing'),'before',sf(p,'space_before'),'after',sf(p,'space_after'),'align',sf(p,'alignment'),'keep',sf(p,'keep_with_next'))
 elif sf(p,'alignment')!=3:add('NONJUSTIFY',i,t)
 if re.search(r' {2,}|\s+[;!?]|–\S|\S–',t) and not re.search(r'\d[–-]\d',t):add('SPACING',i,t)
 if not p.style.name.startswith('Heading') and not t.startswith(('Рисунок','Таблица','Продолжение')) and t[-1] not in '.;:!?':add('ENDING',i,t)
for ti,tab in enumerate(d.tables):
 seen=set();stats=Counter()
 for ri,row in enumerate(tab.rows):
  for ci,c in enumerate(row.cells):
   if c._tc in seen:continue
   seen.add(c._tc)
   for p in c.paragraphs:
    if not p.text.strip():continue
    stats[(str(sf(p,'alignment')),str(sf(p,'line_spacing')),str(sf(p,'first_line_indent')))]+=1
    if ti>1 and sf(p,'alignment') not in (3,):add('TABLEALIGN',ti,ri,ci,str(sf(p,'alignment')),p.text)
    if re.search(r' {2,}|\s+[;!?]|–\S',p.text):add('TABLESPACE',ti,ri,ci,p.text)
    if re.search(r'[A-Za-z]{2,}',re.sub('«[^»]*»','',p.text)) and ti>1:add('TABLELATIN',ti,ri,ci,p.text)
 add('TABLESTATS',ti,stats)
for i,s in enumerate(d.sections):add('SECTION',i,'margins',*[round(getattr(s,a).cm,3) for a in ['left_margin','right_margin','top_margin','bottom_margin']])
with zipfile.ZipFile(R/'audit_current.docx') as z:
 ft=E.fromstring(z.read('word/footnotes.xml'))
 add('NOTES',Counter(ft.xpath('//w:sz/@w:val',namespaces=ns)),Counter(ft.xpath('//w:rFonts/@w:ascii',namespaces=ns)))
 for st in d.styles:
  if 'footnote' in st.name.lower():add('NOTESTYLE',st.name,st.font.name,st.font.size.pt if st.font.size else None)
(R/'precise_review.txt').write_text('\n'.join(report),encoding='utf-8')
print('\n'.join(report))
