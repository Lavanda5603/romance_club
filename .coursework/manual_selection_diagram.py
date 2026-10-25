from pathlib import Path
from html import escape
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import math,subprocess

B=Path(__file__).parent
pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
c=canvas.Canvas(str(B/'manual_selection.pdf'),pagesize=(700,1000))
c.setLineWidth(1.4)
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="700" height="1000" viewBox="0 0 700 1000">',
 '<rect width="700" height="1000" fill="white"/>',
 '<g fill="white" stroke="black" stroke-width="1.4">']
def line(x1,y1,x2,y2):
 c.line(x1,y1,x2,y2)
 svg.append(f'<line x1="{x1}" y1="{1000-y1}" x2="{x2}" y2="{1000-y2}"/>')
def label(x,y,tx,size=19):
 c.setFont('Arial',size)
 for i,s in enumerate(tx.split('\n')):
  yy=y-i*(size+5);c.drawCentredString(x,yy,s)
  svg.append(f'<text x="{x}" y="{1000-yy}" text-anchor="middle" fill="black" stroke="none" font-family="Arial, sans-serif" font-size="{size}">{escape(s)}</text>')
def task(y,tx):
 c.roundRect(225,y,250,65,10)
 svg.append(f'<rect x="225" y="{1000-y-65}" width="250" height="65" rx="10"/>')
 ls=tx.split('\n');label(350,y+32+(len(ls)-1)*12-6,tx)
def event(y,end=False):
 c.circle(350,y,18);svg.append(f'<circle cx="350" cy="{1000-y}" r="18"/>')
 if end:c.circle(350,y,14);svg.append(f'<circle cx="350" cy="{1000-y}" r="14"/>')
def gateway(y,tx):
 pts=[(350,y+45),(410,y),(350,y-45),(290,y)]
 p=c.beginPath();p.moveTo(*pts[0])
 for v in pts[1:]:p.lineTo(*v)
 p.close();c.drawPath(p)
 svg.append('<polygon points="'+' '.join(f'{x},{1000-yy}' for x,yy in pts)+'"/>')
 label(350,y+6,tx,16)
def arrow(points):
 for a,b in zip(points,points[1:]):line(*a,*b)
 (x1,y1),(x2,y2)=points[-2:];a=math.atan2(y2-y1,x2-x1);s=9
 pts=[(x2,y2),(x2-s*math.cos(a-.4),y2-s*math.sin(a-.4)),(x2-s*math.cos(a+.4),y2-s*math.sin(a+.4))]
 p=c.beginPath();p.moveTo(*pts[0]);p.lineTo(*pts[1]);p.lineTo(*pts[2]);p.close();c.setFillColorRGB(0,0,0);c.drawPath(p,fill=1)
 svg.append('<polygon fill="black" points="'+' '.join(f'{x},{1000-y}' for x,y in pts)+'"/>')

c.rect(45,80,610,905);svg.append('<rect x="45" y="15" width="610" height="905"/>')
line(90,80,90,985)
c.saveState();c.translate(72,530);c.rotate(90);label(0,0,'Покупатель',20);c.restoreState()
# Replace the SVG label with its rotated equivalent.
svg.pop();svg.append('<text x="72" y="470" transform="rotate(-90 72 470)" text-anchor="middle" fill="black" stroke="none" font-family="Arial, sans-serif" font-size="20">Покупатель</text>')
event(950);label(415,944,'Начало',17)
task(855,'Определить условия\nвыбора')
task(755,'Открыть каталог\nи применить фильтры')
task(655,'Изучить состав\nи описание товара')
gateway(560,'Товар\nподходит?')
task(440,'Сохранить подходящий\nвариант')
gateway(345,'Достаточно\nвариантов?')
task(225,'Сравнить варианты\nи выбрать товар')
event(140,True);label(415,134,'Конец',17)
for y1,y2 in [(932,920),(855,820),(755,720),(655,605),(515,505),(440,390),(300,290),(225,158)]:arrow([(350,y1),(350,y2)])
label(374,518,'Да',16);label(374,303,'Да',16)
arrow([(290,560),(140,560),(140,687),(225,687)])
label(255,568,'Нет',16);label(190,615,'Другой\nтовар',16)
arrow([(410,345),(565,345),(565,687),(475,687)])
label(445,354,'Нет',16);label(602,510,'Другой\nтовар',16)
c.save();svg.extend(['</g>','</svg>'])
(B/'manual_selection.svg').write_text('\n'.join(svg),encoding='utf-8')
subprocess.run(['C:/Users/User/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/bin/pdftoppm.exe','-r','180','-singlefile','-png',str(B/'manual_selection.pdf'),str(B/'manual_selection')],check=True)
print('Created diagram PNG and editable SVG')
