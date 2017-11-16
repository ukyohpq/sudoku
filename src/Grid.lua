---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:22
---

---@class Grid
---@field row number
---@field line number
---@field square number
---@field value number
---@field candidate number[]
local Grid = class("Grid")

function Grid:ctor(row, line, square, value)
    self.row = row
    self.line = line
    self.square = square
    self.value = value
    if value == nil then
        self.candidate = {1,2,3,4,5,6,7,8,9}
    end
end

function Grid:getRow()
    return self.row
end

function Grid:getLine()
    return self.line
end

function Grid:getSquare()
    return self.square
end

function Grid:setValue(value)
    self.value = value
end

function Grid:getValue()
    return self.value
end

return Grid