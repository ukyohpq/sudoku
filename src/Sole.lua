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

---addGrid @添加一个格子，同时添加两个事件：格子确定数字的事件，和格子删除候选数的事件
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
    grid:addEventListener(Grid.DELETE_CANDIDATE, self.onDeleteCandidate, self)
    grid:addEventListener(Grid.START_DELETE_REPEAT, self.onStartDeleteRepeat, self)
end

---checkSole @检测组合是否有重复数字的错误
function Sole:checkSole()
    local ret = 1
    local valueMap = {}
    for _, grid in ipairs(self.group) do
        local candidate = grid:getCandidate()
        local len = #candidate
        if len == 0 then
            return -1
        elseif len > 1 then
            ret = 0
        else
            local value = grid:getValue()
            if valueMap[value] then
                return -1
            end
            valueMap[value] = true
        end
    end
    return ret
end

---checkSole @检测组合是否有重复数字的错误
function Sole:checkSole2()
    local valueMap = {}
    for _, grid in ipairs(self.group) do
        local candidate = grid:getCandidate()
        local len = #candidate
        if len == 0 then
            return false
        elseif len > 1 then
            if grid.cIndex > 0 then
                local value = grid.candidate[grid.cIndex]
                if valueMap[value] then
                    return false
                end
                valueMap[value] = true
            end
        else
            local value = grid:getValue()
            if valueMap[value] then
                return false
            end
            valueMap[value] = true
        end
    end
    return true
end

---hasNewFixValue @是否有新的确定数
function Sole:hasNewFixValue()
    return #self.newFixedValues > 0
end

---checkDirty @对组合进行dirty测试，标记为dirty的组合，需要去重，若经过去重，发现了新的确定数字，
---需要重新进行dirty测试，直到没有新数字出现，然后进行唯一性检测
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

---checkUnique @组合检测唯一性。
function Sole:checkUnique()
    ---@type table<number, Grid[]>
    local tb = {}
    --for _, grid in ipairs(self.candidateGrids) do
    for _, grid in ipairs(self.group) do
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

-----onGridDirty @新数字确定事件
-----@param eventData Event.EventData
function Sole:onFixNewValue(eventData)
    ---@type Grid
    local grid = eventData:getTarget()
    table.insert(self.newFixedValues, grid:getValue())
end

-----onDirty @删除候选数事件，此时认为组合dirty，需要重新检测
-----@param eventData Event.EventData
function Sole:onDeleteCandidate(eventData)
    self.dirty = true
end

function Sole:isDirty()
    return self.dirty
end


---deleteCandidate
---@param value number
function Sole:deleteCandidate(value)
    for _, grid in ipairs(self.group) do
        grid:deleteCandidate(value)
    end
end


---onStartDeleteRepeat
---@param eventData Event.EventData
function Sole:onStartDeleteRepeat(eventData)
    ---@type Grid
    local grid = eventData:getTarget()
    local value = grid:getValue()
    for _, grid in ipairs(self.group) do
        grid:deleteCandidate(value)
    end
end

return Sole