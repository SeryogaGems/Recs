--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

const Recs = require("./Recs")

const world = Recs.world()

print(Recs.component(), world[3][1][1])
