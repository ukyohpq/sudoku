---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:22
---

---@class Grid : Event.EventDispatcher
---@field row number
---@field line number
---@field square number
---@field value number
---@field candidate number[]
local Grid = class("Grid", require("Event.EventDispatcher"))
---@type Event.EventDispatcher
local super = Grid.super
Grid.FIX_NEW_VALUE = "fixNewValue"
Grid.DIRTY = "dirty"


function Grid:ctor(row, line, square, value)
    super.ctor(self)
    if value == nil then
        value = 0
    end
    value = value or 0
    self.row = row
    self.line = line
    self.square = square
    if value == 0 then
        self.candidate = {1,2,3,4,5,6,7,8,9}
    else
        self.candidate = {value}
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

function Grid:reset()
    self.candidate = {1,2,3,4,5,6,7,8,9}
end

function Grid:getValue()
    if #self.candidate == 1 then
        return self.candidate[1]
    else
        return 0
    end
end

function Grid:setValue(value)
    self.candidate = {value}
    self:checkNewFixValue()
end

function Grid:toString()
    if self:getValue() > 0 then
        return tostring(self:getValue())
    end
    local s = "[ "
    for _, cand in ipairs(self.candidate) do
        s = s .. cand .. " "
    end
    s = s .. "]"
    return s
end

function Grid:deleteCandidate(value)
    if #self.candidate == 1 then
        return false
    end
    for i, v in ipairs(self.candidate) do
        if v == value then
            table.remove(self.candidate, i)
            self:dispatchEvent(Grid.DIRTY)
            self:checkNewFixValue()
            return true
        end
    end
    return false
end

function Grid:checkNewFixValue()
    if #self.candidate == 1 then
        self:dispatchEvent(Grid.FIX_NEW_VALUE)
    end
end

function Grid:getCandidate()
    return self.candidate
end

return Grid