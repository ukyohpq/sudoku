---
--- Created by ukyohpq.
--- DateTime: 17/11/16 17:05
---

require("Const")

local Grid = require("Grid")
local Sole = require("Sole")
local HistoryRecorder = require("History.HistoryRecorder")

---@class Record
---@field gridIndex number
---@field candidateIndex number
---@field gridsShortcut number[][]

---@class Sudoku
---@field rows Sole[]
---@field lines Sole[]
---@field squares Sole[]
---@field grids Grid[]
---@field origin Sudoku
---@field recorder History.HistoryRecorder
---@field forCheckGrids Grid[]
---@field checkingGrids Grid[]
---@field uniqueDirtySoleMap Sole[]
---@field state number
---@field isGuessing boolean
local Sudoku = class("Sudoku")

local STATES = {
    NORMAL = "NORMAL",
    CHECK_REPEAT = "CHECK_REPEAT",
    UNIQUE = "UNIQUE",
    START_GUESS = "START_GUESS",
    SUCCESS = "SUCCESS",
    NO_ANSWER = "NO_ANSWER",
    GUESS_NEXT = "GUESS_NEXT",
    GUESS_FAILED = "GUESS_FAILED",
    GUESS_WRONG = "GUESS_WRONG",
}

function Sudoku:ctor(valueMap)
    self.rows = {}
    self.lines = {}
    self.squares = {}
    self.recorder = HistoryRecorder.new()
    self.uniqueDirtySoleMap = {}
    self.checkingGrids = {}
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
            grid:addEventListener(Grid.FIX_NEW_VALUE, self.onFixNewValue, self)
            grid:addEventListener(Grid.DELETE_CANDIDATE, self.onDeleteCandidate, self)
        end
    end
    self.grids = grids
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

---checkDirty @对每个组合进行dirty测试，直到没有组合为dirty
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

---gridLinkGuess 使用grid链表进行候选数猜测
---@param verbose boolean
function Sudoku:gridLinkGuess(verbose)
    ---@type Grid
    local headGrid = nil
    ---@type Grid
    local tailGrid = nil
    ---@type Grid
    local currentGrid = nil
    for _, grid in ipairs(self.grids) do
        grid.cIndex = 0
        grid.mIndex = #grid.candidate
        if grid:getValue() == 0 then
            if headGrid == nil then
                headGrid = grid
                currentGrid = grid
            else
                currentGrid.next = grid
                grid.prev = currentGrid
                tailGrid = grid
                currentGrid = grid
            end
        end
    end
    currentGrid = headGrid
    local step = 0
    while(true) do
        if verbose then
            step = step + 1
        end
        local ret = self:guessNext(currentGrid)
        if ret == -1 then
            print("no answer")
            break
        end
        if ret == 0 then
            currentGrid.cIndex = 0
            currentGrid = currentGrid.prev
        end
        if ret == 1 then
            print("success!!")
            for _, grid in ipairs(self.grids) do
                if grid.cIndex > 0 then
                    grid:setValue(grid.candidate[grid.cIndex])
                end
            end
            break
        end
        if ret == 2 then
            currentGrid = currentGrid.next
        end
    end
    if verbose then
        print("step", step)
    end
end

---guessNext
---@param cGrid Grid
function Sudoku:guessNext(cGrid)
    cGrid.cIndex = cGrid.cIndex + 1
    if cGrid.cIndex > cGrid.mIndex then
        if cGrid.prev == nil then
            return -1
        else
            return 0
        end
    else
        if self.rows[cGrid.row]:checkSole2()
        and self.lines[cGrid.line]:checkSole2()
        and self.squares[cGrid.square]:checkSole2() then
            if cGrid.next == nil then
                return 1
            else
                return 2
            end
        end
    end
end

---getAnswer
---@param littleGuess boolean @是否使用最小候选数猜测
---@param verbose boolean @是否显示详细信息
function Sudoku:getAnswer(littleGuess, verbose)
    for _, grid in ipairs(self.grids) do
        if grid:getValue() > 0 then
            table.insert(self.checkingGrids, grid)
        end
    end
    self.state = STATES.NORMAL
    self.isGuessing = false
    local step = 0
    while(true) do
        if verbose then
            print(self.state)
            step = step + 1
        end
        if self.state == STATES.NORMAL then
            if #self.checkingGrids > 0 then
                self.state = STATES.CHECK_REPEAT
            elseif #self.uniqueDirtySoleMap > 0 then
                self.state = STATES.UNIQUE
            else
                local ret = self:checkSuccess()
                if ret == SuccessInfo.COMPLETE then
                    self.state = STATES.SUCCESS
                elseif ret == SuccessInfo.WRONG then
                    self.state = STATES.NO_ANSWER
                elseif ret == SuccessInfo.UNCOMPLETE then
                    self.state = STATES.START_GUESS
                end
            end
        elseif self.state == STATES.CHECK_REPEAT then
            for _, checkingGrid in ipairs(self.checkingGrids) do
                checkingGrid:startDeleteRepeat()
            end
            if self.isGuessing and self:checkWrong() == false then
                self.state = STATES.GUESS_WRONG
            else
                self.checkingGrids = {}
                self.state = STATES.NORMAL
            end
        elseif self.state == STATES.UNIQUE then
            for _, sole in pairs(self.uniqueDirtySoleMap) do
                sole:checkUnique()
            end
            if self.isGuessing and self:checkWrong() == false then
                self.state = STATES.GUESS_WRONG
            else
                self.uniqueDirtySoleMap = {}
                self.state = STATES.NORMAL
            end
        elseif self.state == STATES.START_GUESS then
            local startIndex = 1
            if self.recorder:hasRecord() then
                ---@type Record
                local record = self.recorder:getRecord()
                startIndex = record.gridIndex + 1
            end
            local gridsClone = {}
            for i, grid in ipairs(self.grids) do
                gridsClone[i] = grid
            end
            table.sort(gridsClone, function(grid1, grid2)
                local len1 = #grid1:getCandidate()
                local len2 = #grid2:getCandidate()
                if len1 ~= len2 then
                    return len1 < len2
                end
                local row1 = grid1:getRow()
                local row2 = grid2:getRow()
                if row1 ~= row2 then
                    return row1 < row2
                end
                return grid1:getLine() < grid2:getLine()
            end)
            ---@type Grid[]
            local grids
            if littleGuess then
                grids = self.grids
            else
                grids = gridsClone
            end
            for i = startIndex, #grids do
                local grid = grids[i]
                if #grid:getCandidate() > 1 then
                    ---@type Record
                    local record = {}
                    record.gridIndex = i
                    record.candidateIndex = 1
                    local shortCut = {}
                    record.gridsShortcut = shortCut
                    record.gridsClones = gridsClone
                    for j, g in ipairs(grids) do
                        shortCut[j] = clone(g:getCandidate())
                    end
                    self.recorder:createRecord(record)
                    self.state = STATES.GUESS_NEXT
                    self.isGuessing = true
                    break
                end
            end
        elseif self.state == STATES.GUESS_NEXT then
            ---@type Record
            local record = self.recorder:getRecord()
            local gridIndex = record.gridIndex
            local candidateIndex = record.candidateIndex
            local value = record.gridsShortcut[gridIndex][candidateIndex]
            if value ~= nil then
                ---@type Grid[]
                local grids
                if littleGuess then
                    grids = self.grids
                else
                    grids = record.gridsClones
                end
                grids[record.gridIndex]:setValue(value)
                record.candidateIndex = record.candidateIndex + 1
                self.state = STATES.NORMAL
            else
                self.state = STATES.GUESS_FAILED
            end
        elseif self.state == STATES.SUCCESS then
            print("success")
            break
        elseif self.state == STATES.NO_ANSWER then
            print("no answer")
            break
        elseif self.state == STATES.GUESS_WRONG then
            ---@type Record
            local record = self.recorder:getRecord()
            ---@type Grid[]
            local grids
            if littleGuess then
                grids = self.grids
            else
                grids = record.gridsClones
            end
            for i, grid in ipairs(grids) do
                grid.candidate = clone(record.gridsShortcut[i])
            end
            self.state = STATES.GUESS_NEXT
        elseif self.state == STATES.GUESS_FAILED then
            self.recorder:undo()
            if self.recorder:hasRecord() then
                self.state = STATES.GUESS_WRONG
            else
                self.state = STATES.NO_ANSWER
            end
        end
        if verbose then
            print("curStep", step)
            print(self:output(true))
        end
    end
    if verbose then
        print("step", step)
    end
end

function Sudoku:checkWrong()
    ---@type Sole[][]
    local allSoles = {self.rows, self.lines, self.squares}
    for _, soles in ipairs(allSoles) do
        for _, sole in ipairs(soles) do
            sole:checkSole()
            if sole:checkSole() == -1 then
                return false
            end
        end
    end
    return true
end

---onFixNewValue
---@param event Event.EventData
function Sudoku:onFixNewValue(event)
    local grid = event:getTarget()
    table.insert(self.checkingGrids, grid)
end

---onDeleteCandidate
---@param event Event.EventData
function Sudoku:onDeleteCandidate(event)
    ---@type Grid
    local grid = event:getTarget()
    self:addUniqueDirtySole(self.rows[grid:getRow()])
    self:addUniqueDirtySole(self.rows[grid:getLine()])
    self:addUniqueDirtySole(self.rows[grid:getSquare()])
end

---addUniqueDirtySole
---@param sole Sole
function Sudoku:addUniqueDirtySole(sole)
    for _, s in ipairs(self.uniqueDirtySoleMap) do
        if s == sole then
            return
        end
    end
    table.insert(self.uniqueDirtySoleMap, sole)
end
return Sudoku