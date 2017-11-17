---
--- Created by Administrator.
--- DateTime: 2017/11/16 23:53
---

local function getStack()
    return debug.traceback()
end

function logError(...)
    local s = "err:"
    for _, v in ipairs({...}) do
        s = s .. " " .. tostring(v)
    end
    s = s .. "\n" .. debug.traceback()
    print(s)
end

function logDebug()

end

function logWarning()

end

function logInfo()
    
end