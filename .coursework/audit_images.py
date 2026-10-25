from docx import Document
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw
r=Path('.coursework');d=Document(r/'audit_current.docx')
for i in [1,9,10,11,12]:
 sh=d.inline_shapes[i];b=sh._inline.graphic.graphicData.pic.blipFill.blip.embed
 part=d.part.related_parts[b];p=r/f'audit_figure_{i+1}.png';p.write_bytes(part.blob)
files=sorted(r.glob('auditview-*.png'))
for start in range(0,min(len(files),38),6):
 canvas=Image.new('RGB',(1200,1740),'#cccccc');draw=ImageDraw.Draw(canvas)
 for j,f in enumerate(files[start:start+6]):
  im=Image.open(f).convert('RGB');im.thumbnail((390,820));x=(j%3)*400;y=(j//3)*870
  canvas.paste(im,(x,y+25));draw.text((x+10,y+5),f.stem,fill='black')
 canvas.save(r/f'audit_sheet_{start//6}.jpg')
print('rendered',len(files))
