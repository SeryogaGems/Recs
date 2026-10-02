--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

-- Entity id type |[]|
type IndexId = number

-- Entity mask bit-sizes: |[
-- Entity(u64) / Group(u52) [integer]
-- Type(u16) / Multi-Component(u8) [number]
-- Component(u12) / Tag(u4) [number] ]|
type u64 = integer
type u48 = integer
type u32 = number

-- Type functions |[]|
type function __ecs_group(relation: type, target: type): type
    local entitySingleton = types.singleton("__T")
    
    local type_relation = relation:readproperty(entitySingleton)
    local type_target = target:readproperty(entitySingleton)

    assert(type_relation and type_target, "Expected type Entity<T>, but a different type was passed for the relation or target.")

    local groupSingleton = types.singleton("__GROUP")
    local groupIsActiveSignleton = types.singleton(true)

    local __group = types.newtable()
    __group:setreadproperty(groupSingleton, groupIsActiveSignleton)
    __group:setreadproperty(entitySingleton, type_relation)

    return __group
end

type function __ecs_create_entity(generic: type): type
    local entitySignleton = types.singleton("__T")

    local __entity = types.newtable()
    __entity:setreadproperty(entitySignleton, generic)

    return __entity
end

type function __ecs_is_entity(entity: type): type
    local entitySingleton = types.singleton("__T")

    local type_entity = entity:readproperty(entitySingleton)
    assert(type_entity, "Expected type Entity<T>, but a different type was passed for the entity.")

    return types.number
end

-- Types for internal world tables |[
-- Structural types within components and meta
type ChunkBuffer = { buffer? }
type ChunkValue <U> = { { U }? }
type ChunkHooks <U> = number | { Callback <U>? }
type Struct <U> = { buffer | ChunkHooks <U> | ChunkBuffer | ChunkValue<U>? }

-- Types for special caches
type QueryCache = {[IndexId]: {}}
type GroupCache = {[u48]: IndexId}

-- Basic types of world tables ]|
type Entities = { [IndexId]: u64 | u48 | u32 }
type Sparse = { [IndexId]: u32 }
type Dense <U> = { [u32]: Struct <U> }
type Cache = { [IndexId]: buffer? }
type Pack = { [string]: IndexId }

-- |[]|
type Entity <T> = { read __T: T }
type Group <Relation, Target> = __ecs_group<Relation, Target>
type Callback <U> = (entity: Entity<number>, component: Entity<U>, ...U) -> (any)

-- Exported types |[]|
export type Id <T> = { read __T: T }
export type IdGroup <T> = { read __GROUP: true, read __T: T }
export type World = { read Entities | Sparse | Dense <unknown> | Cache | QueryCache | GroupCache }

-- Localizing functions for reuse |[
-- Disabling the GETIMPORT compiler instruction
-- INTEGER std::library methods localization
local XOR = integer.bxor
local AND = integer.band
local NOT = integer.bnot
local OR = integer.bor
local COUNTRZ = integer.countrz
local LSHIFT = integer.lshift
local EXTRACT64 = integer.extract
local ICREATE = integer.create
local TONUMBER = integer.tonumber

-- BIT32 std::library methods localization
local EXTRACT32 = bit32.extract

-- BUFFER std::library methods localization
local BCREATE = buffer.create
local WRITEU8 = buffer.writeu8
local READU8 = buffer.readu8
local WRITEU16 = buffer.writeu16
local READU16 = buffer.readu16
local WRITEU32 = buffer.writeu32
local READU32 = buffer.readu32
local WRITEINTEGER = buffer.writeinteger
local READINTEGER = buffer.readinteger
local LEN = buffer.len
local FILL = buffer.fill

-- MATH std::library methods localization 
local MIN = math.min

-- TABLE std::library methods localization ]|
local TCREATE = table.create
local MOVE = table.move
local CLEAR = table.clear

-- Fields and width of bitwise take operations |[
-- Fields maskes
const BIT_INTEGER_ZERO = 0x0i
const BIT_INTEGER_U12 = 0x12i
const BIT_INTEGER_U16 = 0x10i
const BIT_INTEGER_U20 = 0x14i
const BIT_INTEGER_U24 = 0x18i

const BIT_NUMBER_ZERO = 0x0
const BIT_NUMBER_U4 = 0x4
const BIT_NUMBER_U8 = 0x8
const BIT_NUMBER_U16 = 0x10
const BIT_NUMBER_U40 = 0x28
const BIT_NUMBER_U64 = 0x40

-- Maximum size limits in numbers |[
-- Filling of component structures
const MAXSIZE_STRUCT_CHUNK = 0xFFFFi -- 16[0b1] bits
const MAXSIZE_STRUCT_SEGMENT = 0xFi -- 8[0b1] bits
const MAXSIZE_STRUCT_BLOCK = 0xFi -- 4[0b1] bits

-- Dimensions of the basic structures of the world |[
-- Maximum and initial values ​​for component structures
const ELEMENTS_STRUCT_BITMAP = 0x5 -- 5
const ELEMENTS_STRUCT_SEGMENT_META = 0x8 -- 8
const ELEMENTS_STRUCT_CHUNK_SOA = 0x10 -- 16
const ELEMENTS_STRUCT_SEGMENT = 0x100 -- 256
const ELEMENTS_STRUCT_CHUNK_ENTITY = 0x1000 -- 4096

-- Byte representation of bit types |[]|
const BYTE_U64 = 0x8 -- 8 bytes
const BYTE_U32 = 0x4 -- 4 bytes
const BYTE_U16 = 0x2 -- 2 bytes

-- |[]|
const BUFFER_META_SEGMENT_TYPE_OFFSET = 0x288 -- уточнить

const INDEX_COMPONENT_BITMAP = 1
const INDEX_COMPONENT_HOOKS = 2
const INDEX_COMPONENT_TECH = 3
const INDEX_CHUNK_ENTITY = 4
const INDEX_CHUNK_VALUE = 5

-- ID indexes with offsets from the beginning of the entity table |[]|
const ID_ZERO = 0
const ID_SPECIAL_MAX = 11
const ID_TYPE_MAX = 256
const ID_COMPONENT_MAX = 512

-- World indexes
const ENTITIES = 1
const SPARSE = 2
const DENSE = 3
const SEGMENT_CACHE = 4
const GROUP_CACHE = 5
const RELATION_GRAPH_CACHE = 6
const TARGET_GRAPH_CACHE = 7
const QUERY_CACHE = 8
const HOOK_CACHE = 9

-- Special immutable types for the library ]|
export const Wildcard = ID_ZERO + 1
export const Component = ID_ZERO + 2
export const Type = ID_ZERO + 3
export const Add = ID_ZERO + 4
export const Remove = ID_ZERO + 5
export const Changed = ID_ZERO + 6
export const ChildOf = ID_ZERO + 7

-- Error messages |[
-- Overflow error
const ERROR_OVERFLOW_MESSAGE = [[
    Oh no! You've exceeded the allowed limit!
    Remove unnecessary objects or follow the instructions. 
    Examples are provided in the library documentation.
]]

const ERROR_COMPONENT_BEHAIVOR = [[
    An attempt to assign component behavior to an Entity<number>.
]]

-- Mutable values ​​during library execution |[
-- Maximum and minimum position of a chunk in meta
local _structChunkHead = 1
local _structChunkTail = 1

-- Maximum position of components and entities in the world
local _componentIdHead = ID_TYPE_MAX + 1
local _entityIdHead = ID_COMPONENT_MAX + 1

-- Counters for the number of entities, types, and base components
local _worldEntity = 0
local _worldHooks = 0
local _worldDense = 0
local _worldCachedQueries = 0

-- Entity and component cache
local _cacheIdEntities: { number? }
local _cacheStructComponents: { Struct <unknown>? }
local _cacheTableSegments: { {}? }
local _cacheIdComponents: buffer

-- Entity and component cache size (var)
local _headIdEntities = 0
local _headIdComponents = 0
local _headEmptyStructs = 0
local _headEmptyChunks = 0

-- Packed objects
local _worldPacked = {} :: Pack

-- World variables ]|
local _WORLD_ARRAY: World
local _WORLD_NULL = true

const function ecs_error(errorMessage: string): never
    error(`[RECS]: {errorMessage}`)
end

const function _segmentAllocation <U> (cmp_struct: Struct <U>, struct_size: number, position: number): buffer
    local entity_struct = cmp_struct[INDEX_CHUNK_ENTITY] :: ChunkBuffer

    local newBuffer = BCREATE(ELEMENTS_STRUCT_SEGMENT * BYTE_U64)
    entity_struct[position] = newBuffer

    if struct_size == INDEX_CHUNK_ENTITY then return newBuffer end

    local value_struct = cmp_struct[INDEX_CHUNK_VALUE] :: ChunkValue <U>
    value_struct[position] = TCREATE(ELEMENTS_STRUCT_SEGMENT)

    if struct_size == INDEX_CHUNK_VALUE then return newBuffer end
end

const function _chunkInsertion <U> (cmp_struct: Struct <U>, struct_size: number, size: number, count: number?): buffer
    local chunks = count or _structChunkHead

    local tech_struct = cmp_struct[INDEX_COMPONENT_TECH] :: ChunkBuffer

    local difference = chunks - size
    local lastbuffer: buffer
    for i=1, difference do 
        lastbuffer = BCREATE(640) 
        tech_struct[size + i] = lastbuffer
    end

    if struct_size == INDEX_COMPONENT_TECH then return lastbuffer end

    local optional_dense_size = ELEMENTS_STRUCT_CHUNK_SOA * size
    local optional_dense_indexes = ELEMENTS_STRUCT_CHUNK_SOA * chunks

    local old_entity_struct = cmp_struct[INDEX_CHUNK_ENTITY] :: ChunkBuffer
    local new_entity_struct = TCREATE(optional_dense_indexes) :: ChunkBuffer

    MOVE(old_entity_struct, 1, optional_dense_size, 1, new_entity_struct)
    CLEAR(old_entity_struct)

    if struct_size == INDEX_CHUNK_ENTITY then 
        _headEmptyStructs += 1 
        _cacheStructComponents[_headEmptyStructs] = { 0, 0, 0, old_entity_struct } :: Struct <U>
        return lastbuffer 
    end

    local old_value_struct = cmp_struct[INDEX_CHUNK_VALUE] :: ChunkValue<U>
    local new_value_struct = TCREATE(optional_dense_indexes) :: ChunkValue<U>

    MOVE(old_value_struct, 1, optional_dense_size, 1, new_value_struct)
    CLEAR(old_value_struct)

    _headEmptyStructs += 1 
    _cacheStructComponents[_headEmptyStructs] = { 0, 0, 0, old_entity_struct, old_value_struct } :: Struct <U>

    return lastbuffer
end

const function _componentAllocation <U> (structSize: number, from: number?, to: number?): Struct <U>
    local start = from or 0
    local offset = to or _structChunkHead

    local tech_struct = TCREATE(offset) :: ChunkBuffer
    for i=1, offset do tech_struct[i] = BCREATE(640) end

    if structSize == INDEX_COMPONENT_TECH then return { BCREATE(64 * BYTE_U64), 0, tech_struct } end

    local optional_dense_indexes = ELEMENTS_STRUCT_CHUNK_SOA * offset

    local entity_struct = TCREATE(optional_dense_indexes) :: ChunkBuffer
    if structSize == INDEX_CHUNK_ENTITY then return { BCREATE(64 * BYTE_U64), 0, tech_struct, entity_struct } end

    local value_struct = TCREATE(optional_dense_indexes) :: ChunkValue <U>
    if structSize == INDEX_CHUNK_VALUE then return { BCREATE(64 * BYTE_U64), 0, tech_struct, entity_struct, value_struct } end

    return 5 :: any
end

const function _entitiesAllocation(entities: Entities): ()
    for i=1, ID_SPECIAL_MAX do entities[i] = i end
end

const function _metaAllocation(dense: Dense <unknown>, chunkCount: number): ()
    _structChunkHead = chunkCount
    dense[1] = _componentAllocation(INDEX_COMPONENT_TECH)
end

-- Creates a single, shared world instance with entity fields, components (sparse and dense), 
-- group graph caches, type segments, and queries. Preloads custom types and meta components.
-- If called again, the function will not be executed.
-- @param count The number of entities in the world
export function world(count: number?): World
    if not _WORLD_NULL then return _WORLD_ARRAY end

    local entitySize = (count or ELEMENTS_STRUCT_CHUNK_ENTITY * 5) + ID_COMPONENT_MAX
    local chunksCount = entitySize // ELEMENTS_STRUCT_CHUNK_ENTITY

    local entities = TCREATE(entitySize) :: Entities
    local dense = TCREATE(256) :: Dense <unknown>
    local segment_cache = TCREATE(256) :: Cache

    local query_cache = {} :: QueryCache
    local target_graph_cache = {} :: Cache
    local relation_graph_cache = {} :: Cache
    local group_cache = {} :: GroupCache
    local sparse = {} :: Sparse

    _cacheStructComponents = {}

    _entitiesAllocation(entities)
    _metaAllocation(dense, chunksCount)

    _WORLD_NULL = false
    _WORLD_ARRAY = table.freeze({ 
        entities, sparse, dense, segment_cache, 
        group_cache, relation_graph_cache, target_graph_cache, 
        query_cache
    })

    return _WORLD_ARRAY :: World
end

export function etype(): IndexId
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    return 0
end

export function entity <T> (etype: number, cluster: number?): Entity<number>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const segments = _WORLD_ARRAY[SEGMENT_CACHE] :: Cache
    const dense = _WORLD_ARRAY[DENSE] :: Dense<unknown>

    local cachePush = _headIdEntities == BIT_NUMBER_ZERO
    local id = if cachePush then _cacheIdEntities[_headIdEntities] else _worldEntity + 1
    _headIdEntities = cachePush and 0 or _headIdEntities - 1

    local typeSegments = segments[etype] :: buffer
    local typeId = entities[etype] :: u32

    -- local cacheHead = EXTRACT32(typeId, BIT_NUMBER_U16)
    -- local id_segment = READU16(typeSegments, cacheHead)

    local ichunk = ICREATE(1)
    local isegment = LSHIFT(ICREATE(0), BIT_INTEGER_U16)
    local iblock = LSHIFT(ICREATE(0), BIT_INTEGER_U20)
    local ibitmap = LSHIFT(ICREATE(10), BIT_INTEGER_U24)

    local icluster = LSHIFT(ICREATE(cluster or 1), 56i)
    local itype = LSHIFT(ICREATE(etype), 48i)

    local entityId = OR(ichunk, isegment, iblock, ibitmap, icluster, itype)

    entities[id] = entityId
    _worldEntity += 1

   return id :: __ecs_create_entity<T>
end

export function component <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    return id :: __ecs_create_entity<T>
end

export function multi <T> (count: number?): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    return id :: __ecs_create_entity<T>
end

export function tag <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    return id :: __ecs_create_entity<T>
end

export function group <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u48 = OR(irelation, itarget) -- 0bu48

    return id :: Group<Entity<T>, Entity<U>>
end

-- Adding a single component to a single entity
-- @param entity - entity ID under the generic API Entity<T>, where T is a number
-- @param component - component ID under the generic API Entity<U>
-- @param component - group ID under the generic API Group<>
export function add <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): ()
    -- Reading tables within WORLD_ARRAY with fields 1 through 3, where 
    -- 1 [Entities] is the table of entities
    -- 2 [Sparse] is the table of references to structures
    -- 3 [Dense] is the table of component structures
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense <U>

    -- Retrieving the bitmasks for the entity (integer) and the component (number)
    -- The entity is a mask with fields u20 for the first part, u12 for the second part, and the remaining bits
    -- The component ID is simply a reference
    -- The __ecs_is_entity<> function returns a number
    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    -- Reading the component structure.
    local cmp_struct = dense[componentId] :: Struct <U>

    -- Retrieving the table of technical buffers. Each buffer consists of one chunk
    -- The buffer size is 640 bytes, or 16 slices of 40 bytes (or 16 slices of 5 integers)
    local tech_struct = cmp_struct[INDEX_COMPONENT_TECH] :: ChunkBuffer

    -- Reading 20 bits and converting the 64-bit value into a number
    -- The composite position combines the chunk number (0..65_534) and the segment number (0..15)
    local complexPosition = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U20)
    local positionNumber = TONUMBER(complexPosition) -- from 0

    -- Conversion of a composite position into separate components using the following formulas:
    -- Chunk = composite position // 16, where // denotes integer division (discarding the remainder)
    -- Segment = composite position - (chunk * 16)
    -- The number 16 was chosen because it is the maximum number of segments for a single chunk
    local chunk = positionNumber // BIT_NUMBER_U16
    local segment = positionNumber - (chunk * BIT_NUMBER_U16)

    -- Attempt to find a technical chunk buffer. If nothing is found, allocate a new chunk
    -- This is a rare but expensive operation called a "chunk miss"
    -- This happens if the meta has chunks ahead of the component
    -- Footnote: When creating the world, it is worth specifying an entity limit to avoid allocations
    local techbuffer = tech_struct[chunk + 1] :: buffer?
    local cmpsize: number
    if not techbuffer then 
        -- Size of component structure fields
        -- The allocator accepts the structure itself, the number of fields in the structure, and the maximum chunk number
        cmpsize = #cmp_struct
        techbuffer = _chunkInsertion(cmp_struct, cmpsize, #tech_struct)
    end

    -- Reading the entity buffer table
    local entity_struct = cmp_struct[INDEX_CHUNK_ENTITY] :: ChunkBuffer

    -- Reading 12 bits from 20 bit and converting the 64-bit value into a number
    -- Complex index transformation. It combines a block (0..4) and a bitmap (0..63)
    local complexIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U12)
    local indexNumber = TONUMBER(complexIndex) -- from 0

    -- Decomposition of the composite index into two components using the formulas:
    -- Block – composite index // 64, where // denotes integer division
    -- Bitmap – composite index – (block * 64)
    -- The number 64 was chosen because it is the maximum number of segments for a single block (or, more accurately, a bitmap)
    local block = indexNumber // BIT_NUMBER_U64
    local bitmap = indexNumber - (block * BIT_NUMBER_U64)

    -- Reading the entity buffer. If nothing is found, a segment is allocated
    -- The index is equivalent to the position
    -- Note: Segment creation is a lazy process. Allocation occurs immediately upon each new initialization
    local index = positionNumber + 1
    local entitybuffer = entity_struct[index] :: buffer?
    if not entitybuffer then 
        -- What is needed is the structure itself, the structure's size (i.e., how many fields it has), and the current position with table padding
        entitybuffer = _segmentAllocation(cmp_struct, cmpsize or #cmp_struct, index)

        -- Since this is a new segment, its presence needs to be noted in higher-level masks
        local quadmaskbuffer = cmp_struct[INDEX_COMPONENT_BITMAP] :: buffer

        -- A single quadrant consists of 4 chunks packed into a single 64-bit integer
        -- Essentially, these are 15-bit sets arranged sequentially, starting from bit position 0
        local quadBuffer = cmp_struct[1] :: buffer
        local quadOffset = (chunk // BIT_NUMBER_U4) * BIT_NUMBER_U8
        local bitInQuad = (chunk % BIT_NUMBER_U4) * BIT_NUMBER_U16 + segment

        local quadMask = READINTEGER(quadBuffer, quadOffset)

        -- Bit flipping
        local intQuad = ICREATE(bitInQuad)
        quadMask = OR(quadMask, LSHIFT(1i, intQuad))

        WRITEINTEGER(quadBuffer, quadOffset, quadMask)
    end

    -- Obtaining the offset where the required bitmap is located
    -- The value is multiplied by the total weight of one buffer slice and shifted by 8, since an integer is 8 bytes
    local offset = segment * BIT_NUMBER_U40 + (block + 1) * BIT_NUMBER_U8
    local mask = READINTEGER(techbuffer :: buffer, offset)

    -- If the mask consists entirely of zeros, registration takes place at the segment block level
    -- The corresponding bit is flipped to 1
    if mask == BIT_INTEGER_ZERO then
        -- Calculating the required block within the technical buffer
        local segmentOffset = segment * BIT_NUMBER_U40
        local segmentMask = READINTEGER(techbuffer :: buffer, segmentOffset)

        -- Bit flip
        local intBlock = ICREATE(block)
        segmentMask = XOR(segmentMask, LSHIFT(1i, intBlock))

        WRITEINTEGER(techbuffer :: buffer, segmentOffset, segmentMask)
    end

    -- A bit flip at an address registered by the entity within the technical buffer
    -- This corresponds to a specific position within a 64-bit number
    local intBitmap = ICREATE(bitmap)
    mask = XOR(mask, LSHIFT(1i, intBitmap))

    -- Writing the modified bitmap with the flipped bit associated with the entity
    -- Adding the entity ID to the buffer
     -- The __ecs_is_entity<> function returns a number
    WRITEINTEGER(techbuffer :: buffer, offset, mask)
    WRITEU32(entitybuffer :: buffer, indexNumber, entity :: __ecs_is_entity<typeof(entity)>)

    -- query cache invalid
end

export function remove <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense <U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct <U>

    local tech_struct = cmp_struct[INDEX_COMPONENT_TECH] :: ChunkBuffer

    local complexPosition = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U20)
    local positionNumber = TONUMBER(complexPosition) -- from 0

    local chunk = positionNumber // BIT_NUMBER_U16
    local segment = positionNumber - (chunk * BIT_NUMBER_U16)

    local techbuffer = tech_struct[chunk + 1] :: buffer

    local entity_struct = cmp_struct[INDEX_CHUNK_ENTITY] :: ChunkBuffer

    local complexIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U12)
    local indexNumber = TONUMBER(complexIndex) -- from 0

    local block = indexNumber // BIT_NUMBER_U64
    local bitmap = indexNumber - (block * BIT_NUMBER_U64)

    local entitybuffer = entity_struct[positionNumber + 1] :: buffer

    local offset = segment * BIT_NUMBER_U40 + (block + 1) * BIT_NUMBER_U8
    local mask = READINTEGER(techbuffer, offset)

    local intBitmap = ICREATE(bitmap)
    mask = XOR(mask, LSHIFT(1i, intBitmap))

    if mask == BIT_INTEGER_ZERO then
        local segmentOffset = segment * BIT_NUMBER_U40
        local segmentMask = READINTEGER(techbuffer, segmentOffset)

        local intBlock = ICREATE(block)
        segmentMask = XOR(segmentMask, LSHIFT(1i, intBlock))

        if segmentMask == BIT_INTEGER_ZERO then
            local quadmaskbuffer = cmp_struct[INDEX_COMPONENT_BITMAP] :: buffer

            local quadBuffer = cmp_struct[1] :: buffer
            local quadOffset = (chunk // BIT_NUMBER_U4) * BIT_NUMBER_U8
            local bitInQuad = (chunk % BIT_NUMBER_U4) * BIT_NUMBER_U16 + segment

            local quadMask = READINTEGER(quadBuffer, quadOffset)

            local intQuad = ICREATE(bitInQuad)
            quadMask = OR(quadMask, LSHIFT(1i, intQuad))

            WRITEINTEGER(quadBuffer, quadOffset, quadMask)
        end

        WRITEINTEGER(techbuffer, segmentOffset, segmentMask)
    end

    WRITEINTEGER(techbuffer, offset, mask)
    WRITEU32(entitybuffer, indexNumber, 0)

    -- query cache invalid
end

export function get <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): U?
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct <U>

    local complexPosition = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U20)
    local complexIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U12)

    local sg_struct = cmp_struct[INDEX_CHUNK_VALUE] :: ChunkValue <U>
    local tbl_value = sg_struct[TONUMBER(complexPosition) + 1] :: { U? }

    return tbl_value[TONUMBER(complexIndex) + 1]
end

export function set <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>, value: U): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct <U>

    local complexPosition = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U20)
    local complexIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U12)

    local sg_struct = cmp_struct[INDEX_CHUNK_VALUE] :: ChunkValue <U>
    local tbl_value = sg_struct[TONUMBER(complexPosition) + 1] :: { U? }

    tbl_value[TONUMBER(complexIndex) + 1] = value

    -- query cache invalid
end

export function has <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense <U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct <U>

    local tech_struct = cmp_struct[INDEX_COMPONENT_TECH] :: ChunkBuffer

    local complexPosition = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U20)
    local positionNumber = TONUMBER(complexPosition) -- from 0

    local chunk = positionNumber // BIT_NUMBER_U16
    local segment = positionNumber - (chunk * BIT_NUMBER_U16)

    local techbuffer = tech_struct[chunk + 1] :: buffer

    local complexIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U12)
    local indexNumber = TONUMBER(complexIndex) -- from 0

    local block = indexNumber // BIT_NUMBER_U64
    local bitmap = indexNumber - (block * BIT_NUMBER_U64)

    local offset = segment * BIT_NUMBER_U40 + (block + 1) * BIT_NUMBER_U8
    local mask = READINTEGER(techbuffer, offset)

    local intBitmap = ICREATE(bitmap)
    return EXTRACT64(mask, intBitmap) ~= BIT_INTEGER_ZERO
end

export function exist <T, U> (entity: Entity<T> | Group<Entity<T>, Entity<U>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64 | u48 | u32
    return entityId ~= BIT_NUMBER_ZERO
end

export function hook <T> (entity: Entity<T>, hook: number, callback: Callback): ()
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local component_id = sparse[entity :: __ecs_create_entity<typeof(entity)>] :: u32
    if not component_id then ecs_error(ERROR_COMPONENT_BEHAIVOR) end

    local cmp_struct = dense[component_id]
    local hooks = cmp_struct[INDEX_COMPONENT_HOOKS] :: ChunkHooks <T>

    if not hooks then
        cmp_struct[INDEX_COMPONENT_HOOKS] = TCREATE(3)
    end

    if hook == Add then end
    if hook == Remove then return end
    if hook == Changed then return end
end

export function clear <T> (entity: Entity<T>): ()
    
end

export function destroy <T> (entity: Entity<T>): ()
    
end

-- export function query <A, B, C, D, E> (...: Entity<A | B | C | D | E>): Query<>
    
-- end

-- export function forEach(query: Query<T>): ()
    
-- end

const function disable(entity: Entity<number>): ()
    
end

const function fastGroup <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u48 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<Entity<T>, Entity<U>> end
    
    id = _headIdEntities == 0 and 
         ID_COMPONENT_MAX + (_worldEntity + 1) or _cacheIdEntities[_headIdEntities] :: number
    
    groups[uint_48] = id
    entities[id] = uint_48
    _worldEntity += 1

    const relation_cache = _WORLD_ARRAY[RELATION_GRAPH_CACHE] :: Cache
    const target_cache = _WORLD_ARRAY[TARGET_GRAPH_CACHE] :: Cache

    return id :: Group<Entity<T>, Entity<U>>
end

const function target <T, U> (entity: Entity<T>, relation: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

const function relation <T, U> (entity: Entity<T>, target: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

const function first <T, U> (group: Group<Entity<T>, Entity<U>>): Entity<T>
    local entities = _WORLD_ARRAY[ENTITIES] :: Entities

    local uint_48 = entities[group] :: u64
    local relation_id = EXTRACT64(uint_48, BIT_INTEGER_ZERO, BIT_INTEGER_U24)

    return relation_id :: __ecs_create_entity<U>
end

const function second <T, U> (group: Group<Entity<T>, Entity<U>>): Entity<any>
    local entities = _WORLD_ARRAY[ENTITIES] :: Entities

    local uint_48 = entities[group] :: u64
    local target_id = EXTRACT64(uint_48, BIT_INTEGER_U24, BIT_INTEGER_U24)

    return target_id :: __ecs_create_entity<U>
end

export const ImportRelations = {
    fastGroup = fastGroup,
    target = target,
    relation = relation,
    first = first,
    second = second
}

export const ImportQuery = {

}

export const ImportEntity = {
    
}

export const ImportProfiler = {

}