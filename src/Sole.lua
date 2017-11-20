---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:45
---
local Grid = require("Grid")

---@class Sole
---@field id number
---@field group Grid[]
---@field newFixedValues number[]
---@field candidateGrids Grid[]
---@field groupType GroupType
---@field dirty boolean
local Sole = class("Sole")

---ctor
---@param groupType GroupType
function Sole:ctor(groupType, id)
    self.id = id
    self.group = {}
    self.newFixedValues = {}
    self.candidateGrids = {}
    self.groupType = groupType
    self.dirty = false
end

function Sole:getGroupType()
    return self.groupType
end

---addGrid
---@param grid Grid
function Sole:addGrid(grid)
    table.insert(self.group, grid)
    local value = grid:getValue()
    if value > 0 then
        table.insert(self.newFixedValues, value)
    else
        table.insert(self.candidateGrids, grid)
    end
    grid:addEventListener(Grid.FIX_NEW_VALUE, self.onFixNewValue, self)
    grid:addEventListener(Grid.DIRTY, self.onDirty, self)
end

function Sole:checkSole()
    for _, grid in ipairs(self.group) do
        local candidate = grid:getCandidate()
        local len = #candidate
        if len == 0 then
            return -1
        elseif len > 1 then
            return 0
        end
    end
    return 1
end


function Sole:hasNewFixValue()
    return #self.newFixedValues > 0
end

function Sole:checkDirty()
    local dirtyValues = clone(self.newFixedValues)
    self.newFixedValues = {}
    for i = #self.candidateGrids, 1, -1 do
        local grid = self.candidateGrids[i]
        for j, dValue in ipairs(dirtyValues) do
            grid:deleteCandidate(dValue)
        end
        if grid:getValue() > 0 then
            table.remove(self.candidateGrids, i)
        end
    end
    if self:hasNewFixValue() then
        self:checkDirty()
    else
        self.dirty = false
        self:checkUnique()
    end
end

function Sole:checkUnique()
    ---@type table<number, Grid[]>
    local tb = {}
    for _, grid in ipairs(self.candidateGrids) do
        for _, candidate in ipairs(grid:getCandidate()) do
            if tb[candidate] == nil then
                tb[candidate] = {}
            end
            table.insert(tb[candidate], grid)
        end
    end
    for cValue, grids in pairs(tb) do
        if #grids == 1 then
            local grid = grids[1]
            grid:setValue(cValue)
            table.removeElement(self.candidateGrids, grid)
        end
    end
end

---onGridDirty
---@param eventData Event.EventData
function Sole:onFixNewValue(eventData)
    ---@type Grid
    local grid = eventData:getTarget()
    table.insert(self.newFixedValues, grid:getValue())
end

---onDirty
---@param eventData Event.EventData
function Sole:onDirty(eventData)
    self.dirty = true
end

function Sole:isDirty()
    return self.dirty
end

return Sole