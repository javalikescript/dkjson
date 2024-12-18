This is the LUA dkjson module from [http://dkolf.de/dkjson-lua](http://dkolf.de/dkjson-lua)


## Introduction

This is a JSON module written in** **[Lua](http://www.lua.org/). It supports UTF-8.

[JSON (JavaScript Object Notation)](http://www.json.org/) is a format for serializing data based on the syntax for JavaScript data structures. It is an ideal format for transmitting data between different applications and commonly used for dynamic web pages. It can also be used to save Lua data structures, but you should be aware that not every Lua table can be represented by the JSON standard. For example tables that contain both string keys and an array part cannot be exactly represented by JSON. You can solve this by putting your array data in an explicit subtable.

dkjson is written in Lua without any dependencies, but when** **[LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/) is available dkjson can use it to speed up decoding.

## Download

* [dkjson.lua](http://dkolf.de/dkjson-lua/dkjson-2.8.lua)

## Usage

The full** **[documentation including the license](http://dkolf.de/dkjson-lua/documentation) is available online on this website or as Markdown text in the readme.txt file.

dkjson is free software released under the same conditions as the Lua interpreter. Please remember to mention external code you are using in your software.

## Examples

### Encoding

```

local json = require ("dkjson")

local tbl = {
  animals = { "dog", "cat", "aardvark" },
  instruments = { "violin", "trombone", "theremin" },
  bugs = json.null,
  trees = nil
}

local str = json.encode (tbl, { indent = true })

print (str)
```

#### Output

```

{
  "bugs":null,
  "instruments":["violin","trombone","theremin"],
  "animals":["dog","cat","aardvark"]
}
```

### Decoding

```

local json = require ("dkjson")

local str = [[
{
  "numbers": [ 2, 3, -20.23e+2, -4 ],
  "currency": "\u20AC"
}
]]

local obj, pos, err = json.decode (str, 1, nil)
if err then
  print ("Error:", err)
else
  print ("currency", obj.currency)
  for i = 1,#obj.numbers do
    print (i, obj.numbers[i])
  end
end

```

#### Output

```
currency	€
1	2
2	3
3	-2023
4	-4
```


## Versions

[version detail](http://dkolf.de/dkjson-lua/readme-2.8.txt)
