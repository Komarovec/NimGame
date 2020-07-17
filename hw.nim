import csfml

var window = new_RenderWindow(
    video_mode(800, 800), "Snakes",
    WindowStyle.Default, context_settings(32, antialiasing=8)
)

type
  Box = ref object
    pos: Vector2i
    size: Vector2i
    velocity: Vector2f
    color: Color

proc paint*(b: Box; canvas: Canvas) =
  let acc = vec2((b.velocity.x/2),(b.velocity.y/2))
  
  b.pos.x -= acc.x
  b.pos.x -= acc.y
  b.velocity.x -= acc.x
  b.velocity.y -= acc.y

  canvas.areaColor = rgb(r.color[0],r.color[1],r.color[2]) # red
  canvas.drawRectArea(r.pos[0],r.pos[1],r.size[0],r.size[1])

proc collision*(b: Box; pos: openArray[int]): bool =
  if(pos[0] < r.pos[0] + r.size[0] and 
    pos[0] > r.pos[0] and 
    pos[1] < r.pos[1]+r.size[1] and 
    pos[1] > r.pos[1]): return true
  else: return false

proc newBox(pos: Vector2i, size: Vector2i, color: Color): Box =
  new result
  result.pos = pos
  result.size = size
  result.color = color
  result.velocity = vec2(0,0)

var myBox = newBox(vec2(100,100),vec2(200,200),color(255,0,0))

while window.open:
  var event: Event
  while window.pollEvent event:
    if event.kind == EventType.Closed:
      window.close()

  var myRect = newRectangleShape(size=myBox.size)
  myRect.position = myBox.pos
  myRect.fillColor = myBox.color
  window.draw myRect

  window.display()

window.destroy()

#[

# Game object; classes
type
  Rect* = ref object of RootObj
    pos*: array[2, int]
    size*: array[2, int]
    color*: array[3, byte]
    velocity*: array[2, int]
    dragged*: bool

proc paint*(r: Rect; canvas: Canvas) =
  let acc = [(r.velocity[0]/2).int,(r.velocity[1]/2).int]
  
  r.pos[0] -= acc[0]
  r.pos[1] -= acc[1]
  r.velocity[0] -= acc[0]
  r.velocity[1] -= acc[1]

  canvas.areaColor = rgb(r.color[0],r.color[1],r.color[2]) # red
  canvas.drawRectArea(r.pos[0],r.pos[1],r.size[0],r.size[1])

proc collision*(r: Rect; pos: openArray[int]): bool =
  if(pos[0] < r.pos[0] + r.size[0] and 
    pos[0] > r.pos[0] and 
    pos[1] < r.pos[1]+r.size[1] and 
    pos[1] > r.pos[1]): return true
  else: return false

# Game objects
var myRect: Rect
new myRect
myRect.pos = [20,20]
myRect.size = [60,60]
myRect.color = [255.byte,255.byte,255.byte]
myRect.velocity = [0,0]
myRect.dragged = false

# Draw
control1.onDraw = proc (event: DrawEvent) =
  let canvas = event.control.canvas
  canvas.areaColor = rgb(30, 30, 30) # dark grey
  canvas.fill()

  mousePos = mouse_ge

  # Paint objects
  if(myRect.dragged):
    myRect.pos[0] = mousePos[0]
    myRect.pos[1] = mousePos[1]

  myRect.paint(canvas)

  # Gravity
  myRect.velocity[1] += -10

  # Dont fall off the screen
  if((myRect.pos[0]+myRect.size[0]) >= canvas.height):
    myRect.pos[0] = canvas.height-myRect.size[0]
    myRect.velocity[0] = 0

  if((myRect.pos[1]+myRect.size[1]) >= canvas.height):
    myRect.pos[1] = canvas.height-myRect.size[1]
    myRect.velocity[1] = 0

# User input
control1.onMouseButtonDown = proc (event: MouseEvent) =
  echo(event.button, " (", event.x, ", ", event.y, ")") 
  echo mousePos

  # Drag object
  if(myRect.dragged):
    myRect.dragged = false
  else:
    myRect.dragged = myRect.collision([event.x,event.y])

# Timer
var timer: Timer

proc timerProc(event: TimerEvent) =
  control1.forceRedraw()

timer = startRepeatingTimer(12, timerProc)

window.show()
app.run()

]#