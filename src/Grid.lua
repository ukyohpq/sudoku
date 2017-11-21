---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:22
---

local HistoryRecorder = require("History.HistoryRecorder")

---@class Grid : Event.EventDispatcher
---@field row number
---@field line number
---@field square number
---@field value number
---@field candidate number[]
---@field recorder History.HistoryRecorder
local Grid = class("Grid", require("Event.EventDispatcher"))

---@type Event.EventDispatcher
local super = Grid.super

---当数字确定时广播
Grid.FIX_NEW_VALUE = "fixNewValue"
---当删除候选数时广播
Grid.DELETE_CANDIDATE = "deleteCandidate"


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
    self.recorder = HistoryRecorder.new()
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

---setValue 直接设置确定值，用在组合唯一性处理时
---@param value number
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

---deleteCandidate @从候选数中删除指定的数字
---@param value number @要删除的候选数
---@return boolean @是否成功删除
function Grid:deleteCandidate(value)
    if #self.candidate == 1 then
        return false
    end
    for i, v in ipairs(self.candidate) do
        if v == value then
            table.remove(self.candidate, i)
            self:dispatchEvent(Grid.DELETE_CANDIDATE)
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

function Grid:record()
    self.recorder:createRecord(clone(self.candidate))
end

function Grid:revertRecord()
    self.candidate = clone(self.recorder:getRecord())
end

function Grid:hasRecord()
    return self.recorder:hasRecord()
end

function Grid:revertToPrevRecord()
    if self:hasRecord() then
        self.recorder:undo()
        self:revertRecord()
    end
end

return Grid