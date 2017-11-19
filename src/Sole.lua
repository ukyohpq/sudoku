---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:45
---

---@class Sole
---@field group Grid[]
---@field dirtyGrid Grid[]
---@field candidateGrids Grid[]
local Sole = class("Sole")

function Sole:ctor()
    self.group = {}
    self.dirtyGrid = {}
    self.candidateGrids = {}
end

function Sole:addGrid(grid)
    table.insert(self.group, grid)
    if grid:getValue() > 0 then
        table.insert(self.dirtyGrid, grid)
    else
        table.insert(self.candidateGrids, grid)
        --grid
    end
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

function Sole:checkDirty()
    local newDirty = {}
    for i = #self.candidateGrids, 1, -1 do
        local grid = self.candidateGrids[i]
        for j, dGrid in ipairs(self.dirtyGrid) do
            grid:deleteCandidate(dGrid:getValue())
        end
        if grid:getValue() > 0 then
            table.insert(newDirty, grid)
            table.remove(self.candidateGrids, i)
        end
    end
    self.dirtyGrid = newDirty
end

return Sole