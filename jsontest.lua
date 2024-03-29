local encode, decode, dkencode, dkdecode


local test_module, opt = ... -- command line argument
--local test_module = 'cmj-json'
--local test_module = 'dkjson'
--local test_module = 'dkjson-nopeg'
--local test_module = 'fleece'
--local test_module = 'jf-json'
--locel test_module = 'lua-yajl'
--local test_module = 'mp-cjson'
--local test_module = 'nm-json'
--local test_module = 'sb-json'
--local test_module = 'th-json'
test_module = test_module or 'dkjson'

--local opt = "esc" -- Test which characters in the BMP get escaped and whether this is correct
--local opt = "esc_full" -- Full range from 0 to 0x10ffff
--local opt = "esc_asc" -- Just 0 to 127

--local opt = "refcycle" -- What happens when a reference cycle gets encoded?

local testlocale = "de_DE.UTF8"

local function inlocale(fn)
  local oldloc = os.setlocale(nil, 'numeric')
  if not os.setlocale(testlocale, 'numeric') then
    print("test could not switch to locale "..testlocale)
  else
    fn()
  end
  os.setlocale(oldloc, 'numeric')
end

if test_module == 'cmj-json' then
  -- https://github.com/craigmj/json4lua/
  -- http://json.luaforge.net/
  local json = require "cmjjson" -- renamed, the original file was just 'json'
  encode = json.encode
  decode = json.decode
elseif test_module == 'dkjson' then
  -- http://chiselapp.com/user/dhkolf/repository/dkjson/
  local json = require "dkjson"
  encode = json.encode
  decode = json.decode
elseif test_module == 'dkjson-lpeg' then
  test_module = 'dkjson'
  local json = require "dkjson".use_lpeg()
  encode = json.encode
  decode = json.decode
elseif test_module == 'dkjson-lulpeg' then
  test_module = 'dkjson'
  package.loaded["lpeg"] = require "lulpeg"
  local json = require "dkjson".use_lpeg()
  encode = json.encode
  decode = json.decode
elseif test_module == 'fleece' then
  -- http://www.eonblast.com/fleece/
  local fleece = require "fleece"
  encode = function(x) return fleece.json(x, "E4") end
elseif test_module == 'jf-json' then
  -- http://regex.info/blog/lua/json
  local json = require "jfjson" -- renamed, the original file was just 'JSON'
  encode = function(x) return json:encode(x) end
  decode = function(x) return json:decode(x) end
elseif test_module == 'lua-yajl' then
  -- http://github.com/brimworks/lua-yajl
  local yajl = require ("yajl")
  encode = yajl.to_string
  decode = yajl.to_value
elseif test_module == 'mp-cjson' then
  -- http://www.kyne.com.au/~mark/software/lua-cjson.php
  local json = require "cjson"
  encode = json.encode
  decode = json.decode
elseif test_module == 'nm-json' then
  -- http://luaforge.net/projects/luajsonlib/
  local json = require "LuaJSON"
  encode = json.encode or json.stringify
  decode = json.decode or json.parse
elseif test_module == 'sb-json' then
  -- http://www.chipmunkav.com/downloads/Json.lua
  local json = require "sbjson" -- renamed, the original file was just 'Json'
  encode = json.Encode
  decode = json.Decode
elseif test_module == 'th-json' then
  -- https://github.com/harningt/luajson
  -- http://luaforge.net/projects/luajson/
  local json = require "json"
  encode = json.encode
  decode = json.decode
else
  print "No module specified"
  return
end

do
  -- http://chiselapp.com/user/dhkolf/repository/dkjson/
  local dkjson = require "dkjson"
  dkencode = dkjson.encode
  dkdecode = dkjson.decode
end

if not encode then
  print ("No encode method")
else
  local x, r

  local escapecodes = {
    ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
    ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t", ["/"] = "\\/"
  }
  local function test (x, n, expect)
    local enc = encode{ x }:match("^%s*%[%s*%\"(.-)%\"%s*%]%s*$")
    if not enc or (escapecodes[x] ~= enc
        and ("\\u%04x"):format(n) ~= enc:gsub("[A-F]", string.lower)
        and not (expect and enc:match("^"..expect.."$"))) then
      print(("U+%04X isn't encoded correctly: %q"):format(n, enc))
    end
  end

  -- necessary escapes for JSON:
  for i = 0,31 do
    test(string.char(i), i)
  end
  test("\"", ("\""):byte())
  test("\\", ("\\"):byte())
  -- necessary escapes for JavaScript:
  test("\226\128\168", 0x2028)
  test("\226\128\169", 0x2029)
  -- invalid escapes that were seen in the wild:
  test("'", ("'"):byte(), "%'")

  r,x = pcall (encode, { [1000] = "x" })
  if not r then
    print ("encoding a sparse array (#=0) raises an error:", x)
  else
    if #x > 30 then
      print ("sparse array (#=0) encoded as:", x:sub(1,15).." <...> "..x:sub(-15,-1), "#"..#x)
    else
      print ("sparse array (#=0) encoded as:", x)
    end
  end

  r,x = pcall (encode, { [1] = "a", [1000] = "x" })
  if not r then
    print ("encoding a sparse array (#=1) raises an error:", x)
  else
    if #x > 30 then
      print ("sparse array (#=1) encoded as:", x:sub(1,15).." <...> "..x:sub(-15,-1), "#str="..#x)
    else
      print ("sparse array (#=1) encoded as:", x)
    end
  end

  r,x = pcall (encode, { [1] = "a", [5] = "c", ["x"] = "x" })
  if not r then
    print ("encoding a mixed table raises an error:", x)
  else
    print ("mixed table encoded as:", x)
  end

  r, x = pcall(encode, { math.huge*0 }) -- NaN
  if not r then
    print ("encoding NaN raises an error:", x)
  else
    r = dkdecode(x)
    if not r then
      print ("NaN isn't converted into valid JSON:", x)
    elseif type(r[1]) == "number" and r[1] == r[1] then -- a number, but not NaN
      print ("NaN is converted into a valid number:", x)
    else
      print ("NaN is converted to:", x)
    end
  end

  if test_module == 'fleece' then
    print ("Fleece (0.3.1) is known to freeze on +/-Inf")
  else
    r, x = pcall(encode, { math.huge }) -- +Inf
    if not r then
      print ("encoding +Inf raises an error:", x)
    else
      r = dkdecode(x)
      if not r then
        print ("+Inf isn't converted into valid JSON:", x)
      else
        print ("+Inf is converted to:", x)
      end
    end

    r, x = pcall(encode, { -math.huge }) -- -Inf
    if not r then
      print ("encoding -Inf raises an error:", x)
    else
      r = dkdecode(x)
      if not r then
        print ("-Inf isn't converted into valid JSON:", x)
      else
        print ("-Inf is converted to:", x)
      end
    end
  end

  inlocale(function ()
    local r, x = pcall(encode, { 0.5 })
    if not r then
      print("encoding 0.5 in locale raises an error:", x)
    elseif not x:find(".", 1, true) then
      print("In locale 0.5 isn't converted into valid JSON:", x)
    end
  end)

  -- special tests for dkjson:
  if test_module == 'dkjson' then
    do -- encode a function
      local why, value, exstate
      local state = {
        exception = function (w, v, s)
          why, value, exstate = w, v, s
          return "\"demo\""
        end
      }
      local encfunction = function () end
      r, x = pcall(dkencode, { encfunction }, state )
      if not r then
        print("encoding a function with exception handler raises an error:", x)
      else
        if x ~= "[\"demo\"]" then
          print("expected to see output of exception handler for type exception, but got", x)
        end
        if why ~= "unsupported type" then
          print("expected exception reason to be 'unsupported type' for type exception")
        end
        if value ~= encfunction then
          print("expected to recieve value for type exception")
        end
        if exstate ~= state then
          print("expected to recieve state for type exception")
        end
      end

      r, x = pcall(dkencode, { function () end }, {
        exception = function (w, v, s)
          return nil, "demo"
        end
      })
      if r or x ~= "demo" then
        print("expected custom error for type exception, but got:", r, x)
      end

      r, x = pcall(dkencode, { function () end }, {
        exception = function (w, v, s)
          return nil
        end
      })
      if r or x ~= "type 'function' is not supported by JSON." then
        print("expected default error for type exception, but got:", r, x)
      end
    end

    do -- encode a reference cycle
      local why, value, exstate
      local state = {
        exception = function (w, v, s)
          why, value, exstate = w, v, s
          return "\"demo\""
        end
      }
      local a = {}
      a[1] = a
      r, x = pcall(dkencode, a, state )
      if not r then
        print("encoding a reference cycle with exception handler raises an error:", x)
      else
        if x ~= "[\"demo\"]" then
          print("expected to see output of exception handler for reference cycle exception, but got", x)
        end
        if why ~= "reference cycle" then
          print("expected exception reason to be 'reference cycle' for reference cycle exception")
        end
        if value ~= a then
          print("expected to recieve value for reference cycle exception")
        end
        if exstate ~= state then
          print("expected to recieve state for reference cycle exception")
        end
      end
    end

    do -- example exception handler
      r = dkencode(function () end, { exception = require "dkjson".encodeexception })
      if r ~= [["<type 'function' is not supported by JSON.>"]] then
        print("expected the exception encoder to encode default error message, but got", r)
      end
    end

    do -- test state buffer for custom __tojson function
      local origstate = {}
      local usedstate, usedbuffer, usedbufferlen
      dkencode({ setmetatable({}, {
        __tojson = function(self, state)
          usedstate = state
          usedbuffer = state.buffer
          usedbufferlen = state.bufferlen
          return true
        end
      }) }, origstate)
      if usedstate ~= origstate then print("expected tojson-function to recieve the original state")  end
      if type(usedbuffer) ~= 'table' or #usedbuffer < 1 then print("expected buffer in tojson-function to be an array") end
      if usedbufferlen ~= 1 then print("expected bufferlen in tojson-function to be 1, but got "..tostring(usedbufferlen)) end
    end

    do -- do not keep buffer and bufferlen when they were not present initially
      local origstate = {}
      dkencode(setmetatable({}, {__tojson = function() return true end}), origstate)
      if origstate.buffer ~= nil then print("expected buffer to be reset to nil") end
      if origstate.bufferlen ~= nil then print("expected bufferlen to be reset to nil") end
    end

    do -- keep buffer and update bufferlen when they were present initially
      local origbuffer = {}
      local origstate = { buffer = origbuffer }
      dkencode(true, origstate)
      if origstate.buffer ~= origbuffer then print("expected original buffer to remain") end
      if origstate.bufferlen ~= 1 then print("expected bufferlen to be updated") end
    end

    do -- order keys when value is 'false'
      local r = dkencode({a = false, b = true, c = true}, {keyorder = {"a", "b", "c"}})
      if r ~= [[{"a":false,"b":true,"c":true}]] then
        print("unexpected keyorder:", r)
      end
    end

    do -- error handling in ordered keys
      local r, x = pcall(dkencode, {a = false, b = function () end, c = true}, {keyorder = {"a", "b", "c"}})
      if r or x ~= "type 'function' is not supported by JSON." then
        print("expected default error for type exception, but got:", r, x)
      end
    end
  end
end

if not decode then
  print ("No decode method")
else
  local x, r

  x = decode [=[
{
  "String": "Content",
  "Integer": 26,
  "Object": {
    "String2": "Content2",
    "Boolean": true,
    "Object2": {},
    "Array": [ "Aa", "Bb", "Cc" ],
    "Integer": 42,
    "Nil": null
  }
}
]=]
  r = type(x) == 'table'
  r = r and x.String == "Content"
  r = r and x.Integer == 26
  r = r and type(x.Object) == 'table'
  r = r and x.Object.String2 == "Content2"
  r = r and x.Object.Boolean == true
  r = r and type(x.Object.Object2) == 'table'
  r = r and type(x.Object.Array) == 'table'
  r = r and x.Object.Array[3] == "Cc"
  r = r and x.Object.Integer == 42
  r = r and x.Object.Nil == nil
  if not r then
    print ("Did not decode example data correctly")
  end


  x = decode[=[ ["\u0000"] ]=]
  if x[1] ~= "\000" then
    print ("\\u0000 isn't decoded correctly")
  end

  x = decode[=[ ["\u20AC"] ]=]
  if x[1] ~= "\226\130\172" then
    print ("\\u20AC isn't decoded correctly")
  end

  x = decode[=[ ["\uD834\uDD1E"] ]=]
  if x[1] ~= "\240\157\132\158" then
    print ("\\uD834\\uDD1E isn't decoded correctly")
  end

  r, x = pcall(decode, [=[
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
{"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x": {"x":{"x":{"x":{"x":{"x":
"deep down"
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
    }    }    }    }    }     }    }    }    }    }     }    }    }    }    }
]=])

  if not r then
    print ("decoding a deep nested table raises an error:", x)
  else
    local i = 0
    while type(x) == 'table' do
      i = i + 1
      x = x.x
    end
    if i ~= 60 or x ~= "deep down" then
      print ("deep nested table isn't decoded correctly")
    end
  end

  if false and test_module == 'cmj-json' then
    -- unfortunatly the version can't be read
    print ("decoding a big array takes ages (or forever?) on cmj-json prior to version 0.9.5")
  else
    r, x = pcall(decode, "["..("0,"):rep(100000).."0]")
    if not r then
      print ("decoding a big array raises an error:", x)
    else
      if type(x) ~= 'table' or #x ~= 100001 then
        print ("big array isn't decoded correctly")
      end
    end
  end

  r, x = pcall(decode, "{}")
  if not r then
    print ("decoding an empty object raises an error:", x)
  elseif type(x) ~= 'table' then
    print ("decoding an empty object did not return a table")
  end

  r, x = pcall(decode, "{\"a\":1}")
  if not r then
    print ("decoding an object with one element raises an error:", x)
  elseif type(x) ~= 'table' or x.a ~= 1 then
    print ("decoding an object with one element did not return the expected table")
  end

  r, x = pcall(decode, "{\"a\":1,\"b\":2}")
  if not r then
    print ("decoding an object with two elements raises an error:", x)
  elseif type(x) ~= 'table' or x.a ~= 1 or x.b ~= 2 then
    print ("decoding an object with two elements did not return the expected table")
  end

  r, x = pcall(decode, "[]")
  if not r then
    print ("decoding an empty array raises an error:", x)
  elseif type(x) ~= 'table' then
    print ("decoding an empty array did not return a table")
  end

  r, x = pcall(decode, "[1e+2]")
  if not r then
    print ("decoding a number with exponential notation raises an error:", x)
  elseif x[1] ~= 1e+2 then
    print ("1e+2 decoded incorrectly:", r[1])
  end

  r, x = pcall(decode, "[1,2]")
  if not r then
    print ("decoding an array with two elements raises an error:", x)
  elseif type(x) ~= 'table' or x[1] ~= 1 or x[2] ~= 2 then
    print ("decoding an array with two elements did not return the expected table")
  end

  inlocale(function ()
    local r, x = pcall(decode, "[0.5]")
    if not r then
      print("decoding 0.5 in locale raises an error:", x)
    elseif not x then
      print("cannot decode 0.5 in locale")
    elseif x[1] ~= 0.5 then
      print("decoded 0.5 incorrectly in locale:", x[1])
    end
  end)

  -- special tests for dkjson:
  if test_module == 'dkjson' then
    x = decode[=[ [{"x":0}] ]=]
    local m = getmetatable(x)
    if not m or m.__jsontype ~= 'array' then
      print ("<metatable>.__jsontype ~= array")
    end
    local m = getmetatable(x[1])
    if not m or m.__jsontype ~= 'object' then
      print ("<metatable>.__jsontype ~= object")
    end
    
    local x,p,m = decode" invalid "
    if p ~= 2 or type(m) ~= 'string' or not m:find("at line 1, column 2$") then
      print (("Invalid location [1]: position=%d, message=%q"):format(p,m))
    end
    local x,p,m = decode" \n invalid "
    if p ~= 4 or type(m) ~= 'string' or not m:find("at line 2, column 2$") then
      print (("Invalid location [2]: position=%d, message=%q"):format(p,m))
    end
    -- report the position of the unmatched opening character instead of the
    -- position of the end of the string.
    local x,p,m = decode"[   {\"a\":\"........\""
    if type(m) ~= 'string' or not m:find("at line 1, column 5$") then
      print (("Invalid location [3]: position=%d, message=%q"):format(p,m))
    end
    local x,p,m = decode"[   [\"a\",\"........\","
    if type(m) ~= 'string' or not m:find("at line 1, column 5$") then
      print (("Invalid location [4]: position=%d, message=%q"):format(p,m))
    end
    -- report the position of the last opened object
    local x,p,m = decode"{\"x\":  {\"a\":\"........\""
    if type(m) ~= 'string' or not m:find("at line 1, column 8$") then
      print (("Invalid location [5]: position=%d, message=%q"):format(p,m))
    end
    -- report missing string for key
    local x,p,m = decode"{  {\"a\":\"........\""
    if type(m) ~= 'string' or not m:find("at line 1, column 4$") then
      print (("Invalid location [6]: position=%d, message=%q"):format(p,m))
    end
    local x,p,m = decode"[-]"
    if type(m) ~= 'string' or not m:find("at line 1, column 2$") then
      print (("Invalid location for invalid char in array: position=%d, message=%q"):format(p,m))
    end
    local x,p,m = decode"{-}"
    if type(m) ~= 'string' or not m:find("at line 1, column 2$") then
      print (("Invalid location for invalid char in object: position=%d, message=%q"):format(p,m))
    end
    local x,p,m = decode"  \"...."
    if type(m) ~= 'string' or not m:find("at line 1, column 3$") then
      print (("Invalid location for unterminated string: position=%d, message=%q"):format(p,m))
    end

    do -- single line comments
      local x, p, m  = decode [[
{"test://" // comment // --?
   : [  // continues
   0]   //
}
]]
      if type(x) ~= 'table' or type(x["test://"]) ~= 'table' or x["test://"][1] ~= 0 then
        print("could not decode a string with single line comments: "..tostring(m))
      end
    end

    do -- multi line comments
      local x, p, m  = decode [[
{"test:/*"/**//*
   hi! this is a comment
*/   : [/** / **/  0]
}
]]
      if type(x) ~= 'table' or type(x["test:/*"]) ~= 'table' or x["test:/*"][1] ~= 0 then
        print("could not decode a string with multi line comments: "..tostring(m))
      end
    end
  end
end

if encode and opt == "refcycle" then
  local a = {}
  a.a = a
  print ("Trying a reference cycle...")
  encode(a)
end

if encode and (opt or ""):sub(1,3) == "esc" then

local strchar, strbyte, strformat = string.char, string.byte, string.format
local floor = math.floor

local function unichar (value)
  if value < 0 then
    return nil
  elseif value <= 0x007f then
    return strchar (value)
  elseif value <= 0x07ff then
    return strchar (0xc0 + floor(value/0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0xffff then
    return strchar (0xe0 + floor(value/0x1000),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  elseif value <= 0x10ffff then
    return strchar (0xf0 + floor(value/0x40000),
                    0x80 + (floor(value/0x1000) % 0x40),
                    0x80 + (floor(value/0x40) % 0x40),
                    0x80 + (floor(value) % 0x40))
  else
    return nil
  end
end

local escapecodes = {
  ["\""] = "\\\"", ["\\"] = "\\\\", ["\b"] = "\\b", ["\f"] = "\\f",
  ["\n"] = "\\n",  ["\r"] = "\\r",  ["\t"] = "\\t", ["/"] = "\\/"
}

local function escapeutf8 (uchar)
  local a, b, c, d = strbyte (uchar, 1, 4)
  a, b, c, d = a or 0, b or 0, c or 0, d or 0
  if a <= 0x7f then
    value = a
  elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
    value = (a - 0xc0) * 0x40 + b - 0x80
  elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
    value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
  elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
    value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
  else
    return ""
  end
  if value <= 0xffff then
    return strformat ("\\u%.4x", value)
  elseif value <= 0x10ffff then
    -- encode as UTF-16 surrogate pair
    value = value - 0x10000
    local highsur, lowsur = 0xD800 + floor (value/0x400), 0xDC00 + (value % 0x400)
    return strformat ("\\u%.4x\\u%.4x", highsur, lowsur)
  else
    return ""
  end
end

  local isspecial = {}
  local unifile = io.open("UnicodeData.txt")
  if unifile then
    -- <http://www.unicode.org/Public/UNIDATA/UnicodeData.txt>
    -- each line consists of 15 parts for each defined codepoints
    local pat = {}
    for i = 1,14 do
      pat[i] = "[^;]*;"
    end
    pat[1] = "([^;]*);" -- Codepoint
    pat[3] = "([^;]*);" -- Category
    pat[15] = "[^;]*"
    pat = table.concat(pat)

    for line in unifile:lines() do
      local cp, cat = line:match(pat)
      if cat:match("^C[^so]") or cat:match("^Z[lp]") then
        isspecial[tonumber(cp, 16)] = cat
      end
    end
    unifile:close()
  end

  local x,xe

  local t = {}
  local esc = {}
  local escerr = {}
  local range
  if opt == "esc_full" then range = 0x10ffff
  elseif opt == "esc_asc" then range = 0x7f
  else range = 0xffff end

  for i = 0,range do
    t[1] = unichar(i)
    xe = encode(t)
    x = string.match(xe, "^%s*%[%s*%\"(.*)%\"%s*%]%s*$")
    if type(x) ~= 'string' then
      escerr[i] = xe
    elseif string.lower(x) == escapeutf8(t[1]) then
      esc[i] = 'u'
    elseif x == escapecodes[t[1]] then
      esc[i] = 'c'
    elseif x:sub(1,1) == "\\" then
      escerr[i] = xe
    end
  end
  do
    local i = 0
    while i <= range do
      local first
      while i <= range and not (esc[i] or isspecial[i]) do i = i + 1 end
      if i > range then break end
      first = i
      local special = isspecial[i]
      if esc[i] and special then
        while esc[i] and isspecial[i] == special do i = i + 1 end
        if i-1 > first then
          print (("Escaped %s characters from U+%04X to U+%04X"):format(special,first,i-1))
        else
          print (("Escaped %s character U+%04X"):format(special,first))
        end
      elseif esc[i] then
        while esc[i] and not isspecial[i] do i = i + 1 end
        if i-1 > first then
          print (("Escaped from U+%04X to U+%04X"):format(first,i-1))
        else
          if first >= 32 and first <= 127 then
            print (("Escaped U+%04X (%c)"):format(first,first))
          else
            print (("Escaped U+%04X"):format(first))
          end
        end
      elseif special then
        while not esc[i] and isspecial[i] == special do i = i + 1 end
        if i-1 > first then
          print (("Unescaped %s characters from U+%04X to U+%04X"):format(special,first,i-1))
        else
          print (("Unescaped %s character U+%04X"):format(special,first))
        end
      end
    end
  end
  do
    local i = 0
    while i <= range do
      local first
      while i <= range and not escerr[i] do i = i + 1 end
      if not escerr[i] then break end
      first = i
      while escerr[i] do i = i + 1 end
      if i-1 > first then
        print (("Errors while escaping from U+%04X to U+%04X"):format(first, i-1))
      else
        print (("Errors while escaping U+%04X"):format(first))
      end
    end
  end

end

-- Copyright (C) 2011 David Heiko Kolf
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
-- 
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
-- 
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
-- BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
-- ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE. 


