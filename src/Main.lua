---
--- Created by Administrator.
--- DateTime: 2017/11/16 22:06
---
package.path = package.path .. ";../../../usefulLib/lua/?.lua"
require("class")
require("Logger")

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

--print(sudoku:output())
--sudoku:checkDirty()
--print(sudoku:output())

local a = require("Event.EventDispatcher").new()
local b = {}
local c = {}
setmetatable(c, {__mode = "k"})
c[b] = 1

b.ff = function(self, ed)
    print("1", ed:getTarget() == a, ed:getData())
    --print(ed:getData())
end

local f2 = function()
    print(2)
end

a:addEventListener("ff", b.ff, nil, 0, true)
--a:removeEventListener("ff", b.ff, nil, 0, true)
--a:addEventListener("ff", f2, nil, 1, false)
b = nil
collectgarbage()
for t, v in pairs(c) do
    print(t)
end
a:dispatchEvent("ff", "gasdf")

