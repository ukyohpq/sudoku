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
---@field uniqueDirtySoleMap table<Sole, boolean>
---@field state number
---@field unfixGrids Grid[]
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
    self.unfixGrids = {}
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
            if valueMap[n] == 0 then
                table.insert(self.unfixGrids, grid)
            end
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

function Sudoku:resetNewGuess()
    self.gridIndex = 1
    self.candidateIndex = 1
    self.needNewGuess = true
end

function Sudoku:guess2()
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
    while(true) do
        local ret = self:tttttfun(currentGrid)
        if ret == -1 then
            print("no answer")
            return
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
            return
        end
        if ret == 2 then
            currentGrid = currentGrid.next
        end
    end
end

function Sudoku:tttttfun(cGrid)
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
---getGuessParam
---猜数。如果基础的处理，没有把所有的未知数全部找到，那么就需要猜数。
---遍历grids，遇到有候选数的grid，就从第一个候选数开始猜，此时保存所有grid以及当前猜测进度的快照，然后使用基础处理法，
---如果不能成功，看是否有错误，如果有错误，那么需要通过快照回滚到猜数时的状态，然后看猜的grid是否还有下一个候选数，
---有就猜下一个候选数，没有，就猜下一个有候选数的grid的第一个数，如果连有候选数的grid都没有了，说明猜测进入了死胡同，
---这种情况只能出现在“猜上加猜”(下面有解释)的情况下，所以需要抛弃该快照，回滚到上一快照时的状态，再进行下一步猜测。
---如果没有错误，看是否破题，如果没有破题，则保存当前进度快照，在猜测的基础之上再猜，即前面说的“猜上加猜”的情况。
function Sudoku:getGuessParam()
    --初始化格子索引gridIndex和参考数索引candidateIndex都为1
    local gridIndex = self.gridIndex
    local candidateIndex = self.candidateIndex
    --取得记录的grid
    local grid = self.grids[gridIndex]
    --检测这个grid还有没有剩余参考数
    --如果有，那么就是用下一个参考数作为猜测数
    --否则，就找下一个未确定的grid，取其第一个参考数为猜测数
    --如果所有都找遍了，那么就退回到上一个记录点，再找
    --print(self:output(true))
    if #grid:getCandidate() < candidateIndex + 1 then
        for i = gridIndex + 1, #self.grids do
            local g = self.grids[i]
            if #g:getCandidate() > 1 then
                gridIndex = i
                candidateIndex = 1
                break
            end
        end
    else
        candidateIndex = candidateIndex + 1
    end
    --self.recorder:createRecord(gridIndex, candidateIndex)
    return gridIndex, candidateIndex
end

function Sudoku:revertRecord()
    self.recorder:undo()
    self.gridIndex = self.recorder:getRecord()[1]
    self.candidateIndex = self.recorder:getRecord()[2]
    for _, grid in ipairs(self.grids) do
        grid:revertToPrevRecord()
    end
end

function Sudoku:guess()
    local gridIndex, candidateIndex = self:getGuessParam()
    if self.gridIndex == gridIndex and self.candidateIndex == candidateIndex then
        if self.recorder:hasRecord() then
            self:revertRecord()
        else
            print("failed!!")
            return
        end
    else
        self.recorder:createRecord({gridIndex, candidateIndex})
    end
    --保存所有的grid的状态
    for _, grid in ipairs(self.grids) do
        grid:record()
    end
    local grid = self.grids[gridIndex]
    grid:setValue(grid:getCandidate()[candidateIndex])
    self:checkDirty()

    local si = self:checkSuccess()
    if si == SuccessInfo.COMPLETE then
        print("success!!!!")
    elseif si == SuccessInfo.WRONG then
        print("wrong!!!!")
        for _, grid in ipairs(self.grids) do
            grid:revertRecord()
        end
        self.gridIndex = self.recorder:getRecord()[1]
        self.candidateIndex = self.recorder:getRecord()[2]
        self:guess()
    else
        print("uncomplete!!!!")
        self:resetNewGuess()
        self:guess()
    end
    --print(self:output())
end

function Sudoku:testFun(verbose)
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
            elseif table.mapLen(self.uniqueDirtySoleMap) > 0 then
                self.state = STATES.UNIQUE
            --elseif #self.unfixGrids > 0 then
            --    self.state = STATES.START_GUESS
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
            for sole, _ in pairs(self.uniqueDirtySoleMap) do
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
                local record = self.recorder:getRecord()
                startIndex = record.gridIndex + 1
            end
            for i = startIndex, #self.grids do
                local grid = self.grids[i]
                if #grid:getCandidate() > 1 then
                    ---@type Record
                    local record = {}
                    record.gridIndex = i
                    record.candidateIndex = 1
                    local shortCut = {}
                    record.gridsShortcut = shortCut
                    for j, g in ipairs(self.grids) do
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
                self.grids[record.gridIndex]:setValue(value)
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
            for i, grid in ipairs(self.grids) do
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
    table.removeElement(self.unfixGrids, grid)
end

---onDeleteCandidate
---@param event Event.EventData
function Sudoku:onDeleteCandidate(event)
    local grid = event:getTarget()
    self.uniqueDirtySoleMap[self.rows[grid:getRow()]] = true
    self.uniqueDirtySoleMap[self.lines[grid:getLine()]] = true
    self.uniqueDirtySoleMap[self.squares[grid:getSquare()]] = true
end

return Sudoku