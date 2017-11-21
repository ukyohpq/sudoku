---
--- Created by Administrator.
--- DateTime: 2017/11/16 23:53
---

function logErr(...)
    local s = ""
    for _, v in ipairs({...}) do
        s = s .. tostring(v) .. " "
    end
    s = s .. "\n"
    s = s .. debug.traceback()
    print(s)
end