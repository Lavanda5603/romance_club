from pathlib import Path
from PIL import Image,ImageDraw
r=Path('.coursework');files=sorted(r.glob('finalpage-*.png'))
for start in range(0,len(files),9):
 canvas=Image.new('RGB',(1500,2145),'#bbb');draw=ImageDraw.Draw(canvas)
 for j,f in enumerate(files[start:start+9]):
  im=Image.open(f).convert('RGB');im.thumbnail((490,680));x=j%3*500;y=j//3*715
  canvas.paste(im,(x,y+25));draw.text((x+10,y+4),f.stem,fill='black')
 canvas.save(r/f'finalsheet-{start//9}.jpg')
print('PAGES',len(files))
