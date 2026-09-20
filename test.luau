--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

type AoSChunk = {integer | {buffer | {any}}}
type SoAChunk = {integer | {buffer} | {{any}}}

type Entities = {integer | number}
type Sparse = {[number]: number}
type Dense = {AoSChunk | SoAChunk}

const EXTRACT32 = bit32.extract
const EXTRACT64 = integer.extract
const TONUMBER = integer.tonumber

const INT64_CHUNK_WIDTH = 16i
const INT64_SEGMENT_WIDTH = 4i
const INT64_BLOCK_WIDTH = 4i
const INT64_BITMAP_WIDTH = 8i

const FIELD_CHUNK = 0i
const FIELD_SEGMENT = 16i
const FIELD_BLOCK = 20i
const FIELD_BITMAP = 24i

const AoSNumber = {0xFFFF, { buffer.create(40), buffer.create(1024), table.create(256) } }
const AoSInteger = {0xFFFFi, { buffer.create(40), buffer.create(1024), table.create(256) } }
const SoANumber = {0xFFFF, table.create(16, buffer.create(40)), table.create(16, buffer.create(1024)), table.create(16, table.create(256, "NULL"))}
const SoAInteger = {0xFFFF, table.create(16, buffer.create(40)), table.create(16, buffer.create(1024)), table.create(16, table.create(256, "NULL"))}

const World = {
    {0b0000_0001_0001_0001_0000_0000_0000_0001, 0b0000_0001_0001_0001_0000_0000_0000_0001i},
    {[2] = 2, [3] = 3, [4] = 4, [5] = 5},
    {{}, {AoSNumber}, {AoSInteger}, {SoANumber}, {SoAInteger}}
} :: {Entities | Sparse | Dense}

const function NumberAoSset(entity: number, component: number, value: number)
    const entities = World[1] :: Entities
    const sparse = World[2] :: Sparse
    const dense = World[3] :: Dense

    local entityId = entities[entity] :: number
    local componentId = sparse[component] :: number

    local componentStruct = dense[componentId] :: {AoSChunk}

    local chunk = entityId % 65536
    local ch_struct = componentStruct[chunk] :: AoSChunk

    local segment = EXTRACT32(entityId, 16, 4)
    local sg_struct = ch_struct[segment + 1] :: {buffer | {any}}

    local block = EXTRACT32(entityId, 20, 4)
    local bitmap = EXTRACT32(entityId, 24, 8)
    local index = 32 * block + bitmap

    local tbl_struct = sg_struct[3] :: {any}
    tbl_struct[index] = value
end

const function numberSoAset(entity: number, component: number, value: number)
    const entities = World[1] :: Entities
    const sparse = World[2] :: Sparse
    const dense = World[3] :: Dense

    local entityId = entities[entity] :: number
    local componentId = sparse[component] :: number

    local componentStruct = dense[componentId] :: {SoAChunk}

    local chunk = entityId % 65536
    local ch_struct = componentStruct[chunk] :: SoAChunk

    local segment = EXTRACT32(entityId, 16, 4)
    local sg_value_array = ch_struct[4] :: {{any}}

    local block = EXTRACT32(entityId, 20, 4)
    local bitmap = EXTRACT32(entityId, 24, 8)
    local index = 64 * block + bitmap

    local tbl_struct = sg_value_array[segment] :: {any}
    tbl_struct[index] = value
end

const function integerSoAset(entity: number, component: number, value: number)
    const entities = World[1] :: Entities
    const sparse = World[2] :: Sparse
    const dense = World[3] :: Dense

    local entityId = entities[entity] :: integer
    local componentId = sparse[component] :: number

    local componentStruct = dense[componentId] :: {SoAChunk}

    local chunk = EXTRACT64(entityId, FIELD_CHUNK, INT64_CHUNK_WIDTH)
    local ch_struct = componentStruct[TONUMBER(chunk)] :: SoAChunk

    local segment = EXTRACT64(entityId, FIELD_SEGMENT, INT64_SEGMENT_WIDTH)
    local sg_value_array = ch_struct[4] :: {{any}}

    local block = EXTRACT64(entityId, FIELD_BLOCK, INT64_BLOCK_WIDTH)
    local bitmap = EXTRACT64(entityId, FIELD_BITMAP, INT64_BITMAP_WIDTH)
    local index = 64 * TONUMBER(block) + TONUMBER(bitmap)

    local tbl_struct = sg_value_array[TONUMBER(segment)] :: {any}
    tbl_struct[index] = value
end

const function integerSoAadd(entity: number, component: number, value: number)
    const entities = World[1] :: Entities
    const sparse = World[2] :: Sparse
    const dense = World[3] :: Dense

    local entityId = entities[entity] :: integer
    local componentId = sparse[component] :: number

    local componentStruct = dense[componentId] :: {SoAChunk}

    local chunk = EXTRACT64(entityId, FIELD_CHUNK, INT64_CHUNK_WIDTH)
    local ch_struct = componentStruct[TONUMBER(chunk)] :: SoAChunk

    local segment = EXTRACT64(entityId, FIELD_SEGMENT, INT64_SEGMENT_WIDTH)
    local sg_techBuffer = ch_struct[2] :: {buffer}
    local sg_entityBuffer = ch_struct[3] :: {buffer}

    local block = EXTRACT64(entityId, FIELD_BLOCK, INT64_BLOCK_WIDTH)
    local bitmap = EXTRACT64(entityId, FIELD_BITMAP, INT64_BITMAP_WIDTH)
    local index = 64 * TONUMBER(block) + TONUMBER(bitmap)

    local tchb_struct = sg_techBuffer[TONUMBER(segment)] :: buffer
    local ent_struct = sg_entityBuffer[TONUMBER(segment)] :: buffer
end

const ITERATIONS = 800_000

const function Bench(fn: (number) -> (), times: number): number
  const start = os.clock()
    for i = 1, times do
    fn(i)
  end
  return os.clock() - start
end

const TIMES = 800_000

const array = table.create(10, 0)
const fn1 = Bench(function(i: number)
    NumberAoSset(1, 2, 5)
end, TIMES)

const fn2 = Bench(function(i: number)
    numberSoAset(1, 4, 5)
end, TIMES)

const fn3 = Bench(function(i: number)
    integerSoAset(2, 5, 5)
end, TIMES)

const fn4 = Bench(function(i: number)
    integerSoAadd(2, 5, 5)
end, TIMES)

print(`fn1: {fn1}s`)
print(`fn2: {fn2}s`)
print(`fn3: {fn3}s`)
print(`fn4: {fn4}s`)

