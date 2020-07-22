import csfml
import gameObjects

# Render init
var window = new_RenderWindow(
    video_mode(1400, 1000), "Boxes",
    WindowStyle.Titlebar|WindowStyle.Close, context_settings(32, antialiasing=8)
)
window.framerate_limit = 200

# Procedures declaration
proc calculatePhysics()
proc handleEvents(event: Event, deltaTime: float)
proc respawnBox()
proc restartGame()

# Help vars/objs
var 
  clock = newClock()
  lastMousePos = vec2(0.0,0.0)
  wallTexture = new_Texture("resources/wall.jpg")
  difficulty = 1
  difficultyOffset = 1
  towerHeight = 0

# Constants
const
  THROW_MULTIPLIER = 0.3
  GRAVITY_FORCE = -5

# Objects
var boxes: seq[Box] = @[]
var sepa = newSeparator(1, window.size)
var baseBox: Box

# Start game logic
restartGame()

#[
#---------------------------                       ---------------------------#
#---------------------------       Game Loop       ---------------------------#
#---------------------------                       ---------------------------#
]#

while window.open:
  # Delta Time
  let deltaTime = clock.restart().asSeconds

  # Event handling
  var event: Event
  while window.pollEvent event:
    handleEvents(event, deltaTime)

  # Do physics
  calculatePhysics()

  # Paint background
  let wall = new_Sprite(wallTexture)
  wall.scale = vec2(1,1)
  wall.position = vec2(-(wall.texture.size.x - window.size.x)/2,0)
  window.draw wall
  wall.destroy()

  # Create separator
  sepa.paint(window)

  # Paint boxes
  for box in boxes.items:
    box.paint(window, deltaTime)

  window.display()
window.destroy()



#[
#---------------------------                       ---------------------------#
#--------------------------- Procedure definitions ---------------------------#
#---------------------------                       ---------------------------#
]#

# Respawn box
proc respawnBox() =
  if(boxes.len >= 3):
    for box in boxes.items:
      box.isStatic = true
    boxes[^1].isStatic = false
    boxes[^2].isStatic = false
  boxes.add(newBox(vec2(100,-300), 1/(difficulty+difficultyOffset)))

# Restart box
proc restartGame() =
  # Objects
  boxes = @[]
  respawnBox()

  # Base Box
  baseBox = newBox(vec2(((sepa.pos.x.float + sepa.size.x.float + window.size.x.float)/2 - boxes[0].size.x/2).int, window.size.y - boxes[0].size.y - 1), 1/(difficulty+difficultyOffset))
  baseBox.isTower = true
  baseBox.isTopTower = true
  baseBox.isBase = true
  boxes.add(baseBox)

  towerHeight = baseBox.size.y

# Does physics? somehow...
proc calculatePhysics() =
  var toDelete: seq[int] = @[]
  var spawnNewBox = false
  var restartGame = false

  # Box physics
  for boxi, box in boxes.pairs:
    # Gravity
    if(not (box.dragged or box.grounded)):
      box.velocity.y += GRAVITY_FORCE

    # Screen borders
    if((box.pos.x+box.size.x.float) >  window.size.x.float):
      if(box.isThrown):
        if(box.isTower):
          restartGame = true
        else:
          toDelete.add(boxi)
      box.pos.x =  (window.size.x-box.size.x).float
      box.velocity.x = -(box.velocity.x*box.bounce)
    if((box.pos.y+box.size.y.float) >  window.size.y.float):
      if(box.isThrown):
        if(box.isTower and not box.isBase):
          restartGame = true
        else:
          toDelete.add(boxi)
      box.pos.y =  (window.size.y-box.size.y).float
      box.velocity.y = -(box.velocity.y*box.bounce)
      box.velocity.x = box.velocity.x*box.bounce
    if(box.pos.x < 0):
      if(box.isThrown):
        if(box.isTower):
          restartGame = true
        else:
          toDelete.add(boxi)
      box.pos.x = 0
      box.velocity.x = -(box.velocity.x*box.bounce)
    #[if(box.pos.y < 0): # TOP BORDER
      box.pos.y = 0
      box.velocity.y = -(box.velocity.y*box.bounce)]#

    # Separator collision
    if(sepa.boxCollision(box)):
      toDelete.add(boxi)

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

        # Flag tower if static and on top
        if(not (box.isTower and box2.isTower)):
          if(box.isTopTower and abs(box2.velocity.x) + abs(box2.velocity.y) < 5):
            box2.isTower = true
            box2.isTopTower = true
            box.isTopTower = false
            spawnNewBox = true
            # Check if end game -> increase difficulty
            towerHeight += box2.size.y
            if(towerHeight > sepa.size.y):
              inc(difficulty)
              restartGame = true

          elif(box2.isTopTower and abs(box.velocity.x) + abs(box.velocity.y) < 5):
            box.isTower = true
            box.isTopTower = true
            box2.isTopTower = false
            spawnNewBox = true
            # Check if end game -> increase difficulty
            towerHeight += box.size.y
            if(towerHeight > sepa.size.y):
              inc(difficulty)
              restartGame = true

          # If box landed not on top, restart game
          if(not(box.isTopTower or box2.isTopTower)):
            restartGame = true

  # Delete tagged boxes
  for boxi in toDelete:
    boxes.delete(boxi)
    respawnBox()

  # Spawn new box
  if(spawnNewBox):
    respawnBox()

  # Restart
  if(restartGame):
    restartGame()

# Handle user inputs
proc handleEvents(event: Event, deltaTime: float) =
  if event.kind == EventType.Closed:
    window.close()

  # MouseButton press -> Start dragging  
  elif event.kind == EventType.MouseButtonPressed:
    for box in boxes.items:
      if(box.collision(vec2(event.mouseButton.x,event.mouseButton.y))):
        if(box.isTower or box.isThrown): continue
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

        box.isThrown = true

  # MouseMove -> Recalculate dragging coords
  elif event.kind == EventType.MouseMoved:
    var toDelete: seq[int] = @[]
    for boxi, box in boxes.pairs:
      if(box.dragged):
        if(event.mouseMove.y.float < sepa.pos.y):
          toDelete.add(boxi)
        else:
          lastMousePos = vec2(box.pos.x + box.draggedPoint.x, box.pos.y + box.draggedPoint.y)
          box.pos = vec2(event.mouseMove.x.float - box.draggedPoint.x, event.mouseMove.y.float - box.draggedPoint.y)
    for boxi in toDelete.items:
      boxes.del(boxi)
      respawnBox()