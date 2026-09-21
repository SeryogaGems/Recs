--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

local mask = 0b0001_0000i

const function flipBit(mask: integer, bit: integer): integer
    local shift = integer.lshift(1i, bit)
    return integer.bxor(mask, shift)
end
