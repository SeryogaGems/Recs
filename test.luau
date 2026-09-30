--!strict
--!optimize 2
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

const Recs = require("./Recs")

Recs.world()

const function Bench(fn: () -> ())
    const st = os.clock()
    for i = 1, 1e4 do
        fn()
    end
    return os.clock() - st
end

const chunk_segment = 0b0000_00000000_00000001i
const bitmask = 0b0101_0110_0110i

const fn1 = Bench(function()
    local chunk, segment = integer.extract(chunk_segment, 0i, 16i), integer.extract(chunk_segment, 16i, 4i)

    local chunkNumber = integer.tonumber(chunk)
    local segmentNumber = integer.tonumber(segment)
end)

const fn2 = Bench(function()
    local all = integer.extract(bitmask, 0i, 20i)

    local allNumber = integer.tonumber(all)

    local chunk = allNumber // 16 - 1
    local segment = allNumber // 16
end)

print(fn1, fn2)