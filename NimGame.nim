import csfml

# Render init
var window = new_RenderWindow(
    video_mode(1000, 1000), "Boxes",
    WindowStyle.Default, context_settings(32, antialiasing=8)
)
#window.framerate_limit = 120

# Types
type
  Box = ref object
    pos: Vector2f
    size: Vector2i
    velocity: Vector2f
    texture: Texture
    scale: float
    dragged: bool
    draggedPoint: Vector2f

proc paint*(b: Box; window: RenderWindow; dt: float) =
  let acc = vec2((b.velocity.x/2)*dt,(b.velocity.y/2)*dt)
  
  b.pos.x -= acc.x
  b.pos.y -= acc.y
  b.velocity.x -= acc.x
  b.velocity.y -= acc.y

  let myRect = new_Sprite(b.texture)
  myRect.position = b.pos
  myRect.scale = vec2(b.scale,b.scale)
  window.draw myRect

proc collision*(b: Box; pos: Vector2f): bool =
  if(pos.x < b.pos.x + b.size.x.float and 
    pos.x > b.pos.x and 
    pos.y < b.pos.y+b.size.y.float and 
    pos.y > b.pos.y): return true
  else: return false

proc newBox*(pos: Vector2i, scale: float = 1.0): Box =
  new result
  result.pos = pos
  result.velocity = vec2(0,0)
  result.texture = new_Texture("resources/box.png")
  result.size = vec2((result.texture.size.x.float*scale).int, (result.texture.size.y.float*scale).int)
  result.scale = scale
  result.dragged = false
  result.draggedPoint = vec2(0.0,0.0)


# Objects
var myBox = newBox(vec2(100,100), 0.5)

# Help vars/objs
var 
  clock = newClock()
  lastMousePos = vec2(0.0,0.0)
  wallTexture = new_Texture("resources/wall.jpg")

# Constants
const
  DRAG = 0.8
  THROW_MULTIPLIER = 0.1

# Loop
while window.open:
  # Delta Time
  let deltaTime = clock.restart().asSeconds

  # Event handling
  var event: Event
  while window.pollEvent event:
    if event.kind == EventType.Closed:
      window.close()

    # MouseButton press -> Start dragging  
    elif event.kind == EventType.MouseButtonPressed:
      if(myBox.collision(vec2(event.mouseButton.x,event.mouseButton.y))):
        myBox.dragged = true
        myBox.velocity = vec2(0,0)
        myBox.draggedPoint = vec2(event.mouseButton.x.float - myBox.pos.x, event.mouseButton.y.float - myBox.pos.y)

        lastMousePos = vec2(event.mouseButton.x, event.mouseButton.y)

    # MouseButton released -> Stop dragging
    elif event.kind == EventType.MouseButtonReleased:
      if(myBox.dragged):
        myBox.dragged = false
  
        let distance = vec2(lastMousePos.x-event.mouseButton.x.float,
          lastMousePos.y-event.mouseButton.y.float)
        
        myBox.velocity.x = (distance.x / deltaTime) * THROW_MULTIPLIER
        myBox.velocity.y = (distance.y / deltaTime) * THROW_MULTIPLIER

    # MouseMove -> Recalculate dragging coords
    elif event.kind == EventType.MouseMoved:
      if(myBox.dragged):
        lastMousePos = vec2(myBox.pos.x + myBox.draggedPoint.x, myBox.pos.y + myBox.draggedPoint.y)
        myBox.pos = vec2(event.mouseMove.x.float - myBox.draggedPoint.x, event.mouseMove.y.float - myBox.draggedPoint.y)

  # Gravity
  if(not myBox.dragged):
    myBox.velocity.y += -2

  # Screen borders
  if((myBox.pos.x+myBox.size.x.float) >  window.size.x.float):
    myBox.pos.x =  (window.size.x-myBox.size.x).float
    myBox.velocity.x = -(myBox.velocity.x*DRAG)

  if((myBox.pos.y+myBox.size.y.float) >  window.size.y.float):
    myBox.pos.y =  (window.size.y-myBox.size.y).float
    myBox.velocity.y = -(myBox.velocity.y*DRAG)
    myBox.velocity.x = myBox.velocity.x*DRAG

  if(myBox.pos.x < 0):
    myBox.pos.x = 0
    myBox.velocity.x = -(myBox.velocity.x*DRAG)

  if(myBox.pos.y < 0):
    myBox.pos.y = 0
    myBox.velocity.y = -(myBox.velocity.y*DRAG)

  # Paint objects
  #window.clear color(112, 197, 206)
  let wall = new_Sprite(wallTexture)
  window.draw wall

  myBox.paint(window, deltaTime)

  window.display()

window.destroy()