test "write basic functionality" {
  let buffer = @gmlewis/io.Buffer::new()
  let input : @gmlewis/io.Slice[Byte] = @gmlewis/io.Slice::new(
    [b'A', b'B', b'C'],
  )
  let result = @gmlewis/io.write(buffer, input)
  inspect!(result, content="(3, None)")
}

test "write with different lengths" {
  let buffer = @gmlewis/io.Buffer::new()
  let short_input : @gmlewis/io.Slice[Byte] = @gmlewis/io.Slice::new([b'F'])
  let long_input : @gmlewis/io.Slice[Byte] = @gmlewis/io.Slice::new(
    [b'A', b'B', b'C', b'D', b'E'],
  )
  let short_result = @gmlewis/io.write(buffer, short_input)
  let long_result = @gmlewis/io.write(buffer, long_input)
  inspect!(short_result, content="(1, None)")
  inspect!(long_result, content="(5, None)")
}

test "write boundary test" {
  let buffer = @gmlewis/io.Buffer::new()
  let max_bytes : @gmlewis/io.Slice[Byte] = @gmlewis/io.Slice::new(
    Array::make(1024, b'A'),
  )
  let result = @gmlewis/io.write(buffer, max_bytes)
  inspect!(result, content="(1024, None)")
}

test "write random test cases" {
  let buffer1 = @gmlewis/io.Buffer::new()
  let buffer2 = @gmlewis/io.Buffer::new()
  let input : @gmlewis/io.Slice[Byte] = @gmlewis/io.Slice::new(
    [b'R', b'A', b'N', b'D', b'O', b'M'],
  )
  let result1 = @gmlewis/io.write(buffer1, input)
  let result2 = @gmlewis/io.write(buffer2, input)
  inspect!(result1, content="(6, None)")
  inspect!(result2, content="(6, None)")
}

test "boundary test: read from an empty buffer" {
  let buffer = @gmlewis/io.Buffer::new()
  let (byte, error) = @gmlewis/io.read_byte(buffer)
  inspect!(byte.to_int(), content="0")
  inspect!(error, content="Some(IOError(\"eof\"))")
}

test "convert empty Bytes" {
  let buf = @io.Buffer::new()
  let bytes = buf.to_bytes()
  assert_eq!(bytes.length(), 0)
}

test "randomized/buffer_generated the bytes should be 0" {
  for i = 0; i < 10; i = i + 1 {
    let buf = @io.Buffer::new()
    guard let (1, None) = buf.write_bytes(Bytes::from_array([b'\x00']))
    let bytes = buf.to_bytes()
    for j = 0; j < bytes.length(); j = j + 1 {
      let byte = bytes[j]
      inspect!(byte.to_int(), content="0")
    }
  }
}
