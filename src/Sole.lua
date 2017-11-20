---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:45
---
local Grid = require("Grid")

---@class Sole
---@field group Grid[]
---@field dirtyGrid Grid[]
---@field candidateGrids Grid[]
---@field groupType GroupType
local Sole = class("Sole")

---ctor
---@param groupType GroupType
function Sole:ctor(groupType)
    self.group = {}
    self.dirtyGrid = {}
    self.candidateGrids = {}
    self.groupType = groupType
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
        table.insert(self.dirtyGrid, grid)
    else
        table.insert(self.candidateGrids, grid)
    end
    grid:addEventListener(Grid.ON_DIRTY, self.onGridDirty, self)
end

function Sole:checkSole()
    local map = {}
    for _, grid in ipairs(self.group) do
        local value = grid:getValue()
        if value ~= nil and value ~= 0 then
            if map[value] == nil then
                map[value] = true
            else
                return false
            end
        end
    end
    return true
end

function Sole:check(values, candidates)
    values = values or {}
    if candidates == nil then
        candidates = {}
        for _, grid in ipairs(self.group) do
            local value = grid:getValue()
            if value > 0 then
                values[value] = true
            else
                candidates[grid] = true
            end
        end
    else
        for grid, _ in pairs(candidates) do
            local value = grid:getValue()
            if value > 0 then
                values[value] = true
                candidates[grid] = nil
            end
        end
    end

end

function Sole:deleteCandidate(value)
    local modi = false
    for _, grid in ipairs(self.group) do
        if grid:deleteCandidate(value) then
            modi = true
        end
    end
    return modi
end

function Sole:isDirty()
    return #self.dirtyGrid > 0
end

function Sole:deleteCandidate2()
    for i = #self.candidateGrids, 1, -1 do
        local grid = self.candidateGrids[i]
        for j, dGrid in ipairs(self.dirtyGrid) do
            grid:removeEventListener(Grid.ON_DIRTY, self.onGridDirty, self)
            grid:deleteCandidate(dGrid:getValue())
        end
        if grid:getValue() > 0 then
            table.remove(self.candidateGrids, i)
        end
        grid:addEventListener(Grid.ON_DIRTY, self.onGridDirty, self)
    end
    self.dirtyGrid = {}
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
    for cValue, grids in ipairs(tb) do
        if #grids == 1 then
            local grid = grids[1]
            print("unique", cValue)
            grid:removeEventListener(Grid.ON_DIRTY, self.onGridDirty, self)
            grid:setValue(cValue)
            table.removeElement(self.candidateGrids, grid)
            grid:addEventListener(Grid.ON_DIRTY, self.onGridDirty, self)
        end
    end
end

---onGridDirty
---@param eventData Event.EventData
function Sole:onGridDirty(eventData)
    table.insert(self.dirtyGrid, eventData:getTarget())
    self:deleteCandidate2()
    self:checkUnique()
end

return Sole