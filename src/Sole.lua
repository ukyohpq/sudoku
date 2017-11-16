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

return Sole