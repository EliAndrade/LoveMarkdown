local LINE_MODIFIER_PATTERN = "(% ?% ?% ?)([>*%-%#]) "
local CODE_MODIFIER_PATTERN = "(% ?% ?% ?)(```)(%w*)"

local fonts = require "fonts"
local newFont = love.graphics.newFont

local lmd = {}
lmd.fonts = fonts
lmd.texts = {}
lmd.static = true

function lmd:print(text, font, x, y, r, sx, sy, ox, oy, kx, ky)
    --> If it is drawing static text, use Text objects
    if self.static then
        if not self.texts[font] then
            self.texts[font] = love.graphics.newText(font)
        end

        self.texts[font]:add(text, x, y, r, sx, sy, ox, oy, kx, ky)
    
    --> Else, use basic print
    else
        love.graphics.print(text, font, x, y, r, sx, sy, ox, oy, kx, ky)
    end
end

function lmd:getFont(font, type)
    local fonts = self.fonts
    
    if fonts[font] then
        if fonts[font][type] then
            return fonts[font][type], true
        end
        return fonts[font]['base'], false
    end
    return fonts['base']['base'], false
end

function lmd:drawLine(line, fontFamily, height, maxWidth)
    local whitespace = line:match("^[ \t]+") or ""
    local baseFont = self:getFont(fontFamily, 'base')
    local actualWidth = baseFont:getWidth(whitespace)

    local isBold = false
    local isItalic = false
    local isCode = false
    local tag = nil

    for word in line:gmatch("[\x21-\xff]+") do
        --> Will be this word
        local static = true

        --> Font for this text 
        local font = baseFont

        --> Transform modifiers
        local r, sx, sy, ox, oy, kx, ky = 0, 1, 1, 0, 0, 0, 0

        --> Check style of the word for fonts and style changes starting
        local boldXItalic = word:match("^[*_][*_]?[*_]?")
        if boldXItalic and not tag then
            if boldXItalic:len() == 3 then
                isBold = true
                isItalic = true
            elseif boldXItalic:len() == 2 then
                isBold = true
            elseif boldXItalic:len() == 1 then
                isItalic = true
            end

            tag = boldXItalic:reverse().."$"
            word = word:gsub(boldXItalic, "")
        end

        local code = word:match("^`")
        if code and not tag then
            tag = code.."$"
            word = word:gsub(code, "")
        end

        if tag then
            word = word:gsub(tag, "")
        end

        if code then
            font = self:getFont('code', 'base')
        end

        if isBold then
            font = self:getFont(fontFamily, 'bold')
            sy = 1.10 
            sy = 1.20 
        end

        if isItalic then
            local found = false

            if isBold then
                font, found = self:getFont(fontFamily, 'bolditalic')
            else
                font, found = self:getFont(fontFamily, 'italic')
            end

            if not found then
                kx = -0.25
            end
        end

        --> Get width of this word
        local width = font:getWidth(word)
        
        --> Check if line will need break
        if width + actualWidth > maxWidth then
            height = height + font:getHeight()
            actualWidth = 0
        end

        --> Print with a space
        local spaced = ("%s "):format(word)
        
        if self.static and static then
            self:print(spaced, font, actualWidth, height, r, sx, sy, ox, oy, kx, ky)
        elseif not self.static and not static then
            self:print(spaced, font, actualWidth, height, r, sx, sy, ox, oy, kx, ky)
        end

        --> Update width
        actualWidth = actualWidth + font:getWidth(spaced)

        --> Check finishers
        if tag then
            if word:match(tag) then
                isBold = false
                isItalic = false
            end
        end
    end

    return baseFont:getHeight()
end    

function lmd:parseLine(iterator, height, line, maxWidth)   
    local whitespace, modifier, language = line:match(LINE_MODIFIER_PATTERN)
    if not modifier then
        whitespace, modifier, language = line:match(CODE_MODIFIER_PATTERN)
    end

    if modifier == "#" then
        local size = line:match("#+")
        return height + self:drawLine(line:gsub("^[ \t]*#+ ", ""), ('h%d'):format(size:len()), height, maxWidth)
    elseif modifier == "*" then
        return height + self:drawLine(line:gsub("*", "•"), "base", height, maxWidth)
    elseif modifier == "```" then
        return height + self:drawLine(line:gsub(CODE_MODIFIER_PATTERN, ""), "base", height, maxWidth)
    end

    return height + self:drawLine(line, 'base', height, maxWidth)
end

function lmd:render(str, maxWidth)
    self.static = true

    --> Force newline at end of string
    if str:sub(str:len(), str:len()) ~= "\n" then
        str = str.."\n"
    end

    --> Create iterator
    local nextLine = str:gmatch('.-\n')
    
    --> For each line
    local y = 0
    local line = nextLine()
    
    while line do
        y = self:parseLine(nextLine, y, line, maxWidth)
        line = nextLine()
    end    
end

function lmd:draw(str, maxWidth)
    self.static = false

    --> Force newline at end of string
    if str:sub(str:len(), str:len()) ~= "\n" then
        str = str.."\n"
    end

    --> Create iterator
    local nextLine = str:gmatch('.-\n')
    
    --> For each line
    local y = 0
    local line = nextLine()
    while line do
        y = self:parseLine(nextLine, y, line, maxWidth)
        line = nextLine()
    end    


    --> Draw texts objects
    for i, v in pairs(self.texts) do
        love.graphics.draw(v)
    end
end

return lmd