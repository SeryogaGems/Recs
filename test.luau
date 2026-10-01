--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

const Bench = function(fn: () -> ()): number
	local st = os.clock()
    for i = 1, 1e6 do
        fn()
	end
    return os.clock() - st
end

local mask1 = 0b0000_0001_0001_0001_0000_0000_0000_0001i
local mask2 = integer.create(bit32.bor((1 * 16 + 1), bit32.lshift((1 * 64 + 1), 20)))

const fn1 = Bench(function()
	local chunk = integer.extract(mask1, 0i, 16i)
	local segment = integer.extract(mask1, 16i, 4i)
	local block = integer.extract(mask1, 20i, 4i)
	local bitmap = integer.extract(mask1, 24i, 8i)
	
	local pos = 16 * integer.tonumber(chunk) + integer.tonumber(segment)
	local index = 64 * integer.tonumber(block) + integer.tonumber(bitmap)
end)

const fn2 = Bench(function()
	local complexFirst = integer.extract(mask2, 0i, 20i)
	local complexSecond = integer.extract(mask2, 20i, 12i)

    local cF = integer.tonumber(complexFirst)
    local cS = integer.tonumber(complexSecond)
	
	local chunk = cF // 16
	local segment = cF - (chunk * 16)
	
	local block = cS // 64
	local bitmap = cS - (block * 64)

    local x = integer.create(5)
end)

print(fn1, fn2)