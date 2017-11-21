---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:05
---

require("Const")

local Grid = require("Grid")
local Sole = require("Sole")
local HistoryRecorder = require("History.HistoryRecorder")
---@class Sudoku
---@field rows Sole[]
---@field lines Sole[]
---@field squares Sole[]
---@field grids Grid[]
---@field origin Sudoku
---@field recorder History.HistoryRecorder
local Sudoku = class("Sudoku")

function Sudoku:ctor(valueMap)
    self.rows = {}
    self.lines = {}
    self.squares = {}
    self.recorder = HistoryRecorder.new()
    local grids = {}

    if #valueMap ~= Const.MAX_LINE * Const.MAX_ROW then
        print("err. value map length is not match")
        return
    end

    local n = 0
    for i = 1, Const.MAX_ROW do
        for j = 1, Const.MAX_LINE do
            n = n + 1
            local rowIndex = i
            local lineIndex = j
            local squareIndex = (math.ceil(i / Const.SQUARE_HEIGHT) - 1) * Const.MAX_LINE / Const.SQUARE_WIDTH + math.ceil(j / Const.SQUARE_WIDTH)
            local grid = Grid.new(rowIndex, lineIndex, squareIndex, valueMap[n])
            local row = self:getGroup(GroupType.ROW, rowIndex)
            local line = self:getGroup(GroupType.LINE, lineIndex)
            local square = self:getGroup(GroupType.SQUARE, squareIndex)
            row:addGrid(grid)
            line:addGrid(grid)
            square:addGrid(grid)
            table.insert(grids, grid)
        end
    end
    self.grids = grids
end

function Sudoku:reset()
    for _, grid in ipairs(self.grids) do
        grid:reset()
    end
end

function Sudoku:getGroup(groupType, index)
    ---@type Sole[]
    local group
    if groupType == GroupType.ROW then group = self.rows end
    if groupType == GroupType.LINE then group = self.lines end
    if groupType == GroupType.SQUARE then group = self.squares end
    if group[index] == nil then
        group[index] = Sole.new(GroupType.ROW, index)
    end
    return group[index]
end

function Sudoku:checkDirty()
    ---@type Sole[][]
    local arr = {self.rows, self.lines, self.squares}
    for _, soles in ipairs(arr) do
        for _, sole in ipairs(soles) do
            sole:checkDirty()
        end
    end
    local dirty = false
    for _, soles in ipairs(arr) do
        for _, sole in ipairs(soles) do
            if sole:isDirty() then
                dirty = true
            end
        end
    end
    if dirty then
        self:checkDirty()
    end
end

function Sudoku:output(verbose)
    local s = ""
    local n = 0
    for _, grid in ipairs(self.grids) do
        n = n + 1
        if verbose then
            s = s .. grid:toString()
        else
            if grid:getValue() == 0 then
                s = s .. " "
            else
                s = s .. grid:getValue()
            end
        end
        if n == Const.MAX_LINE then
            n = 0
            s = s .. "\n"
        else
            s = s .. ",\t"
        end
    end
    return s
end

function Sudoku:checkSuccess()
    ---@type Sole[][]
    local arr = {self.rows, self.lines, self.squares}
    local successInfo = SuccessInfo.COMPLETE
    for _, soles in ipairs(arr) do
        for _, sole in ipairs(soles) do
            local ret = sole:checkSole()
            if ret == -1 then
                return SuccessInfo.WRONG
            end
            if ret == 0 then
                successInfo = SuccessInfo.UNCOMPLETE
            end
        end
    end
    return successInfo
end

function Sudoku:guess()
    for _, grid in ipairs(self.grids) do
        if #grid:getCandidate() == 2 then
            grid:setValue(grid:getCandidate()[1])
            break
        end
    end
    self:checkDirty()
end

function Sudoku:makeSavePoint()
    --通过record还原遍历的位置
    local startIndex = 1
    if self.recorder:hasRecord() then
        local record = self.recorder:getRecord()
        startIndex = record
    end
    --保存所有的grid的状态
    for _, grid in ipairs(self.grids) do
        grid:record()
    end
    for i = startIndex, #self.grids  do
        local grid = self.grids[i]
        if #grid:getCandidate() == 2 then
            self.recorder:createRecord(i)
            grid:setValue(grid:getCandidate()[1])
            break
        end
    end
    self:checkDirty()

    local si = self:checkSuccess()
    if si == SuccessInfo.COMPLETE then
        print("success!!!!")
    elseif si == SuccessInfo.WRONG then
        print("wrong!!!!")
    else
        print("uncomplete!!!!")
        self:makeSavePoint()
    end
    print(self:output())
end
return Sudoku