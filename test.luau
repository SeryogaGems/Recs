--!strict
--!optimize 2
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

const Recs = require("./Recs")

Recs.world()

const function Bench(fn: () -> ())
    const st = os.clock()
    for i = 1, 1e6 do
        fn()
    end
    return os.clock() - st
end

const entity = Recs.entity(5)
const tag = Recs.tag()
const component = Recs.component()

Recs.add(entity, tag)
Recs.add(entity, component)

Recs.get(entity, tag)
