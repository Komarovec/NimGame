import csfml

# Constants
const
  VEL_MULTIPLIER = 3

# Types
type
  Separator* = ref object
    pos*: Vector2f
    size*: Vector2i
    texture*: Texture
    scale*: float

  Box* = ref object
    pos*: Vector2f
    size*: Vector2i
    velocity*: Vector2f
    texture*: Texture
    scale*: float
    dragged*: bool
    draggedPoint*: Vector2f
    bounce*: float
    grounded*: bool
    lastPos*: Vector2f
    isThrown*: bool
    isBase*: bool
    isTower*: bool
    isTopTower*: bool
    isStatic*: bool

#[
#---------------------------                       ---------------------------#
#---------------------------       Separator       ---------------------------#
#---------------------------                       ---------------------------#
]#
# Paint separator
proc paint*(b: Separator; window: RenderWindow) =
  let mySepa = new_Sprite(b.texture)
  mySepa.position = b.pos
  mySepa.scale = vec2(b.scale,b.scale)
  window.draw mySepa

  mySepa.destroy()

# Return true if box is in the separator
proc boxCollision*(s: Separator; b: Box): bool =
  if(b.pos.x + b.size.x.float > s.pos.x and b.pos.x < s.pos.x + s.size.x.float and b.pos.y + b.size.y.float > s.pos.y and b.pos.y < s.pos.y + s.size.y.float):
    return true
  else:
    return false

# Instantiate new box
proc newSeparator*(scale: float = 1.0, wsize: Vector2i): Separator =
  new result
  result.texture = new_Texture("resources/separator.png")
  result.size = vec2((result.texture.size.x.float*scale).int, (result.texture.size.y.float*scale).int)
  result.scale = scale
  result.pos = vec2(wsize.x/2-result.size.x/2, (wsize.y-result.size.y).float)


#[
#---------------------------                       ---------------------------#
#---------------------------          Box          ---------------------------#
#---------------------------                       ---------------------------#
]#
# Paint box
proc paint*(b: Box; window: RenderWindow; dt: float) =
  if(not b.isStatic):
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

# Return true if points is in the box
proc collision*(b: Box; pos: Vector2f): bool =
  if(pos.x < b.pos.x + b.size.x.float and 
    pos.x > b.pos.x and 
    pos.y < b.pos.y+b.size.y.float and 
    pos.y > b.pos.y): return true
  else: return false

# Instantiate new box
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
  result.isThrown = false
  result.isTower = false
  result.isTopTower = false
  result.isBase = false
  result.isStatic = false