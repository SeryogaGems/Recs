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
type HookSignals = {[IndexId]: {
    (entity: Entity<number>, component: Entity<unknown>, ...unknown) -> (any)
}}

-- Basic types of world tables ]|
type Entities = {[IndexId]: u64 | u52 | u32}
type Sparse = {[IndexId]: u32}
type Dense <U> = {[u32]: Struct <U>}
type Cache = {[IndexId]: buffer?}
type Pack = {[string]: IndexId}

-- |[]|
type Entity<T> = { read __T: T }
type Group<Relation, Target> = __ecs_group<Relation, Target>

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
const BYTE_U32 = 0x4 -- 4 bytes
const BYTE_U16 = 0x2 -- 2 bytes

-- |[]|
const BUFFER_BLOCK_OFFSET = 0
const BUFFER_META_TYPE_OFFSET = 6

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

-- Entity and component cache
local _worldEntityCache = TCREATE(256) :: {number}
local _worldComponentCache = BCREATE(256)

-- Entity and component cache size (var)
local _worldEntityCacheHead = 0
local _worldComponentCacheHead = 0

-- Packed objects
local _worldPacked = {} :: Pack

-- World variables ]|
local _WORLD_ARRAY: World
local _WORLD_NULL = true

const function ecs_error(errorMessage: string): never
    error(`[RECS]: {errorMessage}`)
end

const function chunkInit <U> (componentStruct: Struct<U>, componentChunkHead: number, size: number): Struct<U>
    return componentStruct
end

const function metaInit(): {LowChunk}
    
end

-- Creates a single, shared world instance with entity fields, components (sparse and dense), 
-- group graph caches, type segments, and queries. Preloads custom types and meta components.
-- If called again, the function will not be executed.
-- @param count The number of entities in the world ]|
export function world(count: number?): World
    _WORLD_ARRAY = {}
end

export function etype(): IndexId
    return 0
end

export function entity <T> (etypeId: number): Entity<number>
   return 0 :: __ecs_create_entity<T>
end

export function component <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local id = _worldComponentCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) + 1 or READU8(_worldComponentCache, _worldComponentCacheHead - 1)

    if id > ID_COMPONENT_MAX then ecs_error(ERROR_OVERFLOW_MESSAGE) end

    local struct = chunkInit({}, 0, INDEX_CHUNK_VALUE)

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    dense[denseIndex] = chunkInit({}, 0, INDEX_CHUNK_TECH)

    entities[id] = BOR(ECS_MASK_ACTIVE, BLSHIFT(1, BIT_NUMBER_U4))

    return id :: __ecs_create_entity<T>
end

export function multi <T> (count: number?): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local struct = chunkInit({}, 0, INDEX_CHUNK_VALUE + (count or 0))
    local id = _worldEntityCacheHead == 0 and 
        _worldEntity + 1 or _worldEntityCache[_worldEntityCacheHead]
    
    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    dense[denseIndex] = chunkInit({}, 0, INDEX_CHUNK_TECH)

    entities[id] = BOR(ECS_MASK_ACTIVE, BLSHIFT(count or 0, BIT_NUMBER_U4))

    return id :: __ecs_create_entity<T>
end

export function tag <T> (): Entity<boolean>
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local struct = chunkInit({}, 0, INDEX_CHUNK_TECH)
    local id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead]

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    dense[denseIndex] = chunkInit({}, 0, INDEX_CHUNK_TECH)

    entities[id] = ECS_MASK_ACTIVE

    return id :: __ecs_create_entity<T>
end

export function add <T, U> (entity: Entity<T>, component: Entity<U>): ()
   
end

export function remove <T, U> (entity: Entity<T>, component: Entity<U>): ()
    
end

export function get <T, U> (entity: Entity<T>, component: Entity<U>): U?
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local entityId = entities[entity] :: u64
    local componentId = sparse[component] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U>

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local sg_value_struct = ch_struct[INDEX_CHUNK_VALUE] :: SegmentValue<U>

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)
    local index = 64 * TONUMBER(blockIndex) + TONUMBER(bitmapIndex)

    local tbl_struct = sg_value_struct[TONUMBER(segmentIndex)]
    return tbl_struct[index]
end

export function set <T, U> (entity: Entity<T>, component: Entity<U>, value: U): ()
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]

    local entityId = entities[entity] :: u64
    local componentId = sparse[component] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    local chunkIndex = EXTRACT64(entityId, BIT_INTEGER_ZERO, BIT_INTEGER_U16)
    local ch_struct = cmp_struct[TONUMBER(chunkIndex)] :: Chunk<U>

    local segmentIndex = EXTRACT64(entityId, BIT_INTEGER_U16, BIT_INTEGER_U4)
    local sg_value_struct = ch_struct[INDEX_CHUNK_VALUE] :: SegmentValue<U>

    local blockIndex = EXTRACT64(entityId, BIT_INTEGER_U20, BIT_INTEGER_U4)
    local bitmapIndex = EXTRACT64(entityId, BIT_INTEGER_U24, BIT_INTEGER_U4)
    local index = 64 * TONUMBER(blockIndex) + TONUMBER(bitmapIndex)

    local tbl_struct = sg_value_struct[TONUMBER(segmentIndex)]
    tbl_struct[index] = value
end

export function has <T, U> (entity: Entity<T> | Group<Entity<T>, Entity<U>>): boolean
    return true
end

export function clean <T> (entity: Entity<T>): ()
    
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
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<typeof(relation), typeof(target)> end

    local struct = chunkInit({}, 0, INDEX_CHUNK_VALUE)
    id = _worldEntityCacheHead == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead]

    local denseIndex = #dense + 1
    sparse[id] = denseIndex
    dense[denseIndex] = chunkInit({}, 0, INDEX_CHUNK_TECH)
    
    local ecs_hook = ICREATE(ECS_MASK_ACTIVE) -- 0b0001
    local uint_52 = LSHIFT(uint_48, 4i) -- 0b0000_u52
    local mask = OR(ecs_hook, uint_52) -- 0b0001_u52

    entities[id] = mask
    groups[uint_48] = id

    return id :: Group<Entity<T>, Entity<U>>
end

const function fast_group <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES]
    const sparse = _WORLD_ARRAY[SPARSE]
    const dense = _WORLD_ARRAY[DENSE]
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<typeof(relation), typeof(target)> end
    
    id = _worldEntityCacheHead == 0 and 
         ID_COMPONENT_MAX + (_worldEntity + 1) or _worldEntityCache[_worldEntityCacheHead]

    local ecs_hook = ICREATE(ECS_MASK_ACTIVE) -- 0b0001
    local uint_52 = LSHIFT(uint_48, 4i) -- 0b0000_u52
    local mask = OR(ecs_hook, uint_52) -- 0b0001_u52

    entities[id] = mask
    groups[uint_48] = id

    return id :: Group<Entity<T>, Entity<U>>
end

const function target <T,U> (entity: Entity<T>, relation: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

const function relation <T,U> (entity: Entity<T>, target: Entity<U>): Entity<any>
    return 0 :: __ecs_create_entity<T>
end

export const Relations = {
    fast_group = fast_group,
    target = target,
    relation = relation
}