import csfml

# Render init
var window = new_RenderWindow(
    video_mode(1400, 1000), "Boxes",
    WindowStyle.Titlebar|WindowStyle.Close, context_settings(32, antialiasing=8)
)
window.framerate_limit = 200

# Help vars/objs
var 
  clock = newClock()
  lastMousePos = vec2(0.0,0.0)
  wallTexture = new_Texture("resources/wall.jpg")

# Constants
const
  THROW_MULTIPLIER = 0.3
  COLLISION_TOLERANCE = 1
  VEL_MULTIPLIER = 3
  RATION_DRAG_BORDER = 100
  GRAVITY_FORCE = -5

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
    bounce: float
    grounded: bool
    lastPos: Vector2f

proc paint*(b: Box; window: RenderWindow; dt: float) =
  let acc = vec2((b.velocity.x),(b.velocity.y))
  b.lastPos.x = b.pos.x
  b.lastPos.y = b.pos.y

  b.pos.x -= acc.x*dt*VEL_MULTIPLIER
  b.pos.y -= acc.y*dt*VEL_MULTIPLIER
  b.velocity.x -= acc.x/100
  b.velocity.y -= acc.y/100

  if(abs(b.lastPos.x - b.pos.x) < 0.01 and abs(b.lastPos.y - b.pos.y) < 0.01 and abs((b.pos.y + b.size.y.float) - window.size.y.float) <= 2):
    b.grounded = true
  else:
    b.grounded = false

  #if(abs(b.lastPos.x - b.pos.x) != 0 or abs(b.lastPos.y - b.pos.y) != 0):
  #  echo abs(b.lastPos.x - b.pos.x), " ", abs(b.lastPos.y - b.pos.y)

  let myRect = new_Sprite(b.texture)
  myRect.position = b.pos
  myRect.scale = vec2(b.scale,b.scale)
  window.draw myRect

  myRect.destroy()

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
  result.bounce = 0.3
  result.grounded = false
  result.lastPos = vec2(0,0)


# Objects
var boxes = @[newBox(vec2(100,300), 0.5),newBox(vec2(600,300), 0.5),newBox(vec2(1000,300), 0.5)]

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
      for box in boxes.items:
        if(box.collision(vec2(event.mouseButton.x,event.mouseButton.y))):
          box.dragged = true
          box.velocity = vec2(0,0)
          box.draggedPoint = vec2(event.mouseButton.x.float - box.pos.x, event.mouseButton.y.float - box.pos.y)

          lastMousePos = vec2(event.mouseButton.x, event.mouseButton.y)

    # MouseButton released -> Stop dragging
    elif event.kind == EventType.MouseButtonReleased:
      for box in boxes.items:
        if(box.dragged):
          box.dragged = false
    
          let distance = vec2(lastMousePos.x-event.mouseButton.x.float,
            lastMousePos.y-event.mouseButton.y.float)
          
          box.velocity.x = (distance.x / deltaTime) * THROW_MULTIPLIER
          box.velocity.y = (distance.y / deltaTime) * THROW_MULTIPLIER

    # MouseMove -> Recalculate dragging coords
    elif event.kind == EventType.MouseMoved:
      for box in boxes.items:
        if(box.dragged):
          lastMousePos = vec2(box.pos.x + box.draggedPoint.x, box.pos.y + box.draggedPoint.y)
          box.pos = vec2(event.mouseMove.x.float - box.draggedPoint.x, event.mouseMove.y.float - box.draggedPoint.y)
  
  # Paint background
  let wall = new_Sprite(wallTexture)
  wall.scale = vec2(0.7,0.7)
  window.draw wall
  wall.destroy()

  for box in boxes.items:
    # Gravity
    if(not (box.dragged or box.grounded)):
      box.velocity.y += GRAVITY_FORCE

    # Screen borders
    if((box.pos.x+box.size.x.float) >  window.size.x.float):
      box.pos.x =  (window.size.x-box.size.x).float
      box.velocity.x = -(box.velocity.x*box.bounce)
    if((box.pos.y+box.size.y.float) >  window.size.y.float):
      box.pos.y =  (window.size.y-box.size.y).float
      box.velocity.y = -(box.velocity.y*box.bounce)
      box.velocity.x = box.velocity.x*box.bounce
    if(box.pos.x < 0):
      box.pos.x = 0
      box.velocity.x = -(box.velocity.x*box.bounce)
    if(box.pos.y < 0):
      box.pos.y = 0
      box.velocity.y = -(box.velocity.y*box.bounce)
    
    # Box collisions
    for box2 in boxes.items:
      if(box == box2): continue
      if(box.pos.x < box2.pos.x + box2.size.x.float and box.pos.x > box2.pos.x - box2.size.x.float and
         box.pos.y < box2.pos.y + box2.size.y.float and box.pos.y > box2.pos.y - box2.size.y.float):
        
        # Measure from which side collision happend
        var deltaY = 0.0
        if(abs(box.pos.y-box2.pos.y) > box.size.y.float-abs(box.pos.y-box2.pos.y)):
          deltaY = box.size.y.float-abs(box.pos.y-box2.pos.y)
        else:
          deltaY = abs(box.pos.y-box2.pos.y)

        var deltaX = 0.0
        if(abs(box.pos.x-box2.pos.x) > box.size.x.float-abs(box.pos.x-box2.pos.x)):
          deltaX = box.size.x.float-abs(box.pos.x-box2.pos.x)
        else:
          deltaX = abs(box.pos.x-box2.pos.x)

        # Apply collisions tolerence
        if(deltaX < deltaY):
          if(box.pos.x > box2.pos.x):
            if(abs(box.velocity.x) > abs(box2.velocity.x)):
              box.pos.x = box2.pos.x + box.size.x.float
            else:
              box2.pos.x = box.pos.x - box2.size.x.float
          else:
            if(abs(box.velocity.x) > abs(box2.velocity.x)):
              box.pos.x = box2.pos.x - box.size.x.float
            else:
              box2.pos.x = box.pos.x + box2.size.x.float
        else:
          if(box.pos.y > box2.pos.y):
            if(abs(box.velocity.y) > abs(box2.velocity.y)):
              box.pos.y = box2.pos.y + box.size.y.float
            else:
              box2.pos.y = box.pos.y - box2.size.y.float
          else:
            if(abs(box.velocity.y) > abs(box2.velocity.y)):
              box.pos.y = box2.pos.y - box.size.y.float
            else:
              box2.pos.y = box.pos.y + box2.size.y.float

        # Calculate collision forces
        let pomVel1 = box.velocity.x
        let pomVel2 = box2.velocity.x
        box.velocity.x = (1-box.bounce)*pomVel2 - box.bounce*pomVel1
        box2.velocity.x = (1-box.bounce)*pomVel1 - box.bounce*pomVel2

        let pomyVel1 = box.velocity.y
        let pomyVel2 = box2.velocity.y
        box.velocity.y = (1-box.bounce)*pomyVel2 - box.bounce*pomyVel1
        box2.velocity.y = (1-box.bounce)*pomyVel1 - box.bounce*pomyVel2

    box.paint(window, deltaTime)

  window.display()

window.destroy()