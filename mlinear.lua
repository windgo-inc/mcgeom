-- 2017/10/13 mlinear.lua
-- William Whitacre
--

require 'pp'
require 'fun' ()

local ffi = require 'ffi'

-- NOTE: No hand holding, this is an intentionally low level library.
--
-- There are no type checks on any of the vector and matrix functions.
-- Additionally, each presumes that it's arguments are pointers to arrays of
-- floats. There is no bounds checking. It is possible to use the procedures
-- for smaller vectors to operate on a small chunk of elements in a longer
-- array. There may be clever ways to exploit this, and it is encouraged.

---------------------
-- Contant Epsilon --
---------------------

local epsilon = 1e-13
local epsilon_squared = epsilon * epsilon

local function within_epsilon (x)
  return x < epsilon and x > -epsilon
end

local function within_epsilon_squared (x)
  return x < epsilon_squared and x > -epsilon_squared
end

----------------
-- Base Types --
----------------

-- change this to use a different type for scalars throughout
local scalar_ctype = ffi.typeof 'float'

local typeof_scalar = scalar_ctype -- An alias that fits better.
local sizeof_scalar = ffi.sizeof (scalar_ctype)

local sizeof_tab_n, ctype_tab_n = { }, { }
for i = 1, 16 do
  rawset(sizeof_tab_n, i, sizeof_ctype * i)
  rawset(ctype_tab_n, i, ffi.typeof('$ [$]', scalar_ctype, i))
end

local function get_tabs (i)
  return ctype_tab_n[i], sizeof_tab_n[i]
end

-------------------------------------
-- Derived Primitive Types & Sizes --
-------------------------------------

local typeof_v2, sizeof_v2 = get_tabs(2)
local typeof_v3, sizeof_v3 = get_tabs(3)
local typeof_v4, sizeof_v4 = get_tabs(4)

local typeof_quaternion, sizeof_quaternion = get_tabs(4)

local typeof_m2_2, sizeof_m2_2 = get_tabs(4)
local typeof_m3_2, sizeof_m3_2 = get_tabs(6)
local typeof_m2_3, sizeof_m2_3 = get_tabs(6)
local typeof_m2_4, sizeof_m2_4 = get_tabs(8) -- 2017/10/12 - added support for 2x4 matrix
local typeof_m4_2, sizeof_m4_2 = get_tabs(8) -- 2017/10/12 - added support for 4x2 matrix
local typeof_m3_3, sizeof_m3_3 = get_tabs(9)
local typeof_m3_4, sizeof_m3_4 = get_tabs(12)
local typeof_m4_3, sizeof_m4_3 = get_tabs(12)
local typeof_m4_4, sizeof_m4_4 = get_tabs(16)

local typeof_scalarp = ffi.typeof('$ *', typeof_scalar)
local sizeof_scalarp = ffi.sizeof(typeof_scalarp)

local typeof_sindex = ffi.typeof'unsigned short'
local typeof_index  = ffi.typeof'unsigned int'
local typeof_lindex = ffi.typeof'unsigned long'

local sizeof_sindex = ffi.sizeof(typeof_sindex)
local sizeof_index  = ffi.sizeof(typeof_index)
local sizeof_lindex = ffi.sizeof(typeof_lindex)

local function typeof_parray (count)
  return ffi.typeof('$ [$]', typeof_scalarp, count)
end

local function typeof_2array (count)
  return ffi.typeof('$ [$]', typeof_v2, count)
end

local function typeof_3array (count)
  return ffi.typeof('$ [$]', typeof_v3, count)
end

local function typeof_4array (count)
  return ffi.typeof('$ [$]', typeof_v4, count)
end


local function typeof_2_2array (count)
  return ffi.typeof('$ [$]', typeof_m2_2, count)
end

local function typeof_3_2array (count)
  return ffi.typeof('$ [$]', typeof_m3_2, count)
end

local function typeof_2_3array (count)
  return ffi.typeof('$ [$]', typeof_m2_3, count)
end

local function typeof_3_3array (count)
  return ffi.typeof('$ [$]', typeof_m3_3, count)
end

local function typeof_3_4array (count)
  return ffi.typeof('$ [$]', typeof_m3_4, count)
end

local function typeof_4_3array (count)
  return ffi.typeof('$ [$]', typeof_m4_3, count)
end

local function typeof_4_4array (count)
  return ffi.typeof('$ [$]', typeof_m4_4, count)
end

local function typeof_sarray (count)
  return ffi.typeof('$ [$]', typeof_scalar, count)
end

local typeof_qarray = typeof_4array

local function typeof_varray (nelem, count)
  return ffi.typeof('$ [$][$]', typeof_scalar, nelem, count)
end

local function typeof_iarray (count)
  return ffi.typeof('$ [$]', typeof_index, count)
end

local function typeof_siarray (count)
  return ffi.typeof('$ [$]', typeof_sindex, count)
end

local function typeof_liarray (count)
  return ffi.typeof('$ [$]', typeof_lindex, count)
end

local function sizeof_sarray (count)
  return sizeof_scalar * count
end

local function sizeof_parray (count)
  return sizeof_scalarp * count
end

local function sizeof_2array (count)
  return sizeof_v2 * count
end

local function sizeof_3array (count)
  return sizeof_v3 * count
end

local function sizeof_4array (count)
  return sizeof_v3 * count
end

local function sizeof_2_2array (count)
  return sizeof_m2_2 * count
end

local function sizeof_4_2array (count)
  return sizeof_m4_2 * count
end

local sizeof_2_4array = sizeof_4_2array

local function sizeof_3_2array (count)
  return sizeof_m3_2 * count
end

local sizeof_2_3array = sizeof_3_2array

local function sizeof_3_3array (count)
  return sizeof_m3_3 * count
end

local function sizeof_3_4array (count)
  return sizeof_m3_4 * count
end

local sizeof_4_3array = sizeof_3_4array

local function sizeof_4_4array (count)
  return sizeof_m4_4 * count
end

local sizeof_qarray = sizeof_4array

local function sizeof_varray (nelem, count)
  return sizeof_scalarp * nelem * count
end

local function sizeof_iarray (count)
  return sizeof_index * count
end

local function sizeof_siarray (count)
  return sizeof_sindex * count
end

local function sizeof_liarray (count)
  return sizeof_lindex * count
end

get_tabs = nil
sizeof_tab_n = nil

----------------------------
-- Parameter Constructors --
----------------------------

local function new2 (x, y)
  return ffi.new(typeof_v2, {[0] = x or 0, y or 0})
end

local function new3 (x, y, z)
  return ffi.new(typeof_v3, {[0] = x or 0, y or 0, z or 0})
end

-- The default value of w is 1, for the sake of quaternions. Note that the
-- reason for putting the w component last is technical and does not have a
-- mathematical effect.  Namely, it is less confusing from an implementation
-- standpoint if x is always first and w is treated specially, because
-- quaternions are one of the only places the w component will actually be
-- used, and the order of the components has no effect on operations like
-- normalization.
local function new4 (x, y, z, w)
  return ffi.new(typeof_v4, {[0] = x or 0, y or 0, z or 0, w or 1})
end

------------------
-- Copy Setters --
------------------

local function set_copy2 (P, Q)
  ffi.copy(P, Q, sizeof_v2)
  return P
end

local function set_copy3 (P, Q)
  ffi.copy(P, Q, sizeof_v3)
  return P
end

local function set_copy4 (P, Q)
  ffi.copy(P, Q, sizeof_v4)
  return P
end

-------------------------
-- Stride Copy Setters --
-------------------------
--
-- These constructors permit one to take precisely every kth
-- element, where k is the pitch used to copy data from P.
-- This is also sometimes called the stride.

local function set_pcopy2 (P, Q, pitch)
  P[0], P[1] = Q[0], Q[pitch]
  return P
end

local function set_pcopy3 (P, Q, pitch)
  P[0], P[1], P[2] = Q[0], Q[pitch], Q[2 * pitch]
  return P
end

local function set_pcopy4 (P, Q, pitch)
  P[0], P[1], P[2], P[3] = Q[0], Q[pitch], Q[2 * pitch], Q[3 * pitch]
  return P
end

------------------
-- Fill Setters --
------------------

local function set_fill2 (P, x)
  P[0], P[1] = x, x
  return P
end

local function set_fill3 (P, x)
  P[0], P[1], P[2] = x, x, x
  return P
end

local function set_fill4 (P, x)
  P[0], P[1], P[2], P[3] = x, x, x, x
  return P
end

-----------------------
-- Copy Constructors --
-----------------------

local function copy2 (P)
  return set_copy2(ffi.new(typeof_v2), P)
end

local function copy3 (P)
  return set_copy3(ffi.new(typeof_v3), P)
end

local function copy4 (P)
  return set_copy4(ffi.new(typeof_v4), P)
end

------------------------------
-- Stride Copy Constructors --
------------------------------
--
-- These constructors permit one to take precisely every kth
-- element, where k is the pitch used to copy data from P.
-- This is also sometimes called the stride.

local function pcopy2 (P, pitch)
  return set_pcopy2(ffi.new(typeof_v2), P, pitch)
end

local function pcopy3 (P, pitch)
  return set_pcopy3(ffi.new(typeof_v3), P, pitch)
end

local function pcopy4 (P, pitch)
  return set_pcopy4(ffi.new(typeof_v4), P, pitch)
end

-----------------------
-- Fill Constructors --
-----------------------

local function fill2 (x)
  return ffi.new(typeof_v2, {[0] = x, x})
end

local function fill3 (x)
  return ffi.new(typeof_v3, {[0] = x, x, x})
end

local function fill4 (x)
  return ffi.new(typeof_v4, {[0] = x, x, x, x})
end


--------------------
-- Vector Getters --
--------------------

local function get2(P, ia, ib)
  return P[ia], P[ib]
end

local function get3(P, ia, ib, ic)
  return P[ia], P[ib], P[ic]
end

local function get4(P, ia, ib, ic, id)
  return P[ia], P[ib], P[ic], P[id]
end

----------------------
-- Swizzle Operator --
----------------------

local function swizzle2(P, ia, ib)
  return new2(get2(P, ia, ib))
end

local function swizzle3(P, ia, ib, ic)
  return new3(get3(P, ia, ib, ic))
end

local function swizzle4(P, ia, ib, ic, id)
  return new4(get4(P, ia, ib, ic, id))
end

---------------------------------------
-- Unit Vectors, Identity Quaternion --
---------------------------------------

local _0v_2 = new2()
local _0v_3 = new3()
local _0v_4 = fill4(0)

local function zero2 ()
  return copy2(_0v_2)
end

local function zero3 ()
  return copy3(_0v_3)
end

local function zero4 ()
  return copy4(_0v_4)
end

local _vi3, _vj3, _vk3 = new3(1, 0, 0), new3(0, 1, 0), new3(0, 0, 1)

local function unitx2 ()
  return copy2(_vi3)
end

local function unity2 ()
  return copy2(_vj3)
end

local function unitx3 ()
  return copy3(_vi3)
end

local function unity3 ()
  return copy3(_vj3)
end

local function unitz3 ()
  return copy3(_vk3)
end

local _q_identity = new4(0, 0, 0, 1)

-----------------------------
-- Linear Vector Operators --
-----------------------------

-- Negation
local function set_neg2 (P)
  P[0] = -P[0]
  P[0] = -P[1]
  return P
end

local function set_neg3 (P)
  P[0] = -P[0]
  P[1] = -P[1]
  P[2] = -P[2]
  return P
end

local function set_neg4 (P)
  P[0] = -P[0]
  P[1] = -P[1]
  P[2] = -P[2]
  P[3] = -P[3]
  return P
end

local function neg2 (P)
  return set_neg2(copy2(P))
end

local function neg3 (P)
  return set_neg3(copy3(P))
end

local function neg4 (P)
  return set_neg4(copy4(P))
end

-- vec2 arith
--
-- add2
local function adds2 (P, x)
  return new2(P[0] + x, P[1] + x)
end

local function accadds2 (P, x)
  P[0] = P[0] + x
  P[1] = P[1] + x
  return P
end

local function add2 (P1, P2)
  return new2(P1[0] + P2[0], P1[1] + P2[1])
end

local function accadd2 (P1, P2)
  P1[0] = P1[0] + P2[0]
  P1[1] = P1[1] + P2[1]
  return P1
end

-- sub2
local function subs2 (P, x)
  return new2(P[0] - x, P[1] - x)
end

local function accsubs2 (P, x)
  P[0] = P[0] - x
  P[1] = P[1] - x
  return P
end

local function sub2 (P1, P2)
  return new2(P1[0] - P2[0], P1[1] - P2[1])
end

local function accsub2 (P1, P2)
  P1[0] = P1[0] - P2[0]
  P1[1] = P1[1] - P2[1]
  return P1
end

-- mul2
local function muls2 (P, x)
  return new2(P[0] * x, P[1] * x)
end

local function accmuls2 (P, x)
  P[0] = P[0] * x
  P[1] = P[1] * x
  return P
end

local function mul2 (P1, P2)
  return new2(P1[0] * P2[0], P1[1] * P2[1])
end

local function accmul2 (P1, P2)
  P1[0] = P1[0] * P2[0]
  P1[1] = P1[1] * P2[1]
  return P1
end

-- div2
local function divs2 (P, x)
  --assert (x ~= 0, "cannot divide by zero")
  return new2(P[0] / x, P[1] / x)
end

local function accdivs2 (P, x)
  --assert (x ~= 0, "cannot divide by zero")
  P[0] = P[0] / x
  P[1] = P[1] / x
  return P
end

local function div2 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0, "cannot divide by zero")
  return new2(P1[0] / P2[0], P1[1] / P2[1])
end

local function accdiv2 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0, "cannot divide by zero")
  P1[0] = P1[0] / P2[0]
  P1[1] = P1[1] / P2[1]
  return P1
end

-- vec3 arith
local function adds3 (P, x)
  return new3(P[0] + x, P[1] + x, P[2] + x)
end

local function accadds3 (P, x)
  P[0] = P[0] + x
  P[1] = P[1] + x
  P[2] = P[2] + x
  return P
end

local function add3 (P1, P2)
  return new3(P1[0] + P2[0], P1[1] + P2[1], P1[2] + P2[2])
end

local function accadd3 (P1, P2)
  P1[0] = P1[0] + P2[0]
  P1[1] = P1[1] + P2[1]
  P1[2] = P1[2] + P2[2]
  return P1
end

local function subs3 (P, x)
  return new3(P[0] - x, P[1] - x, P[2] - x)
end

local function accsubs3 (P, x)
  P[0] = P[0] - x
  P[1] = P[1] - x
  P[2] = P[2] - x
  return P
end

local function sub3 (P1, P2)
  return new3(P1[0] - P2[0], P1[1] - P2[1], P1[2] - P2[2])
end

local function accsub3 (P1, P2)
  P1[0] = P1[0] - P2[0]
  P1[1] = P1[1] - P2[1]
  P1[2] = P1[2] - P2[2]
  return P1
end

local function muls3 (P, x)
  return new3(P[0] * x, P[1] * x, P[2] * x)
end

local function accmuls3 (P, x)
  P[0] = P[0] * x
  P[1] = P[1] * x
  P[2] = P[2] * x
  return P
end

local function mul3 (P1, P2)
  return new3(P1[0] * P2[0], P1[1] * P2[1], P1[2] * P2[2])
end

local function accmul3 (P1, P2)
  P1[0] = P1[0] * P2[0]
  P1[1] = P1[1] * P2[1]
  P1[2] = P1[2] * P2[2]
  return P1
end

local function divs3 (P, x)
  assert (x ~= 0, "cannot divide by zero")
  return new3(P[0] / x, P[1] / x, P[2] / x)
end

local function accdivs3 (P, x)
  --assert (x ~= 0, "cannot divide by zero")
  P[0] = P[0] / x
  P[1] = P[1] / x
  P[2] = P[2] / x
  return P
end

local function div3 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0 and P2[2] ~= 0, "cannot divide by zero")
  return new3(P1[0] / P2[0], P1[1] / P2[1], P1[2] / P2[2])
end

local function accdiv3 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0 and P2[2] ~= 0, "cannot divide by zero")
  P1[0] = P1[0] / P2[0]
  P1[1] = P1[1] / P2[1]
  P1[2] = P1[2] / P2[2]
  return P1
end

-- vec4 arith
local function adds4 (P, x)
  return new4(P[0] + x, P[1] + x, P[2] + x, P[3] + x)
end

local function accadds4 (P, x)
  P[0] = P[0] + x
  P[1] = P[1] + x
  P[2] = P[2] + x
  P[3] = P[3] + x
  return P
end

local function add4 (P1, P2)
  return new4(P1[0] + P2[0], P1[1] + P2[1], P1[2] + P2[2], P1[3] + P2[3])
end

local function accadd4 (P1, P2)
  P1[0] = P1[0] + P2[0]
  P1[1] = P1[1] + P2[1]
  P1[2] = P1[2] + P2[2]
  P1[3] = P1[3] + P2[3]
  return P1
end

local function subs4 (P, x)
  return new4(P[0] - x, P[1] - x, P[2] - x, P[3] - x)
end

local function accsubs4 (P, x)
  P[0] = P[0] - x
  P[1] = P[1] - x
  P[2] = P[2] - x
  P[3] = P[3] - x
  return P
end

local function sub4 (P1, P2)
  return new4(P1[0] - P2[0], P1[1] - P2[1], P1[2] - P2[2], P1[3] - P2[3])
end

local function accsub4 (P1, P2)
  P1[0] = P1[0] - P2[0]
  P1[1] = P1[1] - P2[1]
  P1[2] = P1[2] - P2[2]
  P1[3] = P1[3] - P2[3]
  return P1
end

local function muls4 (P, x)
  return new4(P[0] * x, P[1] * x, P[2] * x, P[3] * x)
end

local function accmuls4 (P, x)
  P[0] = P[0] * x
  P[1] = P[1] * x
  P[2] = P[2] * x
  P[3] = P[3] * x
  return P
end

local function mul4 (P1, P2)
  return new4(P1[0] * P2[0], P1[1] * P2[1], P1[2] * P2[2], P1[3] * P2[3])
end

local function accmul4 (P1, P2)
  P1[0] = P1[0] * P2[0]
  P1[1] = P1[1] * P2[1]
  P1[2] = P1[2] * P2[2]
  P1[3] = P1[3] * P2[3]
  return P1
end

local function divs4 (P, x)
  --assert (x ~= 0, "cannot divide by zero")
  return new4(P[0] / x, P[1] / x, P[2] / x, P[3] / x)
end

local function accdivs4 (P, x)
  --assert (x ~= 0, "cannot divide by zero")
  P[0] = P[0] / x
  P[1] = P[1] / x
  P[2] = P[2] / x
  P[3] = P[3] / x
  return P
end

local function div4 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0 and P2[2] ~= 0 and P2[3] ~= 0, "cannot divide by zero")
  return new4(P1[0] / P2[0], P1[1] / P2[1], P1[2] / P2[2], P1[3] / P2[3])
end

local function accdiv4 (P1, P2)
  --assert (P2[0] ~= 0 and P2[1] ~= 0 and P2[2] ~= 0 and P2[3] ~= 0, "cannot divide by zero")
  P1[0] = P1[0] / P2[0]
  P1[1] = P1[1] / P2[1]
  P1[2] = P1[2] / P2[2]
  P1[3] = P1[3] / P2[3]
  return P1
end

---------------------
-- Vector Products --
---------------------

-- 2D Dot Product (P1 · P2)
local function dot2 (P1, P2)
  return P1[0] * P2[0] + P1[1] * P2[1]
end

-- 3D Dot Product (P1 · P2)
local function dot3 (P1, P2)
  return P1[0] * P2[0] + P1[1] * P2[1] + P1[2] * P2[2]
end

-- 4D Dot Product (P1 · P2)
local function dot4 (P1, P2)
  return P1[0] * P2[0] + P1[1] * P2[1] + P1[2] * P2[2] + P1[3] * P2[3]
end

-- In-place left hand perpendicluar of a 2D vector.
local function set_lperp2 (P)
  local x = P[0]
  P[0] = -P[1]
  P[1] = x
  return P
end

-- In-place right hand perpendicluar of a 2D vector.
local function set_rperp2 (P)
  local x = P[0]
  P[0] = P[1]
  P[1] = -x
  return P
end

-- Pure left hand perpendicular.
local function lperp2 (P)
  return set_lperp2(copy2(P))
end

-- Pure right hand perpendicular.
local function rperp2 (P)
  return set_rperp2(copy2(P))
end

-- 2D Wedge Product, also known as Perpendicular Dot Product (i.e. lperp2(A) · B) or
-- the 2D Cross Product.
local function lwedge2 (P1, P2)
  return P1[0]*P2[1] - P1[1]*P2[0] -- negative P1[0]
end

local function rwedge2 (P1, P2)
  return P1[1]*P2[0] - P1[0]*P2[1] -- positive P1[0]
end

local wedge2 = lwedge2

-- Left-handed cross product. (Sarus's Rule)
local function lcross3 (P1, P2)
  return new3(P1[1]*P2[2] - P1[2]*P2[1],
              P1[2]*P2[0] - P1[0]*P2[2],
              P1[0]*P2[1] - P1[1]*P2[0])
end

-- Right-handed cross product. (Sarus's Rule)
local function rcross3 (P1, P2)
  return new3(P1[2]*P2[1] - P1[1]*P2[2],
              P1[0]*P2[2] - P1[2]*P2[0],
              P1[1]*P2[0] - P1[0]*P2[1])
end

local cross3 = lcross3

---------------------------
-- Norm Squared Function --
---------------------------

-- The norm of a 2D vector squared.
local function normsq2 (P)
  return dot2 (P, P)
end

-- The norm of a 3D vector squared.
local function normsq3 (P)
  return dot3 (P, P)
end

-- The norm of a 4D vector squared.
local function normsq4 (P)
  return dot4 (P, P)
end


-- The norm of a 2D vector squared.
local function norm2 (P)
  return math.sqrt (dot2 (P, P))
end

-- The norm of a 3D vector squared.
local function norm3 (P)
  return math.sqrt (dot3 (P, P))
end

-- The norm of a 4D vector squared.
local function norm4 (P)
  return math.sqrt (dot4 (P, P))
end


-- A 2D vector divided by it's norm.
local function normalized2 (P)
  return divs2 (P, dot2 (P, P))
end

-- A 3D vector divided by it's norm.
local function normalized3 (P)
  return divs3 (P, dot3 (P, P))
end

-- A 4D vector divided by it's norm.
local function normalized4 (P)
  return divs4 (P, dot4 (P, P))
end


-- In-place normalization of a 2D vector.
local function set_normalized2 (P)
  return accdivs2 (P, dot2 (P, P))
end

-- In-place normalization of a 3D vector.
local function set_normalized3 (P)
  return accdivs3 (P, dot3 (P, P))
end

-- In-place normalization of a 4D vector.
local function set_normalized4 (P)
  return accdivs4 (P, dot4 (P, P))
end


-------------------
-- Interpolation --
-------------------

local function lerp (x, y, t)
  return x * (1 - t) + y * t
end

local function lerp2 (P1, P2, t)
  local p = muls2(P1, 1 - t)
  return accadd2(p, muls2(P2, t))
end

local function lerp3 (P1, P2, t)
  local p = muls3(P1, 1 - t)
  return accadd3(p, muls3(P2, t))
end

local function lerp4 (P1, P2, t)
  local p = muls4(P1, 1 - t)
  return accadd4(p, muls4(P2, t))
end

---------------------------
-- Midpoint Special Case --
---------------------------
--
local function midpt1 (x, y)
  return (x + y) * 0.5
end

local function midpt2 (P1, P2)
  return accmuls2(add2(P1, P2), 0.5)
end

local function midpt3 (P1, P2)
  return accmuls3(add3(P1, P2), 0.5)
end

local function midpt4 (P1, P2)
  return accmuls4(add4(P1, P2), 0.5)
end

-------------------------------------
-- Quaternion Conversions and Unit -- 
-------------------------------------

-- Note that all quaternion rotation related functions, as well as these
-- constructors, assume operation on unit vectors for axes, and on quaternions
-- representing rotations.
--
-- Note also that while the traditional mathematical representation of a
-- quaternion is given in the order (w, x, y, z), we store it as (x, y, z, w)
-- for computational reasons. Namely, extraction of (x, y, z) is unneccesary
-- and so no pointer arithmetic or copying is needed to access these
-- components, which encode the parts of sin(theta) where theta is the angle of
-- the rotation.

local function qunit4 ()
  return copy4(_q_identity)
end

local function qfromv4 (p)
  return new4(p[0], p[1], p[2], 0)
end

local function qtov4 (q)
  return copy3(q)
end

local function qfromaxisangle4 (axis, angle)
  local halfangle = angle * 0.5

  if halfangle * halfangle > 0 then
    local sinha = math.sin(halfangle)
    return new4(axis[0] * sinha, axis[1] * sinha, axis[2] * sinha, math.cos(halfangle))
  else
    return qunit4() -- no rotation
  end
end

local function qtoaxisangle4 (q)
  local sinsq = dot3(q, q)

  if sinsq > 0 then
    local sintheta = math.sqrt(sinsq)
    local k = 2 * math.atan2(sintheta, q[3])
    return copy3(q), k
  else
    return new3(), 0 -- no rotation
  end
end


---------------------------
-- Quaternion Operations --
---------------------------

-- In-place inverse of a quaternion
local function set_qinverse4 (q)
  -- negate xyz and normalize xyzw
  return set_normalized4(set_neg3(q))
end

-- Conjugate of a quaternion
local function qinverse4 (q)
  return set_qinverse4(copy4(q))
end

-- In-place conjugate
local set_qconj4 = set_neg3 -- exploiting x, y, z, w order

-- Conjugate of a quaternion (assuming normalized quaternion)
local function qconj4 (q)
  -- the w component carries through unchanged.
  return set_neg3(copy4(q))
end

-- Quaternion multiplication
local function qmult4 (q1, q2)
  return new4((q1[3] * q2[0]) + (q1[0] * q2[3]) + (q1[1] * q2[2]) - (q1[2] * q2[1]),
              (q1[3] * q2[1]) - (q1[0] * q2[2]) + (q1[1] * q2[3]) + (q1[2] * q2[0]),
              (q1[3] * q2[2]) + (q1[0] * q2[1]) - (q1[1] * q2[0]) + (q1[2] * q2[3]), 
              (q1[3] * q2[3]) - (q1[0] * q2[0]) - (q1[1] * q2[1]) - (q1[2] * q2[2]))
end

-- Quaternion rotation. p should be a euclidean vector in R^3 represented as a
-- pure quaternion, and q should be a quaternion representing an axis-angle
-- rotation.
local function qrotate4 (p, q)
  return qmult4(qmult4(q, p), qconj4(q))
end

-------------------------------
-- Simple Geometric Modeling --
-------------------------------

-- Ray Types
local typeof_rayv  = typeof_3array (2)
local typeof_rayp  = typeof_parray (2)

local sizeof_rayv  = ffi.sizeof(typeof_rayv)
local sizeof_rayp  = ffi.sizeof(typeof_rayp)

-- Plane Types (n0, n1, n2, d)
-- A plane is encoded as a unit vector representing it's orientation,
-- and a scalar d which represents the plane's offset from the origin
-- along that unit vector.
local typeof_planev  = typeof_v4
local typeof_planep  = typeof_scalarp

local sizeof_planev  = ffi.sizeof(typeof_triv)
local sizeof_planep  = sizeof_scalarp

-- Finite Frustum Type (l, r, b, t, near, far)

local typeof_frustumv = ffi.typeof ('$ [6]', typeof_scalar)
local typeof_frustump = typeof_scalarp

local sizeof_frustumv = sizeof_scalar * 6
local sizeof_frustump = sizeof_scalarp

-- Infinite Frustum Type (l, r, b, t, near)

local typeof_inffrustumv = ffi.typeof ('$ [5]', typeof_scalar)
local typeof_inffrustump = typeof_scalarp

local sizeof_inffrustumv = sizeof_scalar * 5
local sizeof_inffrustump = sizeof_scalarp

-- Pure Frustum Type (l, r, b, t)
-- This is defined because in many cases we want to define
-- near and far values independently of the possible frustums
-- to use. That is because there are sensible constants to
-- choose for these values, which should then be observed
-- globally to simplify computation.
--
local typeof_purefrustumv = typeof_v4
local typeof_purefrustump = typeof_scalarp

local sizeof_purefrustumv = sizeof_v4
local sizeof_purefrustump = sizeof_scalarp

--------------------------
-- Primitive Polygons ----
--------------------------

-- Triangle Types
local typeof_triv  = typeof_3array (3)
local typeof_trip  = typeof_parray (3)
local typeof_trii  = typeof_iarray (3)
local typeof_trisi = typeof_siarray (3)
local typeof_trili = typeof_liarray (3)

local sizeof_triv  = ffi.sizeof(typeof_triv)
local sizeof_trip  = ffi.sizeof(typeof_trip)
local sizeof_trii  = ffi.sizeof(typeof_trii)
local sizeof_trisi = ffi.sizeof(typeof_trisi)
local sizeof_trili = ffi.sizeof(typeof_trili)

-- Quad Types
local typeof_quadv  = typeof_3array (4)
local typeof_quadp  = typeof_parray (4)
local typeof_quadi  = typeof_iarray (4)
local typeof_quadsi = typeof_siarray (4)
local typeof_quadli = typeof_liarray (4)

local sizeof_quadv  = ffi.sizeof(typeof_quadv)
local sizeof_quadp  = ffi.sizeof(typeof_quadp)
local sizeof_quadi  = ffi.sizeof(typeof_quadi)
local sizeof_quadsi = ffi.sizeof(typeof_quadsi)
local sizeof_quadli = ffi.sizeof(typeof_quadli)

-- Pentagon Types
local typeof_pentv  = typeof_3array (5)
local typeof_pentp  = typeof_parray (5)
local typeof_penti  = typeof_iarray (5)
local typeof_pentsi = typeof_siarray (5)
local typeof_pentli = typeof_liarray (5)

local sizeof_pentv  = ffi.sizeof(typeof_pentv)
local sizeof_pentp  = ffi.sizeof(typeof_pentp)
local sizeof_penti  = ffi.sizeof(typeof_penti)
local sizeof_pentsi = ffi.sizeof(typeof_pentsi)
local sizeof_pentli = ffi.sizeof(typeof_pentli)

-- Hexagon Types
local typeof_hexv  = typeof_3array (6)
local typeof_hexp  = typeof_parray (6)
local typeof_hexi  = typeof_iarray (6)
local typeof_hexsi = typeof_siarray (6)
local typeof_hexli = typeof_liarray (6)

local sizeof_hexv  = ffi.sizeof(typeof_hexv)
local sizeof_hexp  = ffi.sizeof(typeof_hexp)
local sizeof_hexi  = ffi.sizeof(typeof_hexi)
local sizeof_hexsi = ffi.sizeof(typeof_hexsi)
local sizeof_hexli = ffi.sizeof(typeof_hexli)


---------------------------
-- Tesselation Apertures --
---------------------------
--
-- TODO - Fill out this section with the listing
-- of apertures in the GEI project journal.

local function tri4 (d, T)
  if d == 0 then
    return iter{ T }
  else
    local mp12, mp23, mp31 = mid3 (T[1], T[2]), mid3 (T[2], T[3]), mid3 (T[3], T[1])
    local Q = tri4 (d - 1, { mp12, mp31, T[1] })
    local R = tri4 (d - 1, { mp23, mp12, T[2] })
    local S = tri4 (d - 1, { mp31, mp23, T[3] })
    local T = tri4 (d - 1, { mp12, mp23, mp31 })
    return chain(Q, R, S, T)
  end
end

-------------------------------------
-- Matrix Constructors and Setters --
-------------------------------------
--
-- Note that tranformation matrices will be used as little as possible.  While
-- a useful abstraction, especially for encoding the order of a series of
-- transformations, they are needed only for the final perspective
-- transformation, and can be helpfully loaded in with a view matrix which
-- encodes the eye in the same construct.  Otherwise, quaternions offer a more
-- compact encoding for rotations, and they can be paired with translation and
-- scaling vectors, still better than a 4x4 matrix taken all together in a 16
-- float layout because it leaves room for one more three vector encoding.
--
-- NOTE: TRANSPOSED ARGUMENT LIST CONSTRUCTORS
-- The reason for doing this is so that when the matrix is specified as a comma
-- separated list, the matrix will be stored as COLUMN MAJOR, taking the VISUAL
-- COLUMNS FORMED BY EVERY ITH ELEMENT as the arguments are laid out as the
-- columns of the stored matrix.

-- Type reference copied from top.
--   typeof_m2_2, sizeof_m2_2
--   typeof_m3_2, sizeof_m3_2
--   typeof_m2_3, sizeof_m2_3
--   typeof_m2_4, sizeof_m2_4
--   typeof_m4_2, sizeof_m4_2
--   typeof_m3_3, sizeof_m3_3
--   typeof_m3_4, sizeof_m3_4
--   typeof_m4_3, sizeof_m4_3
--   typeof_m4_4, sizeof_m4_4

local function set2_2 (M, m11, m21, m12, m22)
  M[0], M[2] = m11, m21
  M[1], M[3] = m12, m22
  return M
end

local function fillzero2_2 (M)
  M[0], M[1], M[2], M[3] = 0, 0, 0, 0
end

local function zero2_2 ()
  return ffi.new(typeof_m2_2)
end

local function identity2_2 ()
  local M = zero2_2()
  M[0], M[3] = 1, 1
  return M
end

local function create2_2 (...)
  return set2_2(zero2_2(), select (1, ...))
end

local function set2_3 (M, m11, m21,
                          m12, m22,
                          m13, m23)
  M[0], M[3] = m11, m21
  M[1], M[4] = m12, m22
  M[2], M[5] = m13, m23
  return M
end

local function fillzero2_3 (M)
  M[0], M[1], M[2], M[3], M[4], M[5] = 0, 0, 0, 0, 0, 0
end

local function zero2_3 ()
  return ffi.new(typeof_m2_3)
end

local function identity2_3 ()
  local M = zero2_3()
  M[0], M[4] = 1, 1
  return M
end

local function create2_3 (...)
  return set2_3(zero2_3(), select (1, ...))
end

local function set3_2 (M, m11, m21, m31,
                          m12, m22, m32)

  M[0], M[2], M[4] = m11, m21, m31
  M[1], M[3], M[5] = m12, m22, m32
  return M
end

local fillzero3_2 = fillzero_2_3

local function zero3_2 ()
  return ffi.new(typeof_m3_2)
end

local function identity3_2 ()
  local M = zero3_2()
  M[0], M[3] = 1, 1
  return M
end

local function create3_2 (...)
  return set3_2(zero3_2(), select (1, ...))
end

local function set2_4 (M, m11, m21,
                          m12, m22,
                          m13, m23,
                          m14, m24)
  M[0], M[4] = m11, m21
  M[1], M[5] = m12, m22
  M[2], M[6] = m13, m23
  M[3], M[7] = m14, m24
  return M
end

local function fillzero2_4 (M)
  M[0], M[1], M[2], M[3], M[4], M[5], M[6], M[7] = 0, 0, 0, 0, 0, 0, 0, 0
end

local function zero2_4 ()
  return ffi.new(typeof_m2_4)
end

local function identity2_4 ()
  local M = zero2_4()
  M[0], M[5] = 1, 1
  return M
end

local function create2_4 (...)
  return set2_4(zero2_4(), select (1, ...))
end

local function set4_2 (M, m11, m21, m31, m41
                          m12, m22, m32, m42)

  M[0], M[2], M[4], M[6] = m11, m21, m31, m41
  M[1], M[3], M[5], M[7] = m12, m22, m32, m42
  return M
end

local fillzero4_2 = fillzero2_4

local function zero4_2 ()
  return ffi.new(typeof_m4_2)
end

local function identity4_2 ()
  local M = zero4_2()
  M[0], M[3] = 1, 1
  return M
end

local function create4_2 (...)
  return set4_2(zero4_2(), select (1, ...))
end

local function set3_3 (M, m11, m21, m31,
                          m12, m22, m32,
                          m13, m23, m33)

  M[0], M[3], M[6] = m11, m21, m31
  M[1], M[4], M[7] = m12, m22, m32
  M[2], M[5], M[8] = m13, m23, m33
  return M
end

local function fillzero3_3 (M)
  M[0], M[1], M[2], M[3], M[4], M[5], M[6], M[7], M[8] = 0, 0, 0, 0, 0, 0, 0, 0, 0
end

local function zero3_3 ()
  return ffi.new(typeof_m3_3)
end

local function identity3_3 ()
  local M = zero3_3()
  M[0], M[4], M[8] = 1, 1, 1
  return M
end

local function create3_3 (...)
  return set3_3(zero3_3(), select (1, ...))
end

local function set3_4 (M, m11, m21, m31,
                          m12, m22, m32,
                          m13, m23, m33,
                          m14, m24, m34)

  M[0], M[4], M[8]  = m11, m21, m31
  M[1], M[5], M[9]  = m12, m22, m32
  M[2], M[6], M[10] = m13, m23, m33
  M[3], M[7], M[11] = m14, m24, m34
  return M
end

local function fillzero3_4 (M)
  M[0], M[1], M[2], M[3], M[4], M[5], M[6], M[7], M[8], M[9], M[10], M[11] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
end

local function zero3_4 ()
  return ffi.new(typeof_m3_4)
end

local function identity3_4 ()
  local M = zero3_4()
  M[0], M[5], M[10] = 1, 1, 1
  return M
end

local function create3_4 (...)
  return set3_4(zero3_4(), select (1, ...))
end

local function set4_3 (M, m11, m21, m31, m41,
                          m12, m22, m32, m42,
                          m13, m23, m33, m43)

  M[0], M[3], M[6], M[9]  = m11, m21, m31, m41
  M[1], M[4], M[7], M[10] = m12, m22, m32, m42
  M[2], M[5], M[8], M[11] = m13, m23, m33, m43
  return M
end

local fillzero4_3 = fillzero3_4

local function zero4_3 ()
  return ffi.new(typeof_m4_3)
end

local function identity4_3 ()
  local M = zero4_3()
  M[0], M[4], M[8] = 1, 1, 1
  return M
end

local function create4_3 (...)
  return set4_3(zero4_3(), select (1, ...))
end

local function set4_4 (M, m11, m21, m31, m41,
                          m12, m22, m32, m42,
                          m13, m23, m33, m43,
                          m14, m24, m34, m44)

  M[0], M[4], M[8],  M[12] = m11, m21, m31, m41
  M[1], M[5], M[9],  M[13] = m12, m22, m32, m42
  M[2], M[6], M[10], M[14] = m13, m23, m33, m43
  M[3], M[7], M[11], M[15] = m14, m24, m34, m44
  return M
end

local function fillzero4_4 (M)
  M[0], M[1], M[2], M[3], M[4], M[5], M[6], M[7], M[8], M[9], M[10], M[11], M[12], M[13], M[14], M[15] = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
end

local function zero4_4 ()
  return ffi.new(typeof_m4_4)
end

local function identity4_4 ()
  local M = zero4_4()
  M[0], M[5], M[10], M[15] = 1, 1, 1, 1
  return M
end

local function create4_4 (...)
  return set4_3(zero4_4(), select (1, ...))
end

----------------------
-- Matrix Transpose --
----------------------

local function transpose2_2 (M)
  M[2], M[1] = M[1], M[2]
  return M
end

-- 0 2 4
-- 1 3 5
--
-- 0 3
-- 1 4
-- 2 5
local function transpose3_2 (M)
  M[1], M[2], M[3], M[4] = M[2], M[4], M[1], M[3]
  return M
end

-- 0 2 4 6
-- 1 3 5 7
--
-- 0 4
-- 1 5
-- 2 6
-- 3 7
local function transpose4_2 (M)
  M[1], M[2], M[3], M[4], M[5], M[6] = M[2], M[4], M[6], M[1], M[3], M[5]
  return M
end

local function transpose2_3 (M)
  M[2], M[4], M[1], M[3] = M[1], M[2], M[3], M[4]
  return M
end

local function transpose3_3 (M)
  M[3], M[1] = M[1], M[3]
  M[6], M[2] = M[2], M[6]
  M[7], M[5] = M[5], M[7]
  return M
end

-- 0   3   6   9
-- 1   4   7  10
-- 2   5   8  11
--
-- 0   4   8
-- 1   5   9
-- 2   6  10
-- 3   7  11
local function transpose4_3 (M)
  M[1], M[2], M[3], M[4], M[5], M[6], M[7], M[8], M[9], M[10] = M[3], M[6], M[9], M[1], M[4], M[7], M[10], M[2], M[5], M[8]
  return M
end

local function transpose2_4 (M)
  M[2], M[4], M[6], M[1], M[3], M[5] = M[1], M[2], M[3], M[4], M[5], M[6]
  return M
end

local function transpose3_4 (M)
  M[3], M[6], M[9], M[1], M[4], M[7], M[10], M[2], M[5], M[8] = M[1], M[2], M[3], M[4], M[5], M[6], M[7], M[8], M[9], M[10]
  return M
end

local function transpose4_4 (M)
  M[1],  M[4]  = M[4],  M[1]
  M[2],  M[8]  = M[8],  M[2]
  M[3],  M[12] = M[12], M[3]
  M[6],  M[9]  = M[9],  M[6]
  M[7],  M[13] = M[13], M[7]
  M[11], M[14] = M[14], M[11]
  return M
end

--------------------
-- Matrix Windows --
--------------------
--
-- In some cases when dealing with more intricate algorithms, one might wish to
-- operate only on a window within a matrix. While swizzling gives us this
-- ability weakly with vectors, we don't bother with the fully blown "window"
-- concept in vectors because it's likely that vectors represent normals, points,
-- rays, or other objects which are used a lot, and require the best performance.
--
-- On the other hand, the enhanced readability of virtual windows in to data
-- enable lucid and clear implementations of more advanced algorithms on
-- matrices. This is of a net benefit, as the number of matrices is likely to
-- be much smaller than the number of points or vectors, and superior algorithms
-- for matrix operations outweigh the constant factor as a concern any time
-- the complexity of naive implementations of those same procedures exceeds it
-- on an amortized basis, which is a basic principle of computing.
--
-- Nevertheless, this utility is still built for performance. There are still no
-- guard rails when using this abstraction. You are responsible for ensuring that
-- you have not specified a window which is out of bounds, checking types if
-- source data are unknown, etc.

local function _windex_compute (iwj, arows, wrows)
  local wcol = math.floor(iwj / wrows) -- compute window column
  local wrow = iwj - wcol * wrows      -- compute window row
  return wrow + wcol * arows -- compute actual column from actual rows
end

local function _windex_within (Mw, iwj)
  return rawget(Mw, 4) + _windex_compute(iwj, rawget(Mw, 2), rawget(Mw, 3))
end

local wmmt = {
  __newindex = function (Mw, iwj, x)
    local M = rawget(Mw, 1)
    M[_windex_within(Mw, iwj)] = x
  end,
  __index = function (Mw, iwj, x)
    local M = rawget(Mw, 1)
    return M[_windex_within(Mw, iwj)]
  end,
  __metatable = { }
}

local function window_aperture_2row (col, row, wrows, M)
  return setmetatable({ M, [2] = 2, [3] = wrows, [4] = col*2 + row }, wmmt)
end

local function window_aperture_3row (col, row, wrows, M)
  return setmetatable({ M, [2] = 3, [3] = wrows, [4] = col*3 + row }, wmmt)
end

local function window_aperture_4row (col, row, wrows, M)
  return setmetatable({ M, [2] = 4, [3] = wrows, [4] = col*4 + row }, wmmt)
end

local window2_2 = window_aperture_2row
local window3_2 = window_aperture_2row
local window4_2 = window_aperture_2row
local window2_3 = window_aperture_3row
local window3_3 = window_aperture_3row
local window4_3 = window_aperture_3row
local window2_4 = window_aperture_4row
local window3_4 = window_aperture_4row
local window4_4 = window_aperture_4row

----------------------------------
-- Scalar Matrix Multiplication --
----------------------------------

local function muls2_2 (M, s)
  return create2_2(
    M[0] * s, M[2] * s,
    M[1] * s, M[3] * s)
end

local function accmuls2_2 (M, s)
  M[0] = M[0] * s
  M[1] = M[1] * s
  M[2] = M[2] * s
  M[3] = M[3] * s
  return M
end

local function muls2_3 (M, s)
  return create2_3(
    M[0] * s, M[3] * s,
    M[1] * s, M[4] * s,
    M[2] * s, M[5] * s)
end

local function muls3_2 (M, s)
  return create2_3(
    M[0] * s, M[2] * s, M[4] * s,
    M[1] * s, M[3] * s, M[5] * s)
end

local function accmuls2_3 (M, s)
  M[0] = M[0] * s
  M[1] = M[1] * s
  M[2] = M[2] * s
  M[3] = M[3] * s
  M[4] = M[4] * s
  M[5] = M[5] * s
  return M
end

local accmuls3_2 = accmuls2_3

local function muls4_2 (M, s)
  return create4_2(
    M[0] * s, M[2] * s, M[4] * s, M[6] * s,
    M[1] * s, M[3] * s, M[5] * s, M[7] * s)
end

local function muls2_4 (M, s)
  return create3_4(
    M[0] * s, M[4] * s,
    M[1] * s, M[5] * s,
    M[2] * s, M[6] * s,
    M[3] * s, M[7] * s)
end

local function accmuls4_2 (M, s)
  M[0] = M[0] * s
  M[1] = M[1] * s
  M[2] = M[2] * s
  M[3] = M[3] * s
  M[4] = M[4] * s
  M[5] = M[5] * s
  M[6] = M[6] * s
  M[7] = M[7] * s
  return M
end

local accmuls2_4 = accmuls4_2

local function muls3_3 (M, s)
  return create3_3(
    M[0] * s, M[3] * s, M[6] * s,
    M[1] * s, M[4] * s, M[7] * s,
    M[2] * s, M[5] * s, M[8] * s)
end

local function accmuls3_3 (M, s)
  M[0] = M[0] * s
  M[1] = M[1] * s
  M[2] = M[2] * s
  M[3] = M[3] * s
  M[4] = M[4] * s
  M[5] = M[5] * s
  M[6] = M[6] * s
  M[7] = M[7] * s
  M[8] = M[8] * s
  return M
end

local function muls4_3 (M, s)
  return create4_3(
    M[0] * s, M[3] * s, M[6] * s, M[9] * s,
    M[1] * s, M[4] * s, M[7] * s, M[10] * s,
    M[2] * s, M[5] * s, M[8] * s, M[11] * s)
end

local function muls3_4 (M, s)
  return create3_4(
    M[0] * s, M[4] * s, M[8]  * s,
    M[1] * s, M[5] * s, M[9]  * s,
    M[2] * s, M[6] * s, M[10] * s,
    M[3] * s, M[7] * s, M[11] * s)
end

local function accmuls4_3 (M, s)
  for i = 0, 11 do M[i] = M[i] * s end
  return M
end

local accmuls3_4 = accmuls4_3

local function muls4_4 (M, s)
  return create4_4(
    M[0] * s, M[4] * s, M[8]  * s, M[12] * s,
    M[1] * s, M[5] * s, M[9]  * s, M[13] * s,
    M[2] * s, M[6] * s, M[10] * s, M[14] * s,
    M[3] * s, M[7] * s, M[11] * s, M[15] * s)
end

local function accmuls4_4 (M, s)
  for i = 0, 15 do M[i] = M[i] * s end
  return M
end

-- Division
--
-- NOTE: These implementations may or may not lead to numerical
-- instability, depending on the result of the reciprocal of s.
-- In the case that there is trouble down the road with this,
-- we will make another pass to correct the matter.

local function accdivs2_2 (M, s)
  return accmuls2_2(M, 1 / s)
end

local function accdivs2_3 (M, s)
  return accmuls2_3(M, 1 / s)
end

local accdivs3_2 = accdivs2_3

local function accdivs2_4 (M, s)
  return accmuls2_4(M, 1 / s)
end

local accdivs4_2 = accdivs2_4

local function accdivs3_3 (M, s)
  return accmuls3_3(M, 1 / s)
end

local function accdivs3_4 (M, s)
  return accmuls3_4(M, 1 / s)
end

local accdivs4_3 = accdivs3_4

local function accdivs4_4 (M, s)
  return accmuls4_4(M, 1 / s)
end

local function divs2_2 (M, s)
  return muls2_2(M, 1 / s)
end

local function divs2_3 (M, s)
  return muls2_3(M, 1 / s)
end

local divs3_2 = divs2_3

local function divs2_4 (M, s)
  return muls2_4(M, 1 / s)
end

local divs4_2 = divs2_4

local function divs3_3 (M, s)
  return muls3_3(M, 1 / s)
end

local function divs3_4 (M, s)
  return muls3_4(M, 1 / s)
end

local divs4_3 = divs3_4

local function divs4_4 (M, s)
  return muls4_4(M, 1 / s)
end

------------------
-- Matrix Minor --
------------------

local function minor_mn (M, m, n, _i, _j)
  local mm1, nm1 = m - 1, n - 1
  local R = ffi.new(typeof_sarray(mm1*nm1))

  for j = 0, _j - 1 do
    for i = 0, _i - 1 do
      R[j + i*nm1] = M[j + i*n]
    end
    for i = _i + 1, mm1 do
      R[j + (i - 1)*nm1] = M[j + i*n]
    end
  end
  for j = _j + 1, nm1 do
    for i = 0, _i - 1 do
      R[j - 1 + i*nm1] = M[j - 1 + i*n]
    end
    for i = _i + 1, mm1 do
      R[j - 1 + (i - 1)*nm1] = M[j - 1 + i*n]
    end
  end

  return R
end

-- 2 column
local function minor2_2 (M, i, j)
  return minor_mn (M, 2, 2, i, j)
end

local function minor2_3 (M, i, j)
  return minor_mn (M, 2, 3, i, j)
end

local function minor2_4 (M, i, j)
  return minor_mn (M, 2, 4, i, j)
end

-- 3 column
local function minor3_2 (M, i, j)
  return minor_mn (M, 3, 2, i, j)
end

local function minor3_3 (M, i, j)
  return minor_mn (M, 3, 3, i, j)
end

local function minor3_4 (M, i, j)
  return minor_mn (M, 3, 4, i, j)
end

-- 4 column
local function minor4_2 (M, i, j)
  return minor_mn (M, 4, 2, i, j)
end

local function minor4_3 (M, i, j)
  return minor_mn (M, 4, 3, i, j)
end

local function minor4_4 (M, i, j)
  return minor_mn (M, 4, 4, i, j)
end

------------------------
-- Matrix Determinant --
------------------------

-- For now this is easy Laplace formula. If lots of
-- matrix crunching becomes neccessary, we may use
-- a better algorithm.

local function det2_2 (M)
  return M[0]*M[3] - M[2]*M[1]
end

local function det_mm (M, m)
  if m == 2 then return det2_2(M) else
    local m2 = m * m

    local dm = ffi.new(typeof_sarray(m2))
    local sign = 1
    for i = 0, m - 1 do
      r = r + sign*M[i*m]*det_mm(minor_mn(M, m, m, i, 0), m - 1)
      sign = -sign
    end
  end
end

local function det3_3 (M)
  -- | a b c |
  -- | d e f |
  -- | g h k |
  --
  -- a * det(e h; f k) - b * det(d g; f k) + c * det(d g; e h)
  local dm = zero2_2()

  local r
  r = r + M[0]*det2_2(minor3_3 (M, 0, 0))
  r = r - M[3]*det2_2(minor3_3 (M, 1, 0))
  r = r + M[6]*det2_2(minor3_3 (M, 2, 0))
  return r
end

local function det4_4 (M)
  -- | a b c d |
  -- | e f g h |
  -- | k l m o |
  -- | p q r s |
  --
  -- a * det(f l q; g m r; h o s) - b * det(e k p; g m r; h o s) + c * det(e k p; f l q; h o s) - d * det(e k p; f l q; g m r)
  local dm = zero3_3()

  local r
  r = r + M[0]*det3_3(minor4_4(M, 0, 0))
  r = r - M[4]*det3_3(minor4_4(M, 1, 0))
  r = r + M[8]*det3_3(minor4_4(M, 2, 0))
  r = r - M[12]*det3_3(minor4_4(M, 3, 0))
  return r
end

-----------------------------------
-- Triangular Matrix Determinant --
-----------------------------------

-- In the special case of a triangular matrix,
-- the determinant is simply the product of the
-- diagonal.

local function det_triangular2_2 (M)
  return M[0] * M[3]
end

local function det_triangular3_3 (M)
  return M[0] * M[4] * M[8]
end

local function det_triangular4_4 (M)
  return M[0] * M[5] * M[10] * M[15]
end

---------------------
-- Matrix Negation --
---------------------

local function set_neg_mn (M, m, n)
  local dim = m * n
  for i = 0, dim - 1 do M[i] = -M[i] end
  return R
end

local function neg_mn (M, m, n)
  local dim = m * n
  local R = ffi.new(typeof_sarray(dim))
  for i = 0, dim - 1 do R[i] = -M[i] end
  return R
end

local function set_neg2_2 (M) return set_neg_mn(M, 2, 2) end
local function set_neg2_3 (M) return set_neg_mn(M, 2, 3) end
local function set_neg2_4 (M) return set_neg_mn(M, 2, 4) end

local function set_neg3_2 (M) return set_neg_mn(M, 3, 2) end
local function set_neg3_3 (M) return set_neg_mn(M, 3, 3) end
local function set_neg3_4 (M) return set_neg_mn(M, 3, 4) end

local function set_neg4_2 (M) return set_neg_mn(M, 4, 2) end
local function set_neg4_3 (M) return set_neg_mn(M, 4, 3) end
local function set_neg4_4 (M) return set_neg_mn(M, 4, 4) end


local function neg2_2 (M) return neg_mn(M, 2, 2) end
local function neg2_3 (M) return neg_mn(M, 2, 3) end
local function neg2_4 (M) return neg_mn(M, 2, 4) end

local function neg3_2 (M) return neg_mn(M, 3, 2) end
local function neg3_3 (M) return neg_mn(M, 3, 3) end
local function neg3_4 (M) return neg_mn(M, 3, 4) end

local function neg4_2 (M) return neg_mn(M, 4, 2) end
local function neg4_3 (M) return neg_mn(M, 4, 3) end
local function neg4_4 (M) return neg_mn(M, 4, 4) end


---------------------
-- Matrix Addition --
---------------------

local function accadd_mn (M, N, m, n)
  local dim = m * n
  for i = 0, dim - 1 do
    M[i] = M[i] + N[i]
  end
  return M
end

local function add_mn (M, N, m, n)
  local dim = m * n
  local R = ffi.new(typeof_sarray(dim))
  for i = 0, dim - 1 do
    R[i] = M[i] + N[i]
  end
  return R
end

-- 2 column, accumulate
local function accadd4_2 (M, N)
  return accadd_mn (M, N, 2, 2)
end

local function accadd4_3 (M, N)
  return accadd_mn (M, N, 2, 3)
end

local function accadd4_4 (M, N)
  return accadd_mn (M, N, 2, 4)
end

-- 3 column, accumulate
local function accadd4_2 (M, N)
  return accadd_mn (M, N, 3, 2)
end

local function accadd4_3 (M, N)
  return accadd_mn (M, N, 3, 3)
end

local function accadd4_4 (M, N)
  return accadd_mn (M, N, 3, 4)
end

-- 4 column, accumulate
local function accadd4_2 (M, N)
  return accadd_mn (M, N, 4, 2)
end

local function accadd4_3 (M, N)
  return accadd_mn (M, N, 4, 3)
end

local function accadd4_4 (M, N)
  return accadd_mn (M, N, 4, 4)
end

-- 2 column
local function add4_2 (M, N)
  return add_mn (M, N, 2, 2)
end

local function add4_3 (M, N)
  return add_mn (M, N, 2, 3)
end

local function add4_4 (M, N)
  return add_mn (M, N, 2, 4)
end

-- 3 column
local function add4_2 (M, N)
  return add_mn (M, N, 3, 2)
end

local function add4_3 (M, N)
  return add_mn (M, N, 3, 3)
end

local function add4_4 (M, N)
  return add_mn (M, N, 3, 4)
end

-- 4 column
local function add4_2 (M, N)
  return add_mn (M, N, 4, 2)
end

local function add4_3 (M, N)
  return add_mn (M, N, 4, 3)
end

local function add4_4 (M, N)
  return add_mn (M, N, 4, 4)
end

------------------------
-- Matrix Subtraction --
------------------------
--
-- NOTE The implementation introduces unneeded intermediate matrices
-- for the negative. This could be remedied in another pass.

local function accsub2_2 (M, N) return accadd4_2(M, neg2_2(N)) end
local function accsub2_3 (M, N) return accadd4_3(M, neg2_3(N)) end
local function accsub2_4 (M, N) return accadd4_4(M, neg2_4(N)) end

local function accsub3_2 (M, N) return accadd4_2(M, neg3_2(N)) end
local function accsub3_3 (M, N) return accadd4_3(M, neg3_3(N)) end
local function accsub3_4 (M, N) return accadd4_4(M, neg3_4(N)) end

local function accsub4_2 (M, N) return accadd4_2(M, neg4_2(N)) end
local function accsub4_3 (M, N) return accadd4_3(M, neg4_3(N)) end
local function accsub4_4 (M, N) return accadd4_4(M, neg4_4(N)) end

local function sub2_2 (M, N) return add4_2(M, neg2_2(N)) end
local function sub2_3 (M, N) return add4_3(M, neg2_3(N)) end
local function sub2_4 (M, N) return add4_4(M, neg2_4(N)) end

local function sub3_2 (M, N) return add4_2(M, neg3_2(N)) end
local function sub3_3 (M, N) return add4_3(M, neg3_3(N)) end
local function sub3_4 (M, N) return add4_4(M, neg3_4(N)) end

local function sub4_2 (M, N) return add4_2(M, neg4_2(N)) end
local function sub4_3 (M, N) return add4_3(M, neg4_3(N)) end
local function sub4_4 (M, N) return add4_4(M, neg4_4(N)) end

---------------------------
-- Matrix Multiplication --
---------------------------
--
-- The implementation consists of a general implementation for matrices
-- of user defined size, and a list of wrappers for the supported sizes.
-- The reason for doing this is brevity. That, and when one calls the
-- wrapper, constants are propagated through the mul_mn_pq function such
-- that it can be optimized heavily on a case-by-case basis by the dynamic
-- assembler.

-- General case matrix multiplication.
local function mul_mn_pq (M, N, m, n, p, q)
  -- let M be a matrix of dimension m*n
  -- let N be a matrix of dimension p*q
  -- result is of dimension p*n

  --assert(m == q, 'row/col mismatch')

  --local rowM = ffi.new(typeof_sarray(m))

  local R = ffi.new(typeof_sarray(p*n))

  for j = 0, p - 1 do
    for i = 0, n - 1 do
      local xij = 0
      for k = 0, m - 1 do
        xij = xij + M[i + k*n] * N[j*p + k]
      end
      R[i + j*n] = xij
    end
  end

  return R
end

-- 2 outer
local function mul2_2 (M, N)
  return mul_mn_pq(M, N, 2, 2, 2, 2)
end

local function mul2_2_3_2 (M, N)
  return mul_mn_pq(M, N, 2, 2, 3, 2)
end

local function mul2_2_4_2 (M, N)
  return mul_mn_pq(M, N, 2, 2, 4, 2)
end


local function mul2_3_2_2 (M, N)
  return mul_mn_pq(M, N, 2, 3, 2, 2)
end

local function mul2_3_3_2 (M, N)
  return mul_mn_pq(M, N, 2, 3, 3, 2)
end

local function mul2_3_4_2 (M, N)
  return mul_mn_pq(M, N, 2, 3, 4, 2)
end


local function mul2_4_2_2 (M, N)
  return mul_mn_pq(M, N, 2, 4, 2, 2)
end

local function mul2_4_3_2 (M, N)
  return mul_mn_pq(M, N, 2, 4, 3, 2)
end

local function mul2_4_4_2 (M, N)
  return mul_mn_pq(M, N, 2, 4, 4, 2)
end

-- 3 outer
local function mul3_2_2_3 (M, N)
  return mul_mn_pq(M, N, 3, 2, 2, 3)
end

local function mul3_2_3_3 (M, N)
  return mul_mn_pq(M, N, 3, 2, 3, 3)
end

local function mul3_2_4_3 (M, N)
  return mul_mn_pq(M, N, 3, 2, 4, 3)
end


local function mul3_3_2_3 (M, N)
  return mul_mn_pq(M, N, 3, 3, 2, 3)
end

local function mul3_3 (M, N)
  return mul_mn_pq(M, N, 3, 3, 3, 3)
end

local function mul3_3_4_3 (M, N)
  return mul_mn_pq(M, N, 3, 3, 4, 3)
end


local function mul3_4_2_3 (M, N)
  return mul_mn_pq(M, N, 3, 4, 2, 3)
end

local function mul3_4_3_3 (M, N)
  return mul_mn_pq(M, N, 3, 4, 3, 3)
end

local function mul3_4_4_3 (M, N)
  return mul_mn_pq(M, N, 3, 4, 4, 3)
end

-- 4 outer
local function mul4_2_2_4 (M, N)
  return mul_mn_pq(M, N, 4, 2, 2, 4)
end

local function mul4_2_3_4 (M, N)
  return mul_mn_pq(M, N, 4, 2, 3, 4)
end

local function mul4_2_4_4 (M, N)
  return mul_mn_pq(M, N, 4, 2, 4, 4)
end


local function mul4_3_2_4 (M, N)
  return mul_mn_pq(M, N, 4, 3, 2, 4)
end

local function mul4_3_3_4 (M, N)
  return mul_mn_pq(M, N, 4, 3, 3, 4)
end

local function mul4_3_4_4 (M, N)
  return mul_mn_pq(M, N, 4, 3, 4, 4)
end


local function mul4_4_2_4 (M, N)
  return mul_mn_pq(M, N, 4, 4, 2, 4)
end

local function mul4_4_3_4 (M, N)
  return mul_mn_pq(M, N, 4, 4, 3, 4)
end

local function mul4_4 (M, N)
  return mul_mn_pq(M, N, 4, 4, 4, 4)
end

----------------------------------
-- Column Vector Multiplication --
----------------------------------

-- 2 column, vector 2
local function mul2_2_v2 (M, V)
  return mul_mn_pq (M, V, 2, 2, 1, 2)
end

local function mul2_3_v2 (M, V)
  return mul_mn_pq (M, V, 2, 3, 1, 2)
end

local function mul2_4_v2 (M, V)
  return mul_mn_pq (M, V, 2, 4, 1, 2)
end

-- 3 column, vector 3
local function mul3_2_v3 (M, V)
  return mul_mn_pq (M, V, 3, 2, 1, 3)
end

local function mul3_3_v3 (M, V)
  return mul_mn_pq (M, V, 3, 3, 1, 3)
end

local function mul3_4_v3 (M, V)
  return mul_mn_pq (M, V, 3, 4, 1, 3)
end

-- 4 column, vector 4
local function mul4_2_v4 (M, V)
  return mul_mn_pq (M, V, 4, 2, 1, 4)
end

local function mul4_3_v4 (M, V)
  return mul_mn_pq (M, V, 4, 3, 1, 4)
end

local function mul4_4_v4 (M, V)
  return mul_mn_pq (M, V, 4, 4, 1, 4)
end

--------------------------
-- Vector Outer Product --
--------------------------

local function outermul_m(u, v, m)
  return mul_mn_pq (u, v, m, 1, 1, m)
end

local function outermul2 (u, v)
  return outermul_m (u, v, 2)
end

local function outermul3 (u, v)
  return outermul_m (u, v, 3)
end

local function outermul4 (u, v)
  return outermul_m (u, v, 4)
end

---------------------------------
-- Minors, Cofactors, Adjugate --
---------------------------------

local function minorsof_mm (M, m)
  local dim = m * m
  local mm1 = m - 1
  local minors = ffi.new(typeof_sarray(dim))

  for j = 0, mm1 do
    for i = 0, mm1 do
      minors[i*m + j] = det_mm (minor_mn (M, i, j), mm1)
    end
  end
end

local function cofactors_mm (M, m)
  local mo2 = m / 2
  local minors = minorsof_mm(M, m)
  local sflip = false

  if math.floor (mo2) ~= mo2 then
    for i = 0, m * m - 1 do
      if sflip then minors[i] = -minors[i] end
      sflip = not sflip
    end

    return minors
  else -- even size, need an extra flip
    local i = 0
    for ii = 0, m - 1 do
      for jj = 0, m - 1 do
        if sflip then minors[i] = -minors[i] end
        sflip = not sflip
        i = i + 1
      end
      sflip = not sflip
    end

    return minors
  end
end

local tftrans = {
  [2] = transpose2_2,
  [3] = transpose3_3,
  [4] = transpose4_4
}

local tfmaccmuls = {
  [2] = accmuls2_2,
  [3] = accmuls3_3,
  [4] = accmuls4_4
}

local function adjugate_mm (M, m)
  return tftrans[m] (cofactors_mm(M, m))
end

----------------------
-- Matrix Inversion --
----------------------

local function invert2_2 (M)
  local det = det2_2 (M)

  if not within_epsilon(det) then
    M[0], M[3] = M[3], -M[0]
    M[1], M[2] = -M[1], M[2]

    return accmuls2_2(M, 1 / det)
  end
end

local function invert_mm (M, m)
  if m == 2 then return invert2_2 (M) else
    local det = det_mm (M, m)
    
    if not within_epsilon(det) then
      return tfmaccmuls[m] (adjugate_mm (M, m), 1 / det)
    end
  end
end

local function invert3_3 (M) return invert_mm (M, 3) end
local function invert4_4 (M) return invert_mm (M, 4) end

--------------------------------
-- Perspective Transformation --
--------------------------------
--
-- The following matrices transform a set of 3D points and vectors with a
-- perspective transformation, based upon a given frustum.
--
-- The frustum* family directly specify the bounding planes of the frustum, and
-- so they can be used to realize an asymmetrical view frustum, which may be
-- especially useful for the purpose of projection mapping using a projector
-- with built-in correction, or in some cases, using a projector in combination
-- with special lenses. For example, tabletop projectors often have a
-- projection frustum with a bottom plane parallel to the ground, so that the
-- bottom half of the image is not cut off when placing the projector away from
-- the edge of the table.
--
-- On the other hand, the perspective* family are for representing undistorted
-- eye-space, which is typically desirable in the case that a 3D perspective
-- visual is represented on an ordinary flat rectangular display.  These
-- functions accept a y-FOV (field of view on the Y axis) in radians, and an
-- aspect ratio (which gives enough information to know the x-FOV as well.
--
-- PRECISION AND VARIATION NOTES
--
-- On standard graphics hardware, the precision of the depth buffer (where the
-- depth values of accepted fragments are stored) is directly effected by the
-- distance between the near plane (zN) and the far plane (zF). Roughly, if
-- r = zN*zF, then log_2(r) bits of precision are lost. Because
-- lim r → ∞ as lim zN → 0, zN must never be 0.
--
-- Some researchers have noted the value and ease of eliminating the far
-- plane from the perspective equations[cit-robustshadowvol]. The approach
-- involves simply evaluating the perspective matrix as lim zF → ∞. This
-- takes the equation relating depth value (zD) to eye distance (zE) from
--
--   zD = (zE*(zF + zN) + 2*zF*zN) / (zE*(zF + zN))
--
-- to give us the equation
--
--   zD = (zE + 2*zN) / zE
--
-- and, as a result, the computation is simpler. Moreover, the precision
-- improvement is also desirable and naturally, one need not worry as much
-- about ensuring their scene fits within a closed finite bounding volume.
-- This improvement came in response to the desire for stencil buffer
-- based shadows, which are projected by objects that are extremely far away
-- from point or spot light sources.
--
-- In particular, as can be seen from the last equation above, the normalized
-- depth no longer reaches a finite maximum. Instead, lim zE → -∞ as lim zD → 1.
-- The loss of precision is thus proportionate to eye distance in the infinite
-- perspective projection.
--
-- NOTE ON NOMENCLATURE
--
-- Some game programmers incorrectly refer to the perspective matrix as a
-- projection matrix. It transforms from 3D eye (or world) space to 3D clip
-- space. While there are parallels (lots of parallels) to the physical
-- practice of video image projection such as in a theater or the art of
-- projection mapping which we are interested in automating, it is not a true
-- mathematical projection.
--
-- If it were, the information would _lose a rank_, and the result would be
-- that no depth information would be retained! In clip space, we still
-- remember depth, but we have simply distorted the points so that when
-- orthogonally positioned on the screen they appear to be corrected for
-- perspective (roughly, they approach the center of the screen tangentially).
-- Viewing clip space from the outside reveals that this distortion does not
-- discard any information.
--

-- Uniform Frustum Projection
-- 
local function perspective4_4 (fovy, aspect, zN, zF)
  local halffovy = fovy * 0.5
  local f = _cos (halffovy) / _sin (halffovy)
  local zNmFinv = 1 / (zN - zF) -- this result must be negative

  return create4_4 (
		f * (1 / aspect), 0,               0,                 0,
		0,                f,               0,                 0,
		0,                0, (zF+zN)*zNmFinv, (2*zF*zN)*zNmFinv,
		0,                0,              -1,                 0)
end

-- Uniform Infinite Frustum Projection
local function perspective_inf4_4 (fovy, aspect, zN)
  local halffovy = fovy * 0.5
  local f = _cos (halffovy) / _sin (halffovy)
  local zN2 = 2 * zN

  local R = f * zN
  local r = R * aspect
  local l, b, t = -r, -R, R

	return create4_4 (
		zN2 / (r - l), 0,             0,    0,
		0,             zN2 / (t - b), 0,    0,
		0,             0,             1,    1,
	 	0,             0,          -zN2,    0)
end

-- Frustum Projection
local function frustum4_4 (l, r, b, t, zN, zF)
  local two_n = 2 * zN
  local two_f_n = zF * two_n
  local r_minus_l = r - l
  local r_plus_l = r + l
  local t_plus_b = t + b
  local t_minus_b = t - b
  local f_plus_n = zF + zN
  local f_minus_n = zF - zN
  
  return create4_4 (
		two_n/r_minus_l, 0,                r_plus_l/r_minus_l, 0,
		0,               two_n/t_minus_b,  t_plus_b/t_minus_b, 0,
		0,               0,               -f_plus_n/f_minus_n, -two_f_n/f_minus_n,
		0,               0,               -1,                  0)
end

-- Infinite Frustum Projection
local function frustum_inf4_4 (l, r, b, t, zN, zF)
  local two_n = 2 * zN
  local r_minus_l = r - l
  local r_plus_l = r + l
  local t_plus_b = t + b
  local t_minus_b = t - b
  local f_plus_n = zF + zN
  local f_minus_n = zF - zN
  
  return create4_4 (
		two_n/r_minus_l, 0,                r_plus_l/r_minus_l, 0,
		0,               two_n/t_minus_b,  t_plus_b/t_minus_b, 0,
		0,               0,               -1,                  -two_n,
		0,               0,               -1,                  0)
end

