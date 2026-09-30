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
type ChunkBuffer = { buffer? }
type ChunkValue <U> = { { U }? }
type ChunkHooks <U> = number | { Callback <U>? }
type Struct <U> = { buffer | ChunkHooks <U> | ChunkBuffer | ChunkValue<U>? }

-- Types for special caches
type QueryCache = {[IndexId]: {}}
type GroupCache = {[u52]: IndexId}

-- Basic types of world tables ]|
type Entities = { [IndexId]: u64 | u52 | u32 }
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

-- MATH std::library methods localization 
local MIN = math.min

-- TABLE std::library methods localization ]|
local TCREATE = table.create
local MOVE = table.move
local CLEAR = table.clear

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
local _headEmptySegments = 0
local _headEmptyChunks = 0

-- Packed objects
local _worldPacked = {} :: Pack

-- World variables ]|
local _WORLD_ARRAY: World
local _WORLD_NULL = true

const function ecs_error(errorMessage: string): never
    error(`[RECS]: {errorMessage}`)
end

const function _segmentAllocation <U> (cmp_struct: Struct<U>, position: number, size: number): ()
    local buffer_entity_struct = cmp_struct[INDEX_CHUNK_ENTITY] :: ChunkBuffer
    buffer_entity_struct[position] = BCREATE(BYTE_U32 * ELEMENTS_STRUCT_CHUNK_SOA)

    if size == INDEX_CHUNK_ENTITY then return end

    local table_value_struct = cmp_struct[INDEX_CHUNK_VALUE] :: ChunkValue <U>
    table_value_struct[position] = TCREATE(ELEMENTS_STRUCT_CHUNK_SOA)
end

const function _chunkAllocation <U> (cmp_struct: Struct<U>, size: number, chunkSize: number): ()

end

const function _entitiesAllocation(): ()
    
end

const function _metaAllocation(): ()
    
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
    local dense = TCREATE(256) :: Dense<any>
    local segment_cache = TCREATE(256) :: Cache

    local query_cache = {} :: QueryCache
    local target_graph_cache = {} :: Cache
    local relation_graph_cache = {} :: Cache
    local group_cache = {} :: GroupCache
    local sparse = {} :: Sparse

    _entitiesAllocation(entities)
    _metaAllocation(dense, chunksCount)

    _cacheIdComponents = BCREATE(256) :: buffer
    _cacheIdEntities = TCREATE(entitySize * 0.1) :: { number? }
    _cacheTableSegments = TCREATE(30) :: { {}? }
    _cacheStructChunk = TCREATE(30) :: { Chunk<unknown>? }

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
    local id = cachePush and 1 + ID_COMPONENT_MAX + _worldEntity or _cacheIdEntities[_headIdEntities] :: number
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

    local cachePush = _headIdComponents == BIT_NUMBER_ZERO
    local id = cachePush and 1 + ID_TYPE_MAX + _componentIdHead or READU8(_cacheIdComponents, _headIdComponents - 1)
    _headIdComponents = cachePush and 0 or _headIdComponents - 1

    if id > ID_COMPONENT_MAX then ecs_error(ERROR_OVERFLOW_MESSAGE) end

    _worldDense += 1
    sparse[id] = _worldDense
    
    local denseStruct = {}
    _chunkAllocation(denseStruct, INDEX_CHUNK_VALUE)
    dense[_worldDense] = denseStruct

    entities[id] = OR(1i)

    return id :: __ecs_create_entity<T>
end

export function multi <T> (count: number?): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local cachePush = _headIdEntities == BIT_NUMBER_ZERO
    local id = cachePush and 1 + ID_COMPONENT_MAX + _worldEntity or _cacheIdEntities[_headIdEntities] :: number
    _headIdEntities = cachePush and 0 or _headIdEntities - 1
    
    _worldDense += 1
    sparse[id] = _worldDense
    
    local denseStruct = {}
    _chunkAllocation(denseStruct, INDEX_CHUNK_VALUE + (count or 0))
    dense[_worldDense] = denseStruct

    entities[id] = ICREATE(count or 0)
    _worldEntity += 1

    return id :: __ecs_create_entity<T>
end

export function tag <T> (): Entity<T>
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local cachePush = _headIdEntities == BIT_NUMBER_ZERO
    local id = cachePush and 1 + ID_COMPONENT_MAX + _worldEntity or _cacheIdEntities[_headIdEntities] :: number
    _headIdEntities = cachePush and 0 or _headIdEntities - 1

    _worldDense += 1
    sparse[id] = _worldDense
    
    local denseStruct = {}
    _chunkAllocation(denseStruct, INDEX_CHUNK_ENTITY)
    dense[_worldDense] = denseStruct

    entities[id] = OR(1i)
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


    -- query cache invalid
end

export function remove <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

    -- query cache invalid
end

export function get <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): U?
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

end

export function set <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>, value: U): ()
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

end

export function has <T, U, V> (entity: Entity<T>, component: Entity<U> | Group<Entity<U>, Entity<V>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<U>

    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64
    local componentId = sparse[component :: __ecs_is_entity<typeof(component)>] :: u32

    local cmp_struct = dense[componentId] :: Struct<U>

end

export function exist <T, U> (entity: Entity<T> | Group<Entity<T>, Entity<U>>): boolean
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local entityId = entities[entity :: __ecs_is_entity<typeof(entity)>] :: u64 | u52 | u32
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

export function group <T, U> (relation: Entity<T>, target: Entity<U>): Group<Entity<T>, Entity<U>>
    local groups = _WORLD_ARRAY[GROUP_CACHE] :: GroupCache
    const entities = _WORLD_ARRAY[ENTITIES] :: Entities
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

    local id = groups[uint_48]
    if id then return id :: Group<Entity<T>, Entity<U>> end

    id = _headIdEntities == 0 and 
        ID_COMPONENT_MAX + (_worldEntity + 1) or _cacheIdEntities[_headIdEntities] :: number
    
    groups[uint_48] = id
    entities[id] = uint_48
    _worldEntity += 1

    const relation_cache = _WORLD_ARRAY[RELATION_GRAPH_CACHE] :: Cache
    const target_cache = _WORLD_ARRAY[TARGET_GRAPH_CACHE] :: Cache

    const sparse = _WORLD_ARRAY[SPARSE] :: Sparse
    const dense = _WORLD_ARRAY[DENSE] :: Dense<T>

    local denseIndex = _worldDense + 1
    _worldDense += 1
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
    
    local irelation: u64 = ICREATE(relation :: __ecs_is_entity<typeof(relation)>)
    local itarget: u64 = ICREATE(target :: __ecs_is_entity<typeof(target)>)

    local uint_48: u52 = OR(irelation, itarget) -- 0bu52

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