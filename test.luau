--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

const Recs = require("./Recs")

local st = os.clock()
Recs.world(1_000_000)
print(os.clock() - st)