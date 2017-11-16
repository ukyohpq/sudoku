---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:45
---

---@class Sole
---@field group Grid[]
local Sole = class("Sole")

function Sole:ctor()
    self.group = {}
end

function Sole:addGrid(grid)
    table.insert(self.group, grid)
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
return Sole