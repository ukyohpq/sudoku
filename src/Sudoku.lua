---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:05
---

require("Const")

local Grid = require("Grid")
local Sole = require("Sole")

---@class Sudoku
---@field rows Sole[]
---@field lines Sole[]
---@field squares Sole[]
---@field grids Grid[]
local Sudoku = class("Sudoku")

function Sudoku:ctor(valueMap)
    self.rows = {}
    self.lines = {}
    self.squares = {}
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
        group[index] = Sole.new()
    end
    return group[index]
end

---baseCheck @基础的行列宫排除法
function Sudoku:baseCheck()
    local modi = false
    for _, row in ipairs(self.rows) do
        row:deleteCandidate()
    end
    for _, grid in ipairs(self.grids) do
        local value = grid:getValue()
        if value > 0 then
            local lineGroup = self:getGroup(GroupType.LINE, grid:getLine())
            if lineGroup:deleteCandidate(value) then
                modi = true
            end
            local rowGroup = self:getGroup(GroupType.ROW, grid:getRow())
            if rowGroup:deleteCandidate(value) then
                modi = true
            end
            local squareGroup = self:getGroup(GroupType.SQUARE, grid:getSquare())
            if squareGroup:deleteCandidate(value) then
                modi = true
            end
        end
    end
    if modi then
        self:baseCheck()
    end
end

function Sudoku:checkDirty()
    local modi = false
    for i, group in ipairs(self.rows) do
        if group:isDirty() then
            print("check rows", i)
            modi = true
            group:checkDirty()
        end
    end
    for i, group in ipairs(self.lines) do
        if group:isDirty() then
            print("check lines", i)
            modi = true
            group:checkDirty()
        end
    end
    for i, group in ipairs(self.squares) do
        if group:isDirty() then
            print("check squares", i)
            modi = true
            group:checkDirty()
        end
    end
    if modi then
        self:checkDirty()
    end
end

function Sudoku:checkRow(index)
    
end

function Sudoku:checkLine(index)
    
end

function Sudoku:checkSquare(index)
    
end

function Sudoku:output(verbose)
    local s = ""
    local n = 0
    for _, grid in ipairs(self.grids) do
        n = n + 1
        if verbose then
            s = s .. grid:tosting()
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

return Sudoku