--- A 2 component bounding box.
-- @module bound2

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec2    = require(modules .. "vec2")

local bound2    = {}
local bound2_mt = {}

-- Private constructor.
---@param min vec2
---@param max vec2
---@return bound2
local function new(min, max)
	return setmetatable({
		min=min, -- min: vec2, minimum value for each component 
		max=max, -- max: vec2, maximum value for each component 
	}, bound2_mt)
end

-- Do the check to see if JIT is enabled. If so use the optimized FFI structs.
local status, ffi
if type(jit) == "table" and jit.status() then
	status, ffi = pcall(require, "ffi")
	if status then
		ffi.cdef "typedef struct { cpml_vec2 min, max; } cpml_bound2;"
		local constructor = ffi.typeof("cpml_bound2")
        ---@diagnostic disable-next-line: cast-type-mismatch
        ---@cast constructor function(min:vec2, max:vec2):bound2
        new = constructor
	end
end

--- Constants
---@class bound2
---@field min vec2
---@field max vec2
---@field zero bound2 Empty vector
bound2.zero = new(vec2.zero, vec2.zero)

--- The public constructor.
-- @param min Can be of two types: </br>
-- vec2 min, minimum value for each component
-- nil Create bound at single point 0,0
-- @param vec2 max, maximum value for each component
-- @return bound2 out
function bound2.new(min, max)
	if min and max then
		return new(min:clone(), max:clone())
	elseif min or max then
		error("Unexpected nil argument to bound2.new")
	else
		return new(vec2.zero, vec2.zero)
	end
end

--- Clone a bound.
-- @param a bound2 bound to be cloned
-- @return bound2 out
function bound2.clone(a)
	return new(a.min, a.max)
end

--- Construct a bound covering one or two points 
-- @param vec2 a Any vector
-- @param vec2 b Any second vector (optional)
-- @return vec2 Minimum bound containing the given points
function bound2.at(a, b) -- "bounded by". b may be nil
	if b then
		return bound2.new(a,b):check()
	else
		return bound2.zero:with_center(a)
	end
end

--- Extend bound to include point
-- @param bound2 a bound
-- @param vec2 center to include
-- @return bound2 Bound covering current min, current max and new point
function bound2.extend(a, center)
	return bound2.new(a.min:component_min(center), a.max:component_max(center))
end

--- Extend bound to entirety of other bound
-- @param bound2 a bound
-- @param bound2 b bound to cover
-- @return bound2 Bound covering current min and max of each bound in the pair
function bound2.extend_bound(a, b)
	return a:extend(b.min):extend(b.max)
end

--- Get size of bounding box as a vector 
-- @param bound2 a bound
-- @return vec2 Vector spanning min to max points
function bound2.size(a)
	return a.max - a.min
end

--- Resize bounding box from minimum corner
-- @param bound2 a a bound
-- @param size vec2  new size
-- @return bound2 resized bound
function bound2.with_size(a, size)
	return bound2.new(a.min, a.min + size)
end

--- Get half-size of bounding box as a vector. A more correct term for this is probably "apothem"
-- @param bound2 a bound
-- @return vec2 Vector spanning center to max point
function bound2.radius(a)
	return a:size()/2
end

--- Get center of bounding box
-- @param bound2 a bound
-- @return bound2 Point in center of bound
function bound2.center(a)
	return (a.min + a.max)/2
end

--- Move bounding box to new center
-- @param bound2 a bound
-- @param vec2 new center
-- @return bound2 Bound with same size as input but different center
function bound2.with_center(a, center)
	return bound2.offset(a, center - a:center())
end

--- Resize bounding box from center
-- @param bound2 a bound
-- @param vec2 new size
-- @return bound2 resized bound
function bound2.with_size_centered(a, size)
	local center = a:center()
	local rad = size/2
	return bound2.new(center - rad, center + rad)
end

--- Convert possibly-invalid bounding box to valid one
-- @param bound2 a bound
-- @return bound2 bound with all components corrected for min-max property
function bound2.check(a)
	if a.min.x > a.max.x or a.min.y > a.max.y then
		return bound2.new(vec2.component_min(a.min, a.max), vec2.component_max(a.min, a.max))
	end
	return a
end

--- Shrink bounding box with fixed margin
-- @param bound2 a bound
-- @param vec2 a margin
-- @return bound2 bound with margin subtracted from all edges. May not be valid, consider calling check()
function bound2.inset(a, v)
	return bound2.new(a.min + v, a.max - v)
end

--- Expand bounding box with fixed margin
-- @param bound2 a bound
-- @param vec2 a margin
-- @return bound2 bound with margin added to all edges. May not be valid, consider calling check()
function bound2.outset(a, v)
	return bound2.new(a.min - v, a.max + v)
end

--- Offset bounding box
-- @param bound2 a bound
-- @param vec2 offset
-- @return bound2 bound with same size, but position moved by offset
function bound2.offset(a, v)
	return bound2.new(a.min + v, a.max + v)
end

--- Test if point in bound
-- @param bound2 a bound
-- @param vec2 point to test
-- @return boolean true if point in bounding box
function bound2.contains(a, v)
	return a.min.x <= v.x and a.min.y <= v.y
	   and a.max.x >= v.x and a.max.y >= v.y
end

-- Round all components of all vectors to nearest int (or other precision).
-- @param vec3 a bound to round.
-- @param precision Digits after the decimal (round number if unspecified)
-- @return vec3 Rounded bound
function bound2.round(a, precision)
	return bound2.new(a.min:round(precision), a.max:round(precision))
end

--- Return a formatted string.
-- @param bound2 a bound to be turned into a string
-- @return string formatted
function bound2.to_string(a)
	return string.format("(%s-%s)", a.min, a.max)
end

--- Return a boolean showing if a table is or is not a vec2.
---@param a vec2|any Vector to be tested
---@return boolean is_vec2
function bound2.is_bound2(a)
	if type(a) == "cdata" then
		return ffi.istype("cpml_bound2", a)
	end

	return
		type(a)   == "table"  and
		vec2.is_bound2(a.x) and
        vec2.is_bound2(a.y)
end

bound2_mt.__index    = bound2
bound2_mt.__tostring = bound2.to_string

function bound2_mt.__call(_, a, b)
	return bound2.new(a, b)
end

if status then
	xpcall(function() -- Allow this to silently fail; assume failure means someone messed with package.loaded
		ffi.metatype(new, bound2_mt)
	end, function() end)
end

return setmetatable({}, bound2_mt)
