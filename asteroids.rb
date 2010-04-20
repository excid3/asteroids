#!/usr/bin/env ruby -w

# Command line options:
#    -info      print GL implementation information

require 'opengl'
require 'glut'
include Math

# compute the sign of a number
def Sgn(value)
  if value > 0
    1
  elsif value < 0
    -1
  else
     0
  end
end

# the 'user' in the game
# a ship can turn
# a ship can accelerate (naturally decellerates)
# a ship can move (does so automatically)
# radius value is for detecting collisions
class Ship
  def initialize(game)
    @radius = 0.5
    @xCenter = 0
    @yCenter = 0
    @direction = 0
    @xDelta = 0
    @yDelta = 0
    @speed = 0
    @game = game
  end #initialize

  attr_reader :xCenter, :yCenter, :direction

  # change ship's speed (called by game in key method)
  def accellerate
    @xDelta += 0.05 * -Math.sin(@direction/180*3.1415)
    @yDelta += 0.05 * Math.cos(@direction/180*3.1415)

    # the ship's acceleration is limited
    @xDelta = 0.3 if @xDelta > 0.3
    @yDelta = 0.3 if @yDelta > 0.3
    @xDelta = -0.3 if @xDelta < -0.3
    @yDelta = -0.3 if @yDelta < -0.3
  end

  # adjust center of object to update position
  def move
    @xCenter += @xDelta
    @yCenter += @yDelta

    # a ship slows over time, so less delta
    @xDelta -= 0.001*Sgn(@xDelta)
    @yDelta -= 0.001*Sgn(@yDelta)

    # the world wraps around
    # adjust position of object to other side of screen
    # if you exit screen left, you enter screen right (etc)
    @xCenter -= 2*@game.xMax if @xCenter > @game.xMax
    @yCenter -= 2*@game.yMax if @yCenter > @game.yMax
    @xCenter += 2*@game.xMax if @xCenter < -@game.xMax
    @yCenter += 2*@game.yMax if @yCenter < -@game.yMax
  end

  # change ship's orientation (called by game in key method)
  def rotate(angle)
    @direction += angle
  end

  # adjust center of object to update position
  def draw
    GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)
    GL.Rotate(@direction.to_f, 0.0, 0.0, 1.0)

    GL.Color3b(255, 255, 255) #WHITE

    GL.Begin(GL::LINE_LOOP)
        GL.Vertex2f( 0.0,  1.2)
        GL.Vertex2f( 0.8, -1.2)
        GL.Vertex2f( 0.0, -0.4)
        GL.Vertex2f(-0.8, -1.2)
    GL.End()
    GL.PopMatrix()
  end #draw

end

# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class SmallAsteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
    @radius = 0.5
    @xCenter = init_x
    @yCenter = init_y
    @xDelta = delta_x
    @yDelta = delta_y
    @game = game
  end #initialize

  # adjust center of object to update position
  def move
    @xCenter += @xDelta
    @yCenter += @yDelta

    # the world wraps around
    # adjust position of object to other side of screen
    # if you exit screen left, you enter screen right (etc)
    @xCenter -= 2*@game.xMax if @xCenter > @game.xMax
    @yCenter -= 2*@game.yMax if @yCenter > @game.yMax
    @xCenter += 2*@game.xMax if @xCenter < -@game.xMax
    @yCenter += 2*@game.yMax if @yCenter < -@game.yMax
  end

  # make pixels on the screen
  # no need to change this
  def draw
    GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)

    GL.Color3b(255, 255, 255) #WHITE

    GL.Begin(GL::LINE_LOOP)
        GL.Vertex2f( 0.5,  0.5)
        GL.Vertex2f( 0.5, -0.5)
        GL.Vertex2f(-0.5, -0.5)
        GL.Vertex2f(-0.5,  0.5)
    GL.End()
    GL.PopMatrix()
  end #draw

end #SmallAsteroid

# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class MediumAsteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
    @radius = 1
    @xCenter = init_x
    @yCenter = init_y
    @xDelta = delta_x
    @yDelta = delta_y
    @game = game
  end #initialize

  # adjust center of object to update position
  def move
    @xCenter += @xDelta
    @yCenter += @yDelta

    # the world wraps around
    # adjust position of object to other side of screen
    # if you exit screen left, you enter screen right (etc)
    @xCenter -= 2*@game.xMax if @xCenter > @game.xMax
    @yCenter -= 2*@game.yMax if @yCenter > @game.yMax
    @xCenter += 2*@game.xMax if @xCenter < -@game.xMax
    @yCenter += 2*@game.yMax if @yCenter < -@game.yMax
  end

  # make pixels on the screen
  # no need to change this
  def draw
    GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)

    GL.Color3b(255, 255, 255) #WHITE

    GL.Begin(GL::LINE_LOOP)
        GL.Vertex2f( 1.0,  1.0)
        GL.Vertex2f( 0.5,  0.5)
        GL.Vertex2f( 1.0,  -1.0)
        GL.Vertex2f( 0.5, -0.5)
        GL.Vertex2f( -1.0,  -1.0)
        GL.Vertex2f(-0.5, -0.5)
        GL.Vertex2f(-0.5,  0.5)
    GL.End()
    GL.PopMatrix()
  end #draw

end #MediumAsteroid


# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class LargeAsteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
    @radius = 1.5
    @xCenter = init_x
    @yCenter = init_y
    @xDelta = delta_x
    @yDelta = delta_y
    @game = game
  end #initialize

  # adjust center of object to update position
  def move

    @xCenter += @xDelta
    @yCenter += @yDelta

    # the world wraps around
    # adjust position of object to other side of screen
    # if you exit screen left, you enter screen right (etc)

    @xCenter -= 2*@game.xMax if @xCenter > @game.xMax
    @yCenter -= 2*@game.yMax if @yCenter > @game.yMax
    @xCenter += 2*@game.xMax if @xCenter < -@game.xMax
    @yCenter += 2*@game.yMax if @yCenter < -@game.yMax

  end

  # make pixels on the screen
  # no need to change this
  def draw
    GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)

    GL.Color3b(255, 255, 255) #WHITE

    GL.Begin(GL::LINE_LOOP)
        GL.Vertex2f( 1.0,  1.0)
        GL.Vertex2f( 1.5,  1.5)
        GL.Vertex2f( 1.0,  -1.0)
        GL.Vertex2f( 1.5, -1.5)
        GL.Vertex2f( -1.0,  -1.0)
        GL.Vertex2f(-1.0, -1.5)
        GL.Vertex2f(-1.5,  1.5)
    GL.End()
    GL.PopMatrix()
  end #draw
end

# PTorpedo - photon torpedo
# always starts at the ship's center
# moves in the direction of the ship (at the time when PTorpedo object created)
# must know it's ship when created
class PTorpedo
  def initialize(ship, game)
    @radius = 0.001
    @xCenter = ship.xCenter
    @yCenter = ship.yCenter
    @xDelta = 0.5 * -Math.sin(ship.direction/180*3.1415)
    @yDelta = 0.5 * Math.cos(ship.direction/180*3.1415)
    @game = game
  end #initialize


  # adjust center of object to update position
  def move

    @xCenter += @xDelta
    @yCenter += @yDelta

    # TODO: destroy this object if @xCenter > @game.xMax
    # TODO: destroy this object if @yCenter > @game.yMax
  end

  # make pixels on the screen
  # no need to change this
  def draw
    GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)

    GL.Color3b(255, 255, 255) #WHITE
    GL.Begin(GL::QUADS)
        GL.Vertex2f( 0.1,  0.1)
        GL.Vertex2f( 0.1, -0.1)
        GL.Vertex2f(-0.1, -0.1)
        GL.Vertex2f(-0.1,  0.1)
    GL.End()

    GL.PopMatrix()
  end #draw

end #PTorpedo

# Game has many purposes
# keeps track of the asteroids
# keeps track of the ship
# keeps track of the photon torpedo
# draws everything as needed
# where the window is created when the game starts

class Game

  attr_reader :xMax, :yMax

  def draw
    GL.Clear(GL::COLOR_BUFFER_BIT )

    @ship.draw
    @asteroids.each do |go|
      go.draw
    end

    @torpedo.draw if defined? @torpedo

    GLUT.SwapBuffers()

    @frames += 1
    t = GLUT.Get(GLUT::ELAPSED_TIME)

    if t - @t0 >= 5000
      seconds = (t - @t0) / 1000.0
      fps = @frames / seconds
      printf("%d frames in %6.3f seconds = %6.3f FPS\n",
        @frames, seconds, fps)

      @t0, @frames = t, 0
    end

  end

  # idle()
  # is called when there is nothing else to do
  # checks the time to see if positions should be updated
  # when necessary, moves everything and then re-draws them

  def idle

    t = GLUT.Get(GLUT::ELAPSED_TIME)

    if t - @lastMove > 10
       @lastMove = t  
       GLUT.PostRedisplay()
       move
    end

  end

  # move()
  # update the postion of all moveable objects in the game
  def move

    @ship.move

    @asteroids.each do |go|
      go.move
    end

    @torpedo.move if defined? @torpedo

  end

  # respond to keypresses
  # ship movement, torpedo fire
  # ESC to terminate
  def key(k, x, y)
    case k
      when ?j
        @ship.rotate(5.0)
      when ?k
        @ship.rotate(-5.0)
      when ?h
        @ship.accellerate
      when ?l
        @torpedo = PTorpedo.new(@ship, self)
      when 27 # Escape
        exit
    end
    GLUT.PostRedisplay()
  end

  # New window size or exposure
  # don't mess with this code
  def reshape(width, height)
    h = height.to_f / width.to_f
    GL.Viewport(0, 0, width, height)
    GL.MatrixMode(GL::MODELVIEW)
    GL.LoadIdentity()
    GL.Scale(0.05, 0.05, 1)
  end

  # initialize the graphics system
  # don't mess with this code
  def init

    @t0 = 0
    @frames = 0
    @lastMove = 0

    GL.Enable(GL::LIGHTING)
    GL.Enable(GL::LIGHT0)

    ARGV.each do |arg|
      case arg
        when '-info'
          printf("GL_RENDERER   = %s\n", GL.GetString(GL::RENDERER))
          printf("GL_VERSION    = %s\n", GL.GetString(GL::VERSION))
          printf("GL_VENDOR     = %s\n", GL.GetString(GL::VENDOR))
          printf("GL_EXTENSIONS = %s\n", GL.GetString(GL::EXTENSIONS))
      end
    end
  end

  # don't mess with this code
  def visible(vis)
    GLUT.IdleFunc((vis == GLUT::VISIBLE ? method(:idle).to_proc : nil))
  end


  # initialize the game object
  # there are things you would change in this method (maybe)

  def initialize
    @xMax = 22
    @yMax = 22

    @asteroids = Array.new

    @ship = Ship.new(self)
    @asteroids[0] = SmallAsteroid.new(2, 3, 0.05, 0.05, self)
    @asteroids[1] = SmallAsteroid.new(3, 2, -0.05, -0.05, self)
    @asteroids[2] = MediumAsteroid.new(3, -2, 0.05, -0.05, self)
    @asteroids[3] = LargeAsteroid.new(-3, -2, 0.0, -0.05, self)

    # the beginning of the graphics stuff
    # leave this alone

    GLUT.Init()
    GLUT.InitDisplayMode(GLUT::RGB | GLUT::DOUBLE)

    GLUT.InitWindowPosition(0, 0)
    GLUT.InitWindowSize(500, 500)
    GLUT.CreateWindow('Asteroids')
    init()

    GLUT.DisplayFunc(method(:draw).to_proc)
    GLUT.ReshapeFunc(method(:reshape).to_proc)
    GLUT.KeyboardFunc(method(:key).to_proc)
    GLUT.VisibilityFunc(method(:visible).to_proc)
  end

  def start
    GLUT.MainLoop()
  end

end


# here is where the game starts
# one game object

game = Game.new
game.start
