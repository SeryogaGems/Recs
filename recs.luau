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
type u52 = integer
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
type SegmentBuffer = { buffer }
type SegmentValue <U> = { {U} }
type Chunk <U> = {u64 | SegmentBuffer | SegmentValue<U>} 
type LowChunk = {u64 | SegmentBuffer}
type Struct <U> = {Chunk <U> | LowChunk}

-- Types for special caches
type QueryCache = {[IndexId]: {}}
type GroupCache = {[u52]: IndexId}
type HookSignals = {[IndexId]: { Callback }}

-- Basic types of world tables ]|
type Entities = {[IndexId]: u64 | u52 | u32}
type Sparse = {[IndexId]: u32}
type Dense <U> = {[u32]: Struct <U>}
type Cache = {[IndexId]: buffer?}
type Pack = {[string]: IndexId}

-- |[]|
type Entity<T> = { read __T: T }
type Group<Relation, Target> = __ecs_group<Relation, Target>
type Callback = (entity: Entity<number>, component: Entity<unknown>, ...unknown) -> (any)

-- Exported types |[]|
export type Id<T> = { read __T: T }
export type IdGroup<T> = { read __GROUP: true, read __T: T }
export type World = { read Entities | Sparse | Dense <unknown> | Cache | QueryCache | GroupCache | HookSignals }

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
local BOR = bit32.bor
local BLSHIFT = bit32.lshift

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

-- MATH std::library methods localization 
local MIN = math.min

-- TABLE std::library methods localization ]|
local TCREATE = table.create

-- Fields and width of bitwise take operations |[
-- Fields maskes
const BIT_INTEGER_ZERO = 0x0i
const BIT_INTEGER_U4 = 0x4i
const BIT_INTEGER_U8 = 0x8i
const BIT_INTEGER_U16 = 0x10i
const BIT_INTEGER_U20 = 0x14i
const BIT_INTEGER_U24 = 0x18i

const BIT_NUMBER_ZERO = 0x0
const BIT_NUMBER_U4 = 0x4
const BIT_NUMBER_U8 = 0x8
const BIT_NUMBER_U16 = 0x10

-- Maximum size limits in numbers |[
-- Filling of component structures
const MAXSIZE_STRUCT_CHUNK = 0xFFFF -- 16[0b1] bits
const MAXSIZE_STRUCT_SEGMENT = 0xFF -- 8[0b1] bits
const MAXSIZE_STRUCT_BLOCK = 0xF -- 4[0b1] bits

-- Dimensions of the basic structures of the world |[
-- Maximum and initial values ​​for component structures
const ELEMENTS_STRUCT_SEGMENT_META = 0x8 -- 8
const ELEMENTS_STRUCT_CHUNK_SOA = 0x10 -- 16
const ELEMENTS_STRUCT_SEGMENT_BUFFER = 0x28 -- 40
const ELEMENTS_STRUCT_SEGMENT = 0x100 -- 256
const ELEMENTS_STRUCT_CHUNK_ENTITY = 0x1000 -- 4096

-- Maximum and initial values ​​for meta
const ELEMENTS_META = 0x1 -- 1
const ELEMENTS_META_SEGMENT_META = 0x6 -- 6

-- Byte representation of bit types |[]|
const BYTE_U64 = 0x8 -- 8 bytes
const BYTE_U32 = 0x4 -- 4 bytes
const BYTE_U16 = 0x2 -- 2 bytes

-- |[]|
const BUFFER_BLOCK_OFFSET = 0x0
const BUFFER_META_TYPE_OFFSET = 0x6

const INDEX_CHUNK_BITMAP = 1
const INDEX_CHUNK_TECH = 2
const INDEX_CHUNK_ENTITY = 3
const INDEX_CHUNK_VALUE = 4

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

-- Specials |[
-- Special types of masks
const ECS_MASK_ADD = 0b0001
const ECS_MASK_REMOVE = 0b0010
const ECS_MASK_CHANGED = 0b0100
const ECS_MASK_ACTIVE = 0b1000

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

-- Rewriting a tag ]|
const ERROR_TAG_MUTABLE = [[
    Adding values using Recs.set() for tags is prohibited. 
    Use other component structures.
]]

-- Mutable values ​​during library execution |[
-- Maximum and minimum position of a chunk in meta
local _structChunkHead = 1
local _structChunkTail = 1

-- Maximum position of components and entities in the world
local _componentIdHead = ID_TYPE_MAX + 1
local _entityIdHead = ID_COMPONENT_MAX + 1

-- Counters for the number of entities, types, and base components
local _worldTypes = 0
local _worldBasicComponents = 0
local _worldEntity = 0
local _worldHooks = 0

-- Entity and component cache
local _worldEntityCache: { number? }
local _worldChunkCache: { Chunk<unknown>? }
local _worldLowChunkCache: { LowChunk? }
local _worldSegmentTableCache: { {} }
local _worldComponentCache: buffer

-- Entity and component cache size (var)
local _worldEntityCacheHead = 0
local _worldComponentCacheHead = 0
local _worldSegmentTableCacheHead = 0

-- Packed objects
local _worldPacked = {} :: Pack

-- World variables ]|
local _WORLD_ARRAY: World
local _WORLD_NULL = true

const function ecs_error(errorMessage: string): never
    error(`[RECS]: {errorMessage}`)
end

const function _allocateChunk <U> (componentStruct: Struct<U>, size: number, componentChunkHead: number?): Chunk<U>? | LowChunk
    local chunk: Chunk<U> | LowChunk

    return chunk
end

const function _allocateSegment <U> (chunk: Chunk<U> | LowChunk, position: number, size: number): (buffer, buffer)
    local techbuf_struct = chunk[INDEX_CHUNK_TECH] :: SegmentBuffer
    local entitybuf_struct = chunk[INDEX_CHUNK_ENTITY] :: SegmentBuffer

    local techbuf = BCREATE(40)
    local entitybuf = BCREATE(1024)

    techbuf_struct[position] = techbuf
    entitybuf_struct[position] = entitybuf

    if size == INDEX_CHUNK_ENTITY then return techbuf, entitybuf end
    
    local valuetbl_struct = chunk[INDEX_CHUNK_VALUE] :: SegmentValue<U>

    local valuetbl = _worldSegmentTableCache[_worldSegmentTableCacheHead] :: {U} or TCREATE(256) :: {U}
    valuetbl_struct[position] = valuetbl

    if size == INDEX_CHUNK_VALUE then return techbuf, entitybuf end
        
    local multivalues = size - INDEX_CHUNK_VALUE

    if multivalues == 4 then
        local multivaluetbl_struct = chunk[INDEX_CHUNK_VALUE + 4] :: SegmentValue<unknown>

        local multivaluetbl = _worldSegmentTableCache[_worldSegmentTableCacheHead] :: {unknown} or TCREATE(256) :: {unknown}
        multivaluetbl_struct[position] = multivaluetbl

        return techbuf, entitybuf
    end

    if multivalues == 3 then
        local multivaluetbl_struct = chunk[INDEX_CHUNK_VALUE + 3] :: SegmentValue<unknown>

        local multivaluetbl = _worldSegmentTableCache[_worldSegmentTableCacheHead] :: {unknown} or TCREATE(256) :: {unknown}
        multivaluetbl_struct[position] = multivaluetbl

        return techbuf, entitybuf
    end

    if multivalues == 2 then
        local multivaluetbl_struct = chunk[INDEX_CHUNK_VALUE + 2] :: SegmentValue<unknown>

        local multivaluetbl = _worldSegmentTableCache[_worldSegmentTableCacheHead] :: {unknown} or TCREATE(256) :: {unknown}
        multivaluetbl_struct[position] = multivaluetbl

        return techbuf, entitybuf
    end

    local multivaluetbl_struct = chunk[INDEX_CHUNK_VALUE + 1] :: SegmentValue<unknown>

    local multivaluetbl = _worldSegmentTableCache[_worldSegmentTableCacheHead] :: {unknown} or TCREATE(256) :: {unknown}
    multivaluetbl_struct[position] = multivaluetbl

    return techbuf, entitybuf
end

const function _allocateEntities(entities: Entities): ()
    _worldTypes = ID_SPECIAL_MAX
    
    for i = 1 :: u32, ID_SPECIAL_MAX do
        entities[i] = i
    end
end

const function _metaInit(dense: Dense<any>, chunksCount: number): ()
    local meta = {}
    
    _allocateChunk(meta, INDEX_CHUNK_TECH)
    _structChunkHead = chunksCount

    dense[1] = meta
end

-- Creates a single, shared world instance with entity fields, components (sparse and dense), 
-- group graph caches, type segments, and queries. Preloads custom types and meta components.
-- If called again, the function will not be executed.
-- @param count The number of entities in the world
export function world(count: number?): World
    if not _WORLD_NULL then return _WORLD_ARRAY end

    local entitySize = (count or ELEMENTS_STRUCT_CHUNK_ENTITY * 5) + ID_COMPONENT_MAX
    local chunksCount = entitySize // ELEMENTS_STRUCT_CHUNK_ENTITY

    local entities = table.create(entitySize) :: Entities
    local dense = table.create(256) :: Dense<any>
    local segment_cache = table.create(256) :: Cache
    local hooks_cache = table.create(256) :: HookSignals
    local query_cache = {} :: QueryCache
    local target_graph_cache = {} :: Cache
    local relation_graph_cache = {} :: Cache
    local group_cache = {} :: GroupCache
    local sparse = {} :: Sparse

    _allocateEntities(entities)
    _metaInit(dense, chunksCount)

    _worldComponentCache = BCREATE(256) :: buffer
    _worldEntityCache = TCREATE(entitySize * 0.1) :: { number? }
    _worldSegmentTableCache = TCREATE(30) :: { {} }

    _WORLD_ARRAY = { entities, sparse, dense, segment_cache, group_cache, relation_graph_cache, target_graph_cache, query_cache, hooks_cache }
    _WORLD_NULL = false

    return _WORLD_ARRAY
end

export function etype(): IndexId
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    return 0
end

export function entity <T> (etype: number): Entity<number>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const segments = _WORLD_ARRAY[SEGMENT_CACHE] :: Cache
    const dense = _WORLD_ARRAY[DENSE] :: Dense<unknown>

    local id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead] :: number

    local typeSegments = segments[etype] :: buffer
    local typeId = entities[etype] :: u32

    local cacheHead = EXTRACT32(typeId, BIT_NUMBER_U16)
    local id_segment = READU16(typeSegments, cacheHead)

   return id :: __ecs_create_entity<T>
end

export function component <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local id = _worldComponentCacheHead == 0 and 
        ID_TYPE_MAX + (_worldBasicComponents + 1) or READU8(_worldComponentCache, _worldComponentCacheHead - 1)

    if id > ID_COMPONENT_MAX then ecs_error(ERROR_OVERFLOW_MESSAGE) end

    local struct = _allocateChunk({}, INDEX_CHUNK_VALUE)

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    
    local denseStruct = {}
    _allocateChunk(denseStruct, INDEX_CHUNK_VALUE)
    dense[denseIndex] = denseStruct

    entities[id] = BOR(ECS_MASK_ACTIVE, BLSHIFT(1, BIT_NUMBER_U4))
    _worldBasicComponents += 1

    return id :: __ecs_create_entity<T>
end

export function multi <T> (count: number?): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local struct = _allocateChunk({}, INDEX_CHUNK_VALUE + (count or 0))
    local id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead] :: number
    
    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    
    local denseStruct = {}
    _allocateChunk(denseStruct, INDEX_CHUNK_VALUE + (count or 0))
    dense[denseIndex] = denseStruct

    entities[id] = BOR(ECS_MASK_ACTIVE, BLSHIFT(count or 0, BIT_NUMBER_U4))
    _worldEntity += 1

    return id :: __ecs_create_entity<T>
end

export function tag <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead] :: number

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    
    local denseStruct = {}
    _allocateChunk(denseStruct, INDEX_CHUNK_VALUE)
    dense[denseIndex] = denseStruct

    entities[id] = ECS_MASK_ACTIVE
    _worldEntity += 1

    return id :: __ecs_create_entity<T>
end

export function add <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U> | LowChunk
    if not ch_struct then end

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local segmentNumber = TONUMBER(segmentIndex)

    local sg_techbuffer_struct = ch_struct[INDEX_CHUNK_BITMAP] :: SegmentBuffer
    local sg_entitybuffer_struct = ch_struct[INDEX_CHUNK_ENTITY] :: SegmentBuffer

    local tech_buffer = sg_techbuffer_struct[segmentNumber] :: buffer?
    local entity_buffer = sg_entitybuffer_struct[segmentNumber] :: buffer?

    if not tech_buffer then 
        tech_buffer, entity_buffer = _allocateSegment(ch_struct, segmentNumber, #ch_struct) 
    end

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)

    local offset = 1 + TONUMBER(blockIndex) * BYTE_U64

    local mask = READINTEGER(tech_buffer :: buffer, offset)
    
    if mask == BIT_INTEGER_ZERO then
        local sg_bitmap = READINTEGER(tech_buffer :: buffer, BIT_NUMBER_ZERO)

        sg_bitmap = XOR(sg_bitmap, LSHIFT(1i, blockIndex))
        WRITEINTEGER(tech_buffer :: buffer, BIT_NUMBER_ZERO, sg_bitmap)
    end

    mask = XOR(mask, LSHIFT(1i, bitmapIndex))

    WRITEINTEGER(tech_buffer :: buffer, offset, mask)
    WRITEU32(entity_buffer :: buffer, offset, entity :: T)

    if _worldHooks == 0 then return end
end

export function remove <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U> | LowChunk

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local segmentNumber = TONUMBER(segmentIndex)

    local sg_techbuffer_struct = ch_struct[INDEX_CHUNK_BITMAP] :: SegmentBuffer
    local sg_entitybuffer_struct = ch_struct[INDEX_CHUNK_ENTITY] :: SegmentBuffer

    local tech_buffer = sg_techbuffer_struct[segmentNumber] :: buffer
    local entity_buffer = sg_entitybuffer_struct[segmentNumber] :: buffer

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)

    local offset = 1 + TONUMBER(blockIndex) * BYTE_U64

    local mask = READINTEGER(tech_buffer :: buffer, offset)
    mask = XOR(mask, LSHIFT(1i, bitmapIndex))

    if mask == BIT_INTEGER_ZERO then
        local sg_bitmap = READINTEGER(tech_buffer, BIT_NUMBER_ZERO)

        sg_bitmap = XOR(sg_bitmap, LSHIFT(1i, blockIndex))
        WRITEINTEGER(tech_buffer, BIT_NUMBER_ZERO, sg_bitmap)
    end

    WRITEINTEGER(tech_buffer :: buffer, offset, mask)
    WRITEU32(entity_buffer, offset, BIT_NUMBER_ZERO)

    if _worldHooks == 0 then return end
end

export function get <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): U?
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U>

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local sg_value_struct = ch_struct[INDEX_CHUNK_VALUE] :: SegmentValue<U>

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)
    local index = 64 * TONUMBER(blockIndex) + TONUMBER(bitmapIndex)

    local tbl_struct = sg_value_struct[TONUMBER(segmentIndex)]
    return tbl_struct[index + 1]
end

export function set <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>, value: U): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U>

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local sg_value_struct = ch_struct[INDEX_CHUNK_VALUE] :: SegmentValue<U>

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)
    local index = 64 * TONUMBER(blockIndex) + TONUMBER(bitmapIndex)

    local tbl_struct = sg_value_struct[TONUMBER(segmentIndex)]
    tbl_struct[index + 1] = value

    if _worldHooks == 0 then return end
end

export function has <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U>? | LowChunk?
    if not ch_struct then return false end

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local sg_techbuffer_struct = ch_struct[INDEX_CHUNK_BITMAP] :: SegmentBuffer

    local bf_struct = sg_techbuffer_struct[TONUMBER(segmentIndex)] :: buffer?
    if not bf_struct then return false end

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)

    local offset = 1 + TONUMBER(blockIndex) * BYTE_U64
    local mask = READINTEGER(bf_struct :: buffer, offset)

    return EXTRACT64(mask, bitmapIndex) ~= BIT_INTEGER_ZERO
end

export function exist <T, U> (entity: Entity<T> | Group<Entity<T>, Entity<U>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64 | u52 | u32
    return entityId ~= BIT_NUMBER_ZERO
end

export function hook <T> (entity: Entity<T>, hook: number, callback: Callback): ()
    const hookSignals = _WORLD_ARRAY[HOOK_CACHE]
    const sparse = _WORLD_ARRAY[SPARSE]

    local densePointer = sparse[entity] :: u32
    if not densePointer then ecs_error(ERROR_COMPONENT_BEHAIVOR) end

    if hook == Add then end
    if hook == Remove then return end
    if hook == Changed then return end
end

export function clear <T> (entity: Entity<T>): ()
    
end

export function destroy <T> (entity: Entity<T>): ()
    
end

export function query <A, B, C, D, E> (...: Entity<A | B | C | D | E>): Query<>
    local a,b,c,d,e = ... :: __ecs_is_entity<typeof(...)>
end

export function forEach(query: Query<T>): ()
    
end

export function group <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const relation_cache = _WORLD_ARRAY[RELATION_GRAPH_CACHE] :: Cache
    const target_cache = _WORLD_ARRAY[TARGET_GRAPH_CACHE] :: Cache
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<Entity<T>, Entity<U>> end

    id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead] :: number
    
    groups[uint_48] = id
    entities[id] = uint_48
    _worldEntity += 1

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    
    local denseStruct = {}
    _allocateChunk(denseStruct, INDEX_CHUNK_VALUE)
    dense[denseIndex] = denseStruct

    return id :: Group<Entity<T>, Entity<U>>
end

const function disable(entity: Entity<number>): ()
    
end

const function fastGroup <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const relation_cache = _WORLD_ARRAY[RELATION_GRAPH_CACHE] :: Cache
    const target_cache = _WORLD_ARRAY[TARGET_GRAPH_CACHE] :: Cache
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<Entity<T>, Entity<U>> end
    
    id = _worldEntityCacheHead == 0 and 
         ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead] :: number
    
    groups[uint_48] = id
    entities[id] = uint_48
    _worldEntity += 1

    return id :: Group<Entity<T>, Entity<U>>
end

const function target <T, U> (entity: Entity<T>, relation: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

const function relation <T, U> (entity: Entity<T>, target: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

const function first <T, U> (group: Group<Entity<T>, Entity<U>>): Entity<T>
    return 0 :: __ecs_create_entity<T>
end

const function second <T, U> (group: Group<Entity<T>, Entity<U>>): Entity<any>
    return 0 :: __ecs_create_entity<U>
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