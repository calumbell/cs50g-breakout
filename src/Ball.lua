--[[
    GD50
    Breakout Remake

    -- Ball Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a ball which will bounce back and forth between the sides
    of the world space, the player's paddle, and the bricks laid out above
    the paddle. The ball can have a skin, which is chosen at random, just
    for visual variety.
]]

Ball = Class{}

function Ball:init(x, y)
    -- simple positional and dimensional variables
    self.width = 8
    self.height = 8
    self.x = x
    self.y = y


    -- these variables are for keeping track of our velocity on both the
    -- X and Y axis, since the ball can move in two dimensions
    self.dy = 0
    self.dx = 0

    -- this will effectively be the color of our ball, and we will index
    -- our table of Quads relating to the global block texture using this
    self.skin = math.random(7)
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function Ball:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Places the ball in the middle of the screen, with no movement.
]]
function Ball:reset()
    self.x = VIRTUAL_WIDTH / 2 - 2
    self.y = VIRTUAL_HEIGHT / 2 - 2
    self.dx = 0
    self.dy = 0
end

function Ball:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

    -- allow ball to bounce off walls
    if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function Ball:render()
    -- gTexture is our global texture for all blocks
    -- gBallFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['balls'][self.skin],
        self.x, self.y)
end




function Ball:randomiseVelocity()
    self.dx = math.random(-200, 200)
    self.dy = math.random(-50, -60)
end



 --[[ collision code for bricks
    we check to see if the opposite side of our velocity is outside of the brick;
    if it is, we trigger a collision on that side. else we're within the X + width of
    the brick and should check to see if the top or bottom edge is outside of the brick,
    colliding on the top or bottom accordingly 

    left edge; only check if we're moving right, and offset the check by a couple of pixels
    so that flush corner hits register as Y flips, not X flips
    ]]
    
function Ball:handleBrickBounce(brick)

    if self.x + 2 < brick.x and self.dx > 0 then
        
        -- flip x velocity and reset position outside of brick
        self.dx = -self.dx
        self.x = brick.x - 8

    -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
    -- so that flush corner hits register as Y flips, not X flips
    elseif self.x + 6 > brick.x + brick.width and self.dx < 0 then
        
        -- flip x velocity and reset position outside of brick
        self.dx = -self.dx
        self.x = brick.x + 32

    -- top edge if no X collisions, always check
    elseif self.y < brick.y then
        
        -- flip y velocity and reset position outside of brick
        self.dy = -self.dy
        self.y = brick.y - 8

    -- bottom edge if no X collisions or top collision, last possibility
    else
        
        -- flip y velocity and reset position outside of brick
        self.dy = -self.dy
        self.y = brick.y + 16
    end

    -- slightly scale the y velocity to speed up the game, capping at +- 150
    if math.abs(self.dy) < 150 then
        self.dy = self.dy * 1.02
    end
end