///|
test "copy_json" {
  let src = Buffer::from_string("{}\r\n{extra bytes}")
  let got = copy_json(src)
  inspect(got, content="(Object({}), 2, None)")
}

///|
test "copy_json" {
  // Test basic JSON value parsing
  let buf = Buffer::from_string("42")
  let (json, bytes, err) = copy_json(buf)
  inspect(json, content="Number(42)")
  inspect(bytes, content="2")
  inspect(err, content="None")

  // Test nested JSON object
  let buf = Buffer::from_string(
    #|{"a":1,"b":true}
    ,
  )
  let (json, bytes, err) = copy_json(buf)
  inspect(
    json,
    content=
      #|Object({"a": Number(1), "b": True})
    ,
  )
  inspect(bytes, content="16")
  inspect(err, content="None")

  // Test nested JSON object with extra whitespace and UTF-8
  let buf = Buffer::from_string(
    #|
    #|{
    #|  "a": 1,
    #|  "b": true,
    #|  "utf-8": "✓ Hello, 世界! 🌍"
    #|}
    ,
  )
  let (json, bytes, err) = copy_json(buf)
  inspect(
    json,
    content=
      #|Object({"a": Number(1), "b": True, "utf-8": String("✓ Hello, 世界! 🌍")})
    ,
  )
  inspect(bytes, content="64")
  inspect(err, content="None")
}

///|
test "copy_json/invalid_json" {
  let buf = Buffer::new()
  buf.write_string("{invalid}") |> ignore()
  let (json, bytes, err) = copy_json(buf)
  inspect(json, content="Null")
  inspect(bytes, content="0")
  inspect(
    err,
    content="Some(IOError(\"invalid JSON: unexpected 'i' at offset 1\"))",
  )
}

///|
test "copy_json/empty" {
  let buf = Buffer::new()
  let (json, bytes, err) = copy_json(buf)
  inspect(json, content="Null")
  inspect(bytes, content="0")
  inspect(err, content="Some(IOError(\"invalid eof\"))")
}

///|
test "copy_json/jsonrpc2" {
  let buf = Buffer::from_string(
    #|{"jsonrpc":"2.0","method":"foo","params":[1,2,3],"id":1}
    ,
  )
  let (json, bytes, err) = copy_json(buf)
  inspect(
    json,
    content=
      #|Object({"jsonrpc": String("2.0"), "method": String("foo"), "params": Array([Number(1), Number(2), Number(3)]), "id": Number(1)})
    ,
  )
  inspect(bytes, content="56")
  inspect(err, content="None")
  //
  let buf = Buffer::from_string(
    #|{"jsonrpc":"2.0","id":1,"method":"test","params":{}}
    ,
  )
  let (json, bytes, err) = copy_json(buf)
  inspect(
    json,
    content=
      #|Object({"jsonrpc": String("2.0"), "id": Number(1), "method": String("test"), "params": Object({})})
    ,
  )
  inspect(bytes, content="52")
  inspect(err, content="None")
}
