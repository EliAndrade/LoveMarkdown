local markdown = require "markdown"
local canvas = love.graphics.newCanvas(800, 1000)
love.window.updateMode(800, 600)

love.graphics.setCanvas(canvas)

love.graphics.setCanvas()

local str = require "test"


markdown:render(str, 400)



function love.draw()
    markdown:draw(str, 400)

   love.graphics.print(("FPS: %i"):format(love.timer.getFPS()))
   love.graphics.print(love.graphics.getStats()['drawcalls'], 0, 16)
end