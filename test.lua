local script = io.open("main.sn"):read("*a")
local parser = require("parser/main")
parser.run(script)