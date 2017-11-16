---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:05
---

local Grid = require("self.Grid")
local Sole = require("self.Sole")

---@class Sudoku
---@field rows Sole[]
---@field lines Sole[]
---@field square Sole[]
---@field grids Grid[]
local Sudoku = class("Sudoku")

function Sudoku:ctor()
    self.rows = {}
    self.lines = {}
    self.square = {}
    local grids = {}

    for i = 1, Const.MAX_ROW do
        for j = 1, Const.MAX_LINE do
            local rowIndex = i
            local lineIndex = j
            local squareIndex = (math.ceil(i / Const.SQUARE_HEIGHT) - 1) * Const.MAX_LINE / Const.SQUARE_WIDTH + math.ceil(j / Const.SQUARE_WIDTH)
            local grid = Grid.new(rowIndex, lineIndex, squareIndex)
            local row = self:getGroup(GroupType.ROW, rowIndex)
            local line = self:getGroup(GroupType.LINE, lineIndex)
            local square = self:getGroup(GroupType.SQUARE, squareIndex)
            table.insert(row, grid)
            table.insert(line, grid)
            table.insert(square, grid)
            table.insert(grids, grid)
        end
    end
    self.grids = grids
end

function Sudoku:writeValue(valueMap)
    for i, grid in ipairs(self.grids) do
        grid:setValue(valueMap[i])
    end
end

function Sudoku:reset()
    for _, grid in ipairs(self.grids) do
        grid:setValue(0)
    end
end
function Sudoku:getGroup(groupType, index)
    local group
    if groupType == GroupType.ROW then group = self.rows end
    if groupType == GroupType.LINE then group = self.lines end
    if groupType == GroupType.SQUARE then group = self.square end
    if group[index] == nil then
        group[index] = Sole.new()
    end
    return group[index]
end

function Sudoku:checkRow(index)
    
end

function Sudoku:checkLine(index)
    
end

function Sudoku:checkSquare(index)
    
end

function Sudoku:output()
    local s = ""
    local n = 0
    for _, grid in ipairs(self.grids) do
        n = n + 1
        s = s .. grid:getValue()
        if n == Const.MAX_LINE then
            n = 0
            s = s .. "\n"
        end
    end
    return s
end

return Sudoku