--!strict
--!optimize 2
--!native
--!nolint LocalUnused
--!nolint MultiLineStatement
--!nolint FunctionUnused

type Id = number

type u52 = number
type u32 = number
type u14 = number
type u12 = number
type u4 = number

type Entities = {[Id]: u52 | u32 | u14 | u12 | u4}
type Sparse = {[Id]: number}
type Dense = {[number]: ComponentStruct}
type Cache = {[Id]: buffer?}
type QueryCache = {[number]: {}?}

type Entity = {read _E: Id}
type Multi = {read _C: Id}
type Group<Relationship, Target> = {read _R: Relationship, read _T: Target}
type Special = Id
type EType = {read _T: Id}

type ComponentStruct = {{Chunk? | LowChunk?}}
type Chunk = {number | {any}}
type LowChunk = {number | buffer}

type World = {
	read entities: Entities,
	read sparse_components: Sparse,
	read dense_components: Dense,
	read graph_relationships_cache: Cache,
	read graph_target_cache: Cache,
	read segments_cache: Cache,
	read query_cache: QueryCache,
}

--Localizing functions for reuse. 
--Disabling the GETIMPORT compiler instruction.
local AND = bit32.band
local NOT = bit32.bnot
local XOR = bit32.bxor
local COUNTRZ = bit32.countrz
local EXTRACT = bit32.extract
local LSHIFT = bit32.lshift
local READU32 = buffer.readu32
local WRITEU32 = buffer.writeu32
local READU16 = buffer.readu16
local WRITEU16 = buffer.writeu16
local BCREATE = buffer.create
local TCREATE = table.create

--Hook and chunk masks fills
const ECS_FILL_CHUNK_MASK = 0xFFFF
const ECS_FILL_SEGMENT_MASK = 0xFF
const ECS_FILL_BLOCK_MASK = 0xFFFF_FFFF
const ECS_ADD_MASK = 0b0001
const ECS_REMOVE_MASK = 0b0010
const ECS_CHANGED_MASK = 0b0100
const ECS_ISLIFE_MASK = 0b1000

--Mask sizes in bits
const SEGMENT_ENTITY_WIDTH = 0x4
const CHUNK_ENTITY_FIELD = 0x10
const CHUNK_SIZE = 2^16
const SEGMENT_SIZE = 2^8
const BLOCK_SIZE = 2^32

--Decimal representation of entity IDs for mathematical comparisons
const ENTITY_DEC = 0x1110001
const GROUP_DEC = 0x300000200001
const MILTI_DEC = 0x3018
const COMPONENT_DEC = 0x24
const TAG_DEC = 0x8

--Constants for initial values ​​of tables and buffers
const WORLD_ELEMENTS = 0x6
const STRUCT_ELEMENTS = 0x5
const COMPONENT_ELEMENTS = 0x100
const CHUNK_ELEMENTS = 0x11
const CHUNK_ENTITY_ELEMENTS = 0x1000
const SEGMENT_ELEMENTS = 0x24
const BLOCK_ELEMENTS = 0x20

const CACHE_BUFFER_ELEMENTS = 0x10
const CACHE_TABLE_ELEMENTS = 0x10
const CACHE_GRAPH_ELENENTS = 0x100
const CACHE_QUERY_ELEMENTS = 0x10

const CACHE_TYPE_FIELD = 0x8
const CACHE_TYPE_WIDTH = 0x16
const CACHE_TYPE_VALUE = 0x10

--ID offsets in the entity table.
const META = 0x1
const ZERO_TYPE = 0x0
const SPECIAL_TYPE = 0xB
const END_TYPE_ID = ZERO_TYPE + 0x100
const SYSTEM_END = END_TYPE_ID + 0x100

--Special entity types for hooks and replacing library objects in queries
const EcsWildcard = ZERO_TYPE + 1
const EcsComponent = ZERO_TYPE + 2
const EcsType = ZERO_TYPE + 3
const EcsAdd = ZERO_TYPE + 4
const EcsRemove = ZERO_TYPE + 5
const EcsChanged = ZERO_TYPE + 6
const EcsChildOf = ZERO_TYPE + 7
const EcsAll = ZERO_TYPE + 8

const ERROR_TYPE_LIMIT = [[
	RECS <TYPE> <LIMIT> ERROR:
		The number of created entity types has reached the allowed limit of 245 elements.
		Redefine entities to existing types during creation or use migration.
]]

const ERROR_COMPONENT_LIMIT = [[
	RECS <COMPONENT> <LIMIT> ERROR:
		The number of components has reached the 256 elements limit.
		Use multi-components to group multiple entity values.
]]

--Variables of different access to the world
local WORLD_ARRAY: World
local WORLD_IS_NULL = true

--Mutable variables controlling the state of the world
local worldMaxChunk: number = 0
local worldComponents: number = 0
local worldTypes: number = 0
local worldEntities: number = 0

local worldEntitesHead: number = 0
local worldEntitiesTail: number = 0

local worldComponentHead: number = 0
local worldComponentTail: number = 0

local worldMetaTail: number = 0

local function ecs_error(error_text: string): never
	error(error_text)
end

-- Creating multiple chunks simultaneously.
-- Increases the hypothetical locality of tables in memory.
-- @param struct Component structure (component, tag, multi-component, group)
-- @param startIndex The last chunk inside the component structure
-- @param count Number of chunks to add
local function struct_create_chunk(struct: ComponentStruct, startIndex: number, count: number): ComponentStruct
	--Checks the maximum chunk index. 
	--If more chunks are created than exist in the world, the value will change. 
	--This variable is used to minimize # operator calls when using the component() functions.
	local maxChunkIndex = startIndex + count
	worldMaxChunk = worldMaxChunk < maxChunkIndex and maxChunkIndex or worldMaxChunk

	for i=1, count do
		--Creates a chunk with 17 elements: 1 presence mask and 16 data segments. 
		--A total of 272 bytes.
		local chunk = TCREATE(CHUNK_ELEMENTS) :: LowChunk | Chunk
		chunk[1] = 0x0

		--Adds a new chunk to the component structure at an offset from the starting index.
		struct[startIndex + i] = chunk
	end

	return struct
end

--Functions for working with basic world objects
-- Filling the world with special components
-- @param entities Entity table
local function world_special_entities(entities: Entities): Entities
	for i=1, SPECIAL_TYPE do
		entities[i] = i
	end

	worldTypes += SPECIAL_TYPE

	return entities :: Entities
end

-- Create a meta component during world initialization. 
-- The function will load chunks based on the specified components in the world, adding one chunk.
-- @param dense Dense array of components
-- @param entitiesCount Number of expected entities in the world
local function world_meta_component(dense: Dense, entitiesCount: number): Dense
	local chunkCount = (entitiesCount // 4096) + 1

	local meta = TCREATE(chunkCount) :: ComponentStruct
	dense[1] = struct_create_chunk(meta, 0, chunkCount)

	-- Increases the initial value of the tail chunk
	-- Additional: function type_create_segment()
	worldMetaTail += 1

	return dense :: Dense
end

-- Create a new segment with initial data in the chunk.
-- @param id Entity type IDs
local function type_create_segment(id: Id)
	local dense: Dense = WORLD_ARRAY.dense_components
	local meta: ComponentStruct = dense[1]

	local chunk = meta[worldMetaTail] :: LowChunk
	local chunkMask = chunk[1] :: number

	-- If a block is full, its tail will move forward by one.
	-- The tail chunk is needed so that when chunks are initialized prematurely, 
	-- meta are not written to the very end chunk.
	-- When the top and tail blocks are equal, the condition below will be triggered.
	if chunkMask == ECS_FILL_CHUNK_MASK then
		-- If there are no empty chunks, an additional 1 empty one is created.
		if worldMetaTail == worldMaxChunk then
			meta = struct_create_chunk(meta, worldMaxChunk, 1)
		end

		worldMetaTail += 1

		chunk = meta[worldMetaTail] :: LowChunk
		chunkMask = chunk[1]  :: number
	end

	-- Finding a free segment. The mask is flipped bitwise. 
	-- All filled entities will become zeros. 
	-- The counter function will find the first inverted one. 
	-- If the function returns more zeros than 16, 0 is automatically returned.
	local inverse = NOT(chunkMask)
	local zeroBits = COUNTRZ(inverse)
	local freeSlot = zeroBits < 16 and zeroBits or 0

	-- Sets a bit of a specific segment to the on state.
	local xored_bit = LSHIFT(0x1, freeSlot)
	chunk[1] = XOR(chunkMask, xored_bit)

	-- Segment information record. Shift by 2 due to 1 index being filled with a number.
	-- This contains the segment mask, 8 block masks, and a pointer to the type.
	-- Numbers are represented in 32-bit unsigned format. Total: 40 bytes.
	local segmentBuffer = BCREATE(SEGMENT_ELEMENTS + 4)
	local segmentIndex = freeSlot + 2
	chunk[segmentIndex] = segmentBuffer

	-- 0x0 - segment mask // 0x4 to 0x20 - block masks // 0x24 - type pointer
	WRITEU32(segmentBuffer, 0x0, 0)
	WRITEU32(segmentBuffer, 0x24, id)

	for i=1, 7 do
		WRITEU32(segmentBuffer, i * 0x4, 0)
	end

	-- Calculating the total value of a segment in the world's memory. 
	-- The formula is: (chunk number - 1) * 16 [the number of segments in 1 chunk] + segment bit number.
	local cacheSegmentIndex = (worldMetaTail - 1) * 16 + freeSlot
	return cacheSegmentIndex
end

local function type_segment_cache(typeId: Id, cacheSegmentId: number, delete: boolean?): ()
	local segmentCache: Cache = WORLD_ARRAY.segments_cache
	local entities: Entities = WORLD_ARRAY.entities

	local typeCacheBuffer = segmentCache[typeId] :: buffer
	local typeMask = entities[typeId] :: u14
	local typeCacheLastIndex = EXTRACT(typeMask, CACHE_TYPE_FIELD, CACHE_TYPE_WIDTH)

	if not delete then
		local newIndex = typeCacheLastIndex + 1
		WRITEU16(typeCacheBuffer, newIndex, cacheSegmentId)
	end

	local newIndex = typeCacheLastIndex + 1
	WRITEU16(typeCacheBuffer, newIndex, cacheSegmentId)

	entities[typeId] = typeCacheLastIndex + CACHE_TYPE_VALUE
end

-- Calculates the logical type of an entity. 
-- The function accesses the segment within the metacomponent and reads parameter 9 of the mask buffer. 
-- Returns a number in the range 11 - 256.
-- @param entity 32-bit entity mask
local function entity_get_type(entity: u32): Id
	local chunkIndex = entity % CHUNK_SIZE
	local segmentIndex = EXTRACT(entity, CHUNK_ENTITY_FIELD, SEGMENT_ENTITY_WIDTH)

	local dense: Dense = WORLD_ARRAY.dense_components
	local meta: ComponentStruct = dense[1]

	-- Shift by 2 due to 1 index being filled with a number
	local chunk = meta[chunkIndex] :: LowChunk 
	local segmentBuffer = chunk[segmentIndex + 2] :: buffer

	return READU32(segmentBuffer, 0x24)
end

-- Creates a single, shared world instance with entity fields, components (sparse and dense), 
-- group graph caches, type segments, and queries. Preloads custom types and meta components.
-- If called again, the function will not be executed.
-- @param count The number of entities in the world
local function world(count: number?): World
	--Preventing repeated world creation. 
	--This is necessary to prevent accidentally overwriting the entire library memory.
	if not WORLD_IS_NULL then return WORLD_ARRAY end
	WORLD_IS_NULL = false

	local const_entity_id = ZERO_TYPE + END_TYPE_ID * 2
	local entity_id_max = count or CHUNK_ENTITY_ELEMENTS * 4

	local entities = TCREATE(entity_id_max + const_entity_id) :: Entities
	local dense_components = TCREATE(COMPONENT_ELEMENTS) :: Dense
	local sparse_components = TCREATE(COMPONENT_ELEMENTS) :: Sparse
	local graph_relationships_cache = TCREATE(CACHE_GRAPH_ELENENTS) :: Cache
	local graph_target_cache = TCREATE(CACHE_GRAPH_ELENENTS) :: Cache
	local query_cache = TCREATE(CACHE_QUERY_ELEMENTS) :: QueryCache
	local segments_cache = TCREATE(END_TYPE_ID) :: Cache

	--Populating these tables requires pre-initialization with special entity types and a meta-component.

	WORLD_ARRAY = table.freeze({
		entities = world_special_entities(entities),
		dense_components = world_meta_component(dense_components, entity_id_max),

		sparse_components = sparse_components,
		graph_relationships_cache = graph_relationships_cache,
		graph_target_cache = graph_target_cache,
		segments_cache = segments_cache,
		query_cache = query_cache
	})

	return WORLD_ARRAY
end

local function etype(): Id
	if worldTypes == END_TYPE_ID then ecs_error(ERROR_TYPE_LIMIT) end
	worldTypes += 1

	local entities = WORLD_ARRAY.entities
	local segmentCache = WORLD_ARRAY.segments_cache

	entities[worldTypes] = worldTypes :: u14
	segmentCache[worldTypes] = BCREATE(CACHE_BUFFER_ELEMENTS)

	local segmentCacheId = type_create_segment(worldTypes)
	type_segment_cache(worldTypes, segmentCacheId)

	return worldTypes
end

local function component(): Entity
	if worldComponents == END_TYPE_ID then ecs_error(ERROR_COMPONENT_LIMIT) end
	worldComponents += 1

	local struct = TCREATE(worldMaxChunk) :: ComponentStruct
	local componentStruct = struct_create_chunk(struct, 0, worldMaxChunk)

	local dense = WORLD_ARRAY.dense_components
	local sparse = WORLD_ARRAY.sparse_components
	local denseLastIndex = #dense + 1

	dense[denseLastIndex] = componentStruct
	sparse[worldComponents] = denseLastIndex
end

return table.freeze({
	world = world,
	etype = etype,
	-- entity = ,
	-- component = 
	-- destroy

	Wildcard = EcsWildcard,
	ChildOf = EcsChildOf,
	Component = EcsComponent,
	Type = EcsType,
	Add = EcsAdd,
	Remove = EcsRemove,
	Changed = EcsChanged,
})
