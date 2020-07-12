--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.recoverPoints = params.recoverPoints
    self.powersActive = params.powersActive
    self.powerups = {}   -- powerup collectables do not persist between states

    -- give ball random starting velocity
    for k, ball in pairs(self.balls) do
        ball:randomiseVelocity()
    end
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update paddle positions based on velocity
    self.paddle:update(dt)

    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    -- update all pickup positions based on velocity
    for k, pu in pairs(self.powerups) do
        pu:update(dt)
        if pu:isAtBottom() then
            self.powerups[k] = nil
        end
    end

    for k, ball in pairs(self.balls) do    
        -- detect ball/paddle collisions
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - 8
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
        
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    for k, ball in pairs(self.balls) do
        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- decrement recoverPoints if we aren't at max paddle size or health
                if self.paddle.size < 4 or self.health < 3 then
                    self.recoverPoints = self.recoverPoints - (brick.tier * 200 + brick.color * 25)
                end

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                -- if we have accumulated enough points..
                if self.recoverPoints <= 0 then

                    -- ..and our health is less than 3, recover
                    if self.health < 3 then
                        -- can't go above 3 health
                        self.health = math.min(3, self.health + 1)
                    end

                    -- .. and our size is less than 4, grow
                    if self.paddle.size < 4 then
                        self.paddle:grow()
                    end

                    -- reset recoverPoints
                    self.recoverPoints = POINTS_TO_RECOVER

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        balls = self.balls,
                        recoverPoints = self.recoverPoints
                    })
                end

                -- Maybe spawn a multi-ball powerup
                if math.random(2) == 1 and self.powerups['multiball'] == nil and self.powersActive['multiball'] == false then
                    self.powerups['multiball'] = Powerup(ball.x, ball.y, 1)
                end

                ball:handleBrickBounce(brick)

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    -- detect powerup/paddle collisions
    for k, pu in pairs(self.powerups) do
        if pu:collides(self.paddle) then

            -- activate power and set flag
            self.powersActive[pu:getType()] = true
            gSounds['powerup']:play()
            self.powerups[pu:getType()] = nil

            for i = 2, MULTIBALL_N, 1 do
                self.balls[i] = Ball(self.balls[1].x, self.balls[1].y)
                self.balls[i]:randomiseVelocity()
            end
        end
    end

    for k, ball in pairs(self.balls) do
        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then

            -- update health and paddle size
            self.health = self.health - 1
            self.paddle:shrink()
            gSounds['hurt']:play()

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores
                })
            else
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints,
                    powersActive = self.powersActive

                })
            end
        end
    end
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    -- render paddle
    self.paddle:render()

    -- render ball(s)
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    -- render powerups
    for k, pu in pairs(self.powerups) do
       pu:render()
    end


    renderScore(self.score)
    renderHealth(self.health)

    if self.health < 3 or self.paddle.size < 4 then
        renderHint(self.recoverPoints)
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end