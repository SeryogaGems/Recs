--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

-- Entity id type |[]|
type IndexId = number

-- Entity mask bit-sizes: |[
-- Group(u52) / Entity(u32)
-- Type(u16) / Multi-Component(u12)
-- Component(u8) / Tag(u4) ]|
type u52 = number
type u32 = number
type u16 = number
type u12 = number
type u8 = number
type u4 = number

-- Type functions |[]|
type function ecs_group_type(relation: type, target: type)
    local __Entity = types.singleton("__Entity")
    local __Group = types.singleton("__Group")
    
    local is_group_type = types.singleton(true)

    local relation_type = relation:readproperty(__Entity)
    local target_type = target:readproperty(__Entity)

    assert(relation_type and target_type, "")

    local group_type = types.newtable()

    group_type:setreadproperty(__Entity, relation_type or target_type)
    group_type:setreadproperty(__Group, is_group_type)

    return group_type
end

-- |[]|
type Query <A, B, C, D, E> = {}

-- Exported types |[]|
export type Id<T> = T
export type World = {}

-- Localizing functions for reuse |[
-- Disabling the GETIMPORT compiler instruction
-- BIT32 std::library methods localization
local XOR = bit32.bxor
local AND = bit32.band
local NOT = bit32.bnot
local COUNTRZ = bit32.countlz
local LSHIFT = bit32.lshift
local EXTRACT = bit32.extract

-- BUFFER std::library methods localization
local BCREATE = buffer.create
local WRITEU16 = buffer.writeu16
local READU16 = buffer.readu16
local WRITEU32 = buffer.writeu32
local READU32 = buffer.readu32

-- TABLE std::library methods localization ]|
local TCREATE = table.create
local UNPACK = table.unpack

-- Fields and width of bitwise take operations |[
-- Fields maskes
const FIELD_ENTITY_SEGMENT = 0x10 -- 16 bits
const FIELD_ENTITY_BLOCKS = 0x14 -- 20 bits
const FIELD_ENTITY_BLOCK = 0x18 -- 24 bits

const FIELD_MULTI_COUNT = 0x8 -- 8 bits

-- Width maskes
-- Width for component structure objects
const WIDTH_ENTITY_CHUNK = 0x10000 -- 16[0b1] % bits
const WIDTH_ENTITY_SEGMENT = 0x4 -- 4 bits
const WIDTH_ENTITY_BLOCK = 0x4 -- 4 bits
const WIDTH_ENTITY_BITMAP = 0x8 -- 8 bits

-- Width for masks of some caches
const WIDTH_CACHETYPE_SIZE = 0x8 -- 8 bits

-- Width for component structure masks ]|
const WIDTH_STRUCT_HOOK = 0x10 -- 4[0b1] % bits
const WIDTH_MULTI_COUNT = 0x4 -- 4 bits

-- Maximum size limits in numbers |[
-- Filling of component structures
const MAXSIZE_STRUCT_CHUNK = 0xFFFF -- 16[0b1] bits
const MAXSIZE_STRUCT_SEGMENT = 0xFF -- 8[0b1] bits
const MAXSIZE_STRUCT_BLOCK = 0xFFFFFFFF -- 32[0b1] bits

-- Filling masks of some entities ]|
const MAXSIZE_ENTITY = 0xFFFFFFFF -- 32[0b1] bits
const MAXSIZE_TAG = 0xF -- 4[0b1] bits

-- Dimensions of the basic structures of the world |[
-- Maximum and initial values ​​for component structures
const ELEMENTS_STRUCT_CHUNK = 0x11 -- 17
const ELEMENTS_STRUCT_SEGMENT_TABLE = 0x100 -- 256
const ELEMENTS_STRUCT_SEGMENT_ENTITIES = 0x100 -- 256
const ELEMENTS_STRUCT_SEGMENT_META = 0x8 -- 8

-- Maximum and initial values ​​for meta
const ELEMENTS_META = 0x1 -- 1
const ELEMENTS_META_SEGMENT_META = 0x9 -- 9

-- Maximum initial values ​​for caches ]|
const ELEMENTS_CACHETYPE_SEGMENTS = 0x20 -- 32
const ELEMENTS_CACHEGRAPH_RELATION = 0x10 -- 16
const ELEMENTS_CACHEGRAPH_TARGET = 0x20 -- 32
const ELEMENTS_CACHEENTITY_ENTITY = 0x100 -- 256

-- Byte representation of bit types |[]|
const BYTE_U32 = 0x4 -- 4 bytes
const BYTE_U16 = 0x2 -- 2 bytes

-- ID indexes with offsets from the beginning of the entity table |[]|
const ID_ZERO = 0
const ID_SPECIAL_MAX = 11
const ID_TYPE_MAX = 256
const ID_COMPONENT_MAX = 512

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
local _structChunkHead = ID_ZERO + 1
local _structChunkTail = ID_ZERO + 1

-- Maximum position of components in the world
local _componentIdHead = ID_TYPE_MAX + 1

-- Maximum position of entities in the world
local _entityIdHead = ID_COMPONENT_MAX + 1

-- Counters for the number of entities, types, and base components ]|
local _worldEntity = 0
local _worldTypes = 0
local _worldBasicComponents = 0
local _worldCacheEntity = 0

local function ecs_error(systemCode: number): never
    error(`[RECS]: {ERROR_OVERFLOW_MESSAGE}`)
end


export function world() end