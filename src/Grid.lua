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
    if value == nil then
        value = 0
    end
    value = value or 0
    self.row = row
    self.line = line
    self.square = square
    self.value = value
    if value == 0 then
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

function Grid:reset()
    self.value = 0
end

function Grid:getValue()
    return self.value
end

function Grid:tosting()
    if self.value > 0 then
        return tostring(self.value)
    end
    local s = "[ "
    for _, cand in ipairs(self.candidate) do
        s = s .. cand .. " "
    end
    s = s .. "]"
    return s
end

function Grid:deleteCandidate(value)
    if self.candidate == nil then
        return false
    end
    for i, v in ipairs(self.candidate) do
        if v == value then
            table.remove(self.candidate, i)
            if #self.candidate == 1 then
                self.value = self.candidate[1]
                self.candidate = nil
            end
            return true
        end
    end
    return false
end

function Grid:deleteCandidates(values)
    local ismodi = false
    for _, value in ipairs(values) do
        if self:deleteCandidate(value) then
            ismodi = true
        end
    end
    return ismodi
end

return Grid