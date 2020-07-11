Powerup = Class {}

function Powerup:init(x, y, id)

	-- Simple positional + dimensional variables	
	self.width = 16
	self.height = 16
	self.x = x
	self.y = y
	self.dx = 0
	self.dy = 25

	-- What kind of powerup is instance
	-- 1: triple ball
	-- 2: key
	self.id = id

end

function Powerup:collides(target)

	-- check if the left edge of either obect is farther to the right 
	-- than the right edge of the other
	if self.x > target.x + target.width or target.x > self.x + self.width then
		return false
	end

	-- check if the bottom edge of either object is higher than the  
	-- top edge of the other
	if self.y > target.y + target.height or target.y > self.y + self.height then
		return false
	end

	-- if neither of the above are true, then the objects are overlapping
	return true
end

function Powerup:update(dt)
	-- Update coordinates using velocities, scaled by delta time
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt
end


function Powerup:render()
	love.graphics.draw(gTextures['main'], gFrames['powerups'][self.id], self.x, self.y)
end


function Powerup:isAtBottom()
	-- If the powerup touches the bottom of the screen, return true
	if self.y + self.width >= VIRTUAL_HEIGHT then
		return true
	end

	-- If it isn't, return false
	return false
end
