local parser = {}

parser.values = {}
local linecount = 0
function parser.parseargs(args, funcname)
    if args:sub(#args,#args) ~= "," then
        args = args .. ","
    end
    local stack      = {}
    local strstarted = false
    local strstarti  = 0
    local argi       = 0
    local index      = 0
    for i = 1, #args do
        local char = args:sub(i,i)
        if char == "\"" then
            if strstarted == true then
                if i ~= #args then
                    if args:sub(i+1,i+1) ~= "," then
                        print("Line "..linecount..": Expected \",\" near '" .. funcname .. " " .. args:sub(1, i) .. "...'")
                        return false
                    else
                        argi = i+1
                    end
                end
                table.insert(stack,{"string",args:sub(strstarti+1, i-1)})
                strstarted = false
            else
                strstarted = true
                strstarti  = i
            end
        elseif char == "," and strstarted == false and i ~= argi then
            if tonumber(args:sub(argi+1,i-1)) then
                table.insert(stack,{"number",args:sub(argi+1,i-1)})
                argi = i
            else
                table.insert(stack,{"var",args:sub(argi+1,i-1)})
                argi = i
            end
        end
    end
    return true, stack
end

function parser.parseinst(inst)
    local type = inst[1]
    local val  = inst[2]
    if type == "number" then
        return tonumber(val)
    elseif type == "string" then
        return tostring(val)
    elseif type == "var" then
        if parser.values[val] then
            return parser.parseinst(parser.values[val])
        else
            return "NULL"
        end
    else
        return "NULL"
    end
end

parser.funcs = {["OUTPUT"] = function(args)
        print("OUTPUT CALLED")
        for i=1,#args do
            print(parser.parseinst(args[i]))
        end
    end}

function parser.run(script)
    for line in script:gmatch("[^\r\n]+") do
        linecount = linecount + 1
        local space = (line:find("%s") or #line + 1)
        local funcname = line:sub(1,space - 1)
        if parser.funcs[funcname] then
            local suc,args = parser.parseargs(line:sub(space + 1), funcname)
            if suc then
                parser.funcs[funcname](args)
            else
                return
            end
        elseif line:sub(space + 1, space + 1) == "=" then
            if line:sub(space + 3, space + 3) == "\"" then
                if line:sub(#line, #line) == "\"" then
                    parser.values[funcname] = {"string", line:sub(space + 4, #line-1)}
                else
                    print("Line " .. tostring(linecount) .. ":" .. #line .. ": Expected a \" to close String.")
                    return
                end
            elseif tonumber(line:sub(space + 3, #line)) then
                parser.values[funcname] = {"number", tonumber(line:sub(space + 3, #line))}
            else
                if line:sub(space + 3, #line):gsub("%s+", "") == line:sub(space + 3, #line) then
                    parser.values[funcname] = parser.values[line:sub(space + 3, #line)] or {"NULL", "NULL"}
                else
                    print("Line " .. tostring(linecount) .. ": Spaces are not allowed in Variable names!")
                    return
                end
            end
        else
            print("Line " .. tostring(linecount) .. ": Global "..funcname.." not found.")
            return
        end
    end
end

return parser