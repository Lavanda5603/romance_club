from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
import math, subprocess
B=Path(__file__).parent
pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
def text(c,x,y,lines,size=11):
 c.setFont('Arial',size)
 for i,line in enumerate(lines.split('\n')):c.drawCentredString(x,y-i*(size+3),line)
def box(c,x,y,w,h,label,size=11):
 c.setFillColorRGB(1,1,1);c.rect(x,y,w,h,fill=1);c.setFillColorRGB(0,0,0)
 lines=label.split('\n');text(c,x+w/2,y+h/2+(len(lines)-1)*(size+3)/2-4,label,size)
def arrow(c,x1,y1,x2,y2,dashed=False):
 c.setDash(3,3) if dashed else c.setDash()
 c.line(x1,y1,x2,y2);c.setDash()
 a=math.atan2(y2-y1,x2-x1);s=6
 p=c.beginPath();p.moveTo(x2,y2);p.lineTo(x2-s*math.cos(a-.45),y2-s*math.sin(a-.45));p.lineTo(x2-s*math.cos(a+.45),y2-s*math.sin(a+.45));p.close();c.drawPath(p,fill=1)
def start(n,w,h):
 c=canvas.Canvas(str(B/f'diagram_{n}.pdf'),pagesize=(w,h));c.setLineWidth(.8);return c
def end(c,n):
 c.save()
 subprocess.run(['C:/Users/User/.cache/codex-runtimes/codex-primary-runtime/dependencies/native/poppler/Library/bin/pdftoppm.exe','-r','180','-singlefile','-png',str(B/f'diagram_{n}.pdf'),str(B/f'diagram_{n}')],check=True)

# Class dependencies, deliberately distinguish model links from dependencies.
c=start(10,600,390)
box(c,15,280,170,90,'Модели данных\nUser, Profile, Product\nRecommendation, Order',12)
box(c,220,280,170,90,'RecommendationService\nРасчёт рейтинга\n17 проверок Check*()',12)
box(c,420,280,165,90,'QuizController\nResults(Profile)\nСохранение результата',12)
box(c,205,90,200,90,'ApplicationDbContext\n11 свойств DbSet<T>\nДоступ к PostgreSQL',12)
arrow(c,420,315,390,315);text(c,405,335,'вызов',9)
arrow(c,300,280,300,180);text(c,345,220,'запрос товаров',9)
arrow(c,485,280,405,160);text(c,480,200,'запись',9)
arrow(c,205,135,100,280);text(c,130,200,'отображение\nсущностей',9)
text(c,300,35,'Кратность связей данных определяется ключами и ограничениями БД',10)
end(c,10)

c=start(11,450,650)
steps=[('Получить анкету и загрузить каталог',575),('Проверить наличие товаров',495),('Для каждого товара проверить категорию',415),('Для допустимого товара выполнить\n17 проверок и собрать пояснения',315),('Сортировать по убыванию Score',225),('Взять до 10 основных и до 50\nдополнительных товаров',135),('Вернуть RecommendationBundle',45)]
for i,(lab,y) in enumerate(steps):
 box(c,55,y,340,55,lab,12)
 if i:arrow(c,225,steps[i-1][1],225,y+55)
text(c,225,480,'Пустой каталог → пустой результат',10)
text(c,225,400,'Недопустимая категория → следующий товар',10)
end(c,11)

# BPMN-style pools with two lanes, start/end events and service/user tasks.
c=start(12,700,360)
c.rect(10,20,680,320);c.line(10,185,690,185)
c.saveState();c.translate(28,255);c.rotate(90);text(c,0,0,'Пользователь',11);c.restoreState()
c.saveState();c.translate(28,90);c.rotate(90);text(c,0,0,'Система',11);c.restoreState()
c.circle(70,265,13);box(c,110,235,145,60,'Заполнить анкету\nи отправить',12);arrow(c,83,265,110,265)
box(c,110,70,145,65,'Проверить данные\nи авторизацию',12);arrow(c,180,235,180,135)
box(c,290,70,155,65,'Рассчитать рейтинг\nи сохранить подборку',12);arrow(c,255,102,290,102)
box(c,290,235,155,60,'Посмотреть результат\nи выбрать товар',12);arrow(c,367,135,367,235)
box(c,480,235,155,60,'Добавить в корзину\nи оформить заказ',12);arrow(c,445,265,480,265)
c.circle(662,265,13);c.circle(662,265,10);arrow(c,635,265,649,265)
text(c,367,160,'Пояснения и предупреждения',10)
end(c,12)

c=start(18,760,420)
names=['Браузер','QuizController','RecommendationService','ApplicationDbContext','PostgreSQL']
xs=[70,215,375,550,690]
for x,n in zip(xs,names):
 box(c,x-65,365,130,40,n,9);c.setDash(3,3);c.line(x,360,x,20);c.setDash()
events=[(0,1,330,'POST /Quiz/Results',False),(1,2,285,'GetRecommendationsWithReasons(profile)',False),(2,3,240,'Products.ToList()',False),(3,4,205,'Запрос товаров',False),(4,2,170,'Список товаров',True),(2,1,120,'RecommendationBundle',True),(1,3,80,'Запись истории и анкеты',False),(1,0,35,'Представление результата',True)]
for a,b,y,lab,ds in events:
 arrow(c,xs[a],y,xs[b],y,ds);text(c,(xs[a]+xs[b])/2,y+9,lab,9)
text(c,430,145,'17 проверок для каждого допустимого товара',9)
end(c,18)
print('Updated four technical diagrams')

# Concise relational schema: all eleven tables, primary keys and references.
# Non-key attributes are described in the main text; references are explicit
# inside each box to keep eleven relationships legible on an A4 page.
c=start(21,660,660)
entities=[
 ('Profiles',10,510,['PK Id','FK UserId → Users']),
 ('Users',230,510,['PK Id','Email, PasswordHash']),
 ('Products',450,510,['PK Id','Name, Price']),
 ('Recommendations',10,355,['PK Id','FK UserId → Users','FK ProductId → Products']),
 ('Carts',230,355,['PK Id','FK UserId → Users','FK ProductId → Products']),
 ('Favorites',450,355,['PK Id','FK UserId → Users','FK ProductId → Products']),
 ('PromoCodes',10,200,['PK Id','Code, DiscountPercent']),
 ('Orders',230,200,['PK Id','FK UserId → Users','PromoCode: строка']),
 ('OrderItems',450,200,['PK Id','FK OrderId → Orders','FK ProductId → Products']),
 ('GiftCards',10,45,['PK Id','OwnerUserId → Users','UsedByUserId → Users']),
 ('OrderGiftCards',230,45,['PK Id','FK OrderId → Orders','FK GiftCardId → GiftCards']),
]
for name,x,y,attrs in entities:
 c.rect(x,y,200,125);c.line(x,y+96,x+200,y+96)
 text(c,x+100,y+104,name,17)
 for j,a in enumerate(attrs):text(c,x+100,y+72-j*23,a,17)
text(c,550,130,'PK – первичный ключ\nFK – внешний ключ\nСтрелка указывает\nтаблицу назначения',17)
end(c,21)
