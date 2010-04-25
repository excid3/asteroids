#!/usr/bin/env ruby -w

# Command line options:
#    -info      print GL implementation information

require 'opengl'
require 'glut'
require 'time'
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

# Graphical Object Class
# provides generic functionality for objects
class GObject

  # So that we can read these publicly
  attr_reader :xCenter, :yCenter, :radius

  # initialize the object
  # sets the item's parent game, initial position, change in positions and radius
  def initialize(game, init_x, init_y, delta_x, delta_y, radius, verticies, type)
	@game = game
	@xCenter = init_x
    @yCenter = init_y
    @xDelta = delta_x
    @yDelta = delta_y
	@radius = radius
	@verticies = verticies
	@type = type
  end
  
  # generic draw function which draws a given set of verticies and a type with optional rotation
  def draw(rotate=nil)
	GL.PushMatrix()
    GL.Translate(@xCenter, @yCenter, 0)
	GL.Rotate(*rotate) if rotate

    GL.Color3b(255, 255, 255) #WHITE

    GL.Begin(@type)
		@verticies.each { |x, y| GL.Vertex2f(x,y) }
    GL.End()
    GL.PopMatrix()
  end
  
  # move the object to its next location
  def move
    @xCenter += @xDelta
    @yCenter += @yDelta
  end
  
  # wrap the object around the screen
  # typically used in a custom draw function at the end
  def wrap
    # the world wraps around
    # adjust position of object to other side of screen
    # if you exit screen left, you enter screen right (etc)
    @xCenter -= 2*@game.xMax if @xCenter > @game.xMax
    @yCenter -= 2*@game.yMax if @yCenter > @game.yMax
    @xCenter += 2*@game.xMax if @xCenter < -@game.xMax
    @yCenter += 2*@game.yMax if @yCenter < -@game.yMax
  end
end

# the 'user' in the game
# a ship can turn
# a ship can accelerate (naturally decellerates)
# a ship can move (does so automatically)
# radius value is for detecting collisions
class Ship < GObject

  attr_reader :direction
  attr_accessor :destroyed # allows game to set the ship as destroyed

  def initialize(game)
    @direction = 0
    @speed = 0
	@destroyed = nil
    super(game, 0, 0, 0, 0, 0.5, game.ship_verticies, GL::LINE_LOOP)
  end #initialize

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
	super

    # a ship slows over time, so less delta
    @xDelta -= 0.001*Sgn(@xDelta)
    @yDelta -= 0.001*Sgn(@yDelta)

    wrap
  end

  # change ship's orientation (called by game in key method)
  def rotate(angle)
    @direction += angle
  end

  # adjust center of object to update position
  def draw
    if not @destroyed
		super([@direction.to_f, 0.0, 0.0, 1.0])
	else	
		# Player is dead
		GL.RasterPos2d(-3, 0)
		"You have died".each_byte { |c| GLUT.BitmapCharacter(GLUT::BITMAP_HELVETICA_12, c) }	
		
		# Reset ship after 5 seconds
		@destroyed = nil if  Time.now - @destroyed > 5
	end

  end #draw
end

# super class for the asteroid obstacles
# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class Asteroid < GObject

  attr_reader :xDelta, :yDelta

  def initialize(radius, init_x, init_y, delta_x, delta_y, game, verticies)
    super(game, init_x, init_y, delta_x, delta_y, radius, verticies, GL::LINE_LOOP)
  end #initialize

  # adjust center of object to update position
  def move
    super
	wrap
  end
end

# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class SmallAsteroid < Asteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
	verticies = [[0.5, 0.5],
	             [0.5, -0.5],
				 [-0.5, -0.5],
				 [-0.5, 0.5]]  
	super(0.5, init_x, init_y, delta_x, delta_y, game, verticies)
  end #initialize
end #SmallAsteroid

# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class MediumAsteroid < Asteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
	verticies = [[1.0, 1.0],
				 [0.5, 0.5],
				 [1.0, -1.0],
				 [0.5, -0.5],
				 [-1.0, -1.0],
				 [-0.5, -0.5],
				 [-0.5, 0.5]]
	super(1, init_x, init_y, delta_x, delta_y, game, verticies)
  end #initialize
end #MediumAsteroid


# an obsticle and a target in the game
# an asteroid can move (does so automatically)
# radius value is for detecting collisions
class LargeAsteroid < Asteroid
  def initialize(init_x, init_y, delta_x, delta_y, game)
    verticies = [[1.0, 1.0],
				 [1.5, 1.5],
				 [1.0, -1.0],
		         [1.5, -1.5],
		         [-1.0, -1.0],
				 [-1.0, -1.5],
				 [-1.5, 1.5]]
	super(1.5, init_x, init_y, delta_x, delta_y, game, verticies)
  end #initialize
end

# PTorpedo - photon torpedo
# always starts at the ship's center
# moves in the direction of the ship (at the time when PTorpedo object created)
# must know it's ship when created
class PTorpedo < GObject
  def initialize(ship, game)
	verticies = [[0.1, 0.1],
	             [0.1, -0.1],
				 [-0.1, -0.1],
				 [-0.1, 0.1]]
   	super(game, 
	      ship.xCenter, 
		  ship.yCenter, 
		  0.5 * -Math.sin(ship.direction/180*3.1415),
		  0.5 * Math.cos(ship.direction/180*3.1415),
		  0.001, verticies, GL::QUADS)
  end #initialize
end #PTorpedo

# Game has many purposes
# keeps track of the asteroids
# keeps track of the ship
# keeps track of the photon torpedo
# draws everything as needed
# where the window is created when the game starts

class Game

  attr_reader :xMax, :yMax, :ship_verticies

  def draw
    GL.Clear(GL::COLOR_BUFFER_BIT )

    @ship.draw
    @asteroids.each { |go| go.draw }
	@torpedos.each { |torpedo| torpedo.draw }

	# display the score
	GL.RasterPos2d(-19, -19)
	string = "Score: %4i" % @score.to_s
	string.each_byte { |c| GLUT.BitmapCharacter(GLUT::BITMAP_HELVETICA_12, c) }	
	
	# display the lives
	@lives.each { |life| life.draw }
	
	# display game over text if necessary
	if @lives.length == 0
		GL.RasterPos2d(-2.75, -2)
		"GAME OVER".each_byte { |c| GLUT.BitmapCharacter(GLUT::BITMAP_HELVETICA_12, c) }	
	end	
	
	# display you win if the player destroyed all the asteroids
	if @asteroids.length == 0
		GL.RasterPos2d(-2, 0)
		"YOU WIN".each_byte { |c| GLUT.BitmapCharacter(GLUT::BITMAP_HELVETICA_12, c) }
	end
	
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
	
	# quit the game if they lost all their lives or destroyed all the asteroids
	if @lives.length == 0 or @asteroids.length == 0
		sleep(3)
		exit
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
    @asteroids.each { |go| go.move }

	@torpedos.each do |torpedo|
		torpedo.move

		# if torpedo is off the screen, just get rid of it
		@torpedos.delete(torpedo) if torpedo.xCenter > @xMax or torpedo.yCenter > @yMax
	end
	
	# check for collisions between objects and act accordingly
	collisions
  end

  # check for collisions between objects and act accordingly
  def collisions
	# check to see if any PTorpedos have hit an asteroid
	@asteroids.each do |asteroid|
		@torpedos.each do |torpedo|
			# Check the distance between each
			distance = Math.sqrt((asteroid.xCenter - torpedo.xCenter)**2 + (asteroid.yCenter - torpedo.yCenter)**2)
			
			# Delete the torpedo and asteroid if they collide
			# We don't need to test the torpedo radius because its so small (poor torpedo)
			if distance < asteroid.radius
				@torpedos.delete(torpedo)
				@asteroids.delete(asteroid)
				
				# split larger asteroids into smaller ones upon collision with a torpedo
				if asteroid.class == LargeAsteroid
					@asteroids.push(MediumAsteroid.new(asteroid.xCenter, asteroid.yCenter, asteroid.xDelta, -asteroid.yDelta, self))
					@asteroids.push(MediumAsteroid.new(asteroid.xCenter, asteroid.yCenter, -asteroid.xDelta, asteroid.yDelta, self))
				elsif asteroid.class == MediumAsteroid
					@asteroids.push(SmallAsteroid.new(asteroid.xCenter, asteroid.yCenter, asteroid.xDelta, -asteroid.yDelta, self))
					@asteroids.push(SmallAsteroid.new(asteroid.xCenter, asteroid.yCenter, -asteroid.xDelta, asteroid.yDelta, self))
				end
				
				@score += 100
				break
			end
		end
		
		# player loses a life if they collided with an asteroid
		distance = Math.sqrt((asteroid.xCenter - @ship.xCenter)**2 + (asteroid.yCenter - @ship.yCenter)**2)
		if distance < asteroid.radius or distance < @ship.radius
			@asteroids.delete(asteroid)
			@ship = Ship.new(self)
			@ship.destroyed = Time.now
			@lives.slice!(-1) # Remove a life
		end
	end
  end
  
  # respond to keypresses
  # ship movement, torpedo fire
  # ESC to terminate
  def key(k, x, y)
    # as long as the ship is not destroyed, we will accept keypresses
    if not @ship.destroyed
		case k
		  when ?j
			@ship.rotate(5.0)
		  when ?k
			@ship.rotate(-5.0)
		  when ?h
			@ship.accellerate
		  when ?l
			@torpedos.push(PTorpedo.new(@ship, self))
		  when 27 # Escape
			exit
		end
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

	# store the ship matrix here because we use it for both the ship class as well showing the player lives
	@ship_verticies = [[0.0, 1.2],
					  [0.8, -1.2],
					  [0.0, -0.4],
					  [-0.8, -1.2]]
	
	@score = 0
	@lives = Array.new
	@lives[0] = GObject.new(self, 18, -18, 0, 0, 0, @ship_verticies, GL::LINE_LOOP)
	@lives[1] = GObject.new(self, 16, -18, 0, 0, 0, @ship_verticies, GL::LINE_LOOP)
	@lives[2] = GObject.new(self, 14, -18, 0, 0, 0, @ship_verticies, GL::LINE_LOOP)
	
    @asteroids = Array.new

    @ship = Ship.new(self)
    @asteroids[0] = SmallAsteroid.new(2, 3, 0.05, 0.05, self)
    @asteroids[1] = SmallAsteroid.new(3, 2, -0.05, -0.05, self)
    @asteroids[2] = MediumAsteroid.new(3, -2, 0.05, -0.05, self)
    @asteroids[3] = LargeAsteroid.new(-3, -2, 0.0, -0.05, self)

	@torpedos = Array.new
	
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
