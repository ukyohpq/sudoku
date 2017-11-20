---
--- Created by Administrator.
--- DateTime: 2017/11/16 22:06
---
package.path = package.path .. ";../../../usefulLib/lua/?.lua"
require("class")
require("Logger")
require("Utils.TableUtil")

local sudoku = require("Sudoku").new({
    6,0,0,5,0,0,0,0,0,
    4,0,0,0,7,0,0,0,1,
    0,2,3,0,0,0,0,0,6,
    0,0,9,2,0,0,0,6,0,
    0,0,2,4,0,0,0,0,0,
    0,0,1,0,0,0,0,0,3,
    0,7,0,0,6,0,9,0,0,
    5,0,4,0,0,0,0,0,0,
    0,0,0,0,2,0,1,4,7,
})

print(sudoku:output())
sudoku:checkDirty()
print(sudoku:output(true))
local ret = sudoku:checkSuccess()
if ret == 0 then
    sudoku:makeSavePoint()
end
---@type Sudoku
local su2 = clone(sudoku)
su2:guess()
print(su2:output(true))