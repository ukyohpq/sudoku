---
--- Created by Administrator.
--- DateTime: 2017/11/16 23:53
---

function logErr(...)
    local s = tostring(unpack({...})) .. "\n"
    s = s .. debug.traceback()
    print(s)
end