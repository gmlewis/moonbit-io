test "write basic functionality" {
  let buffer = @io.Buffer::new()
  let input : @io.Slice[Byte] = @io.Slice::new([b'A', b'B', b'C'])
  let result = buffer.write(input)
  inspect!(result, content="(3, None)")
}

test "write with different lengths" {
  let buffer = @io.Buffer::new()
  let short_input : @io.Slice[Byte] = @io.Slice::new([b'F'])
  let long_input : @io.Slice[Byte] = @io.Slice::new(
    [b'A', b'B', b'C', b'D', b'E'],
  )
  let short_result = buffer.write(short_input)
  let long_result = buffer.write(long_input)
  inspect!(short_result, content="(1, None)")
  inspect!(long_result, content="(5, None)")
}

test "write boundary test" {
  let buffer = @io.Buffer::new()
  let max_bytes : @io.Slice[Byte] = @io.Slice::new(Array::make(1024, b'A'))
  let result = buffer.write(max_bytes)
  inspect!(result, content="(1024, None)")
}

test "write random test cases" {
  let buffer1 = @io.Buffer::new()
  let buffer2 = @io.Buffer::new()
  let input : @io.Slice[Byte] = @io.Slice::new(
    [b'R', b'A', b'N', b'D', b'O', b'M'],
  )
  let result1 = buffer1.write(input)
  let result2 = buffer2.write(input)
  inspect!(result1, content="(6, None)")
  inspect!(result2, content="(6, None)")
}

test "boundary test: read from an empty buffer" {
  let buffer = @io.Buffer::new()
  let (byte, error) = @io.read_byte(buffer)
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

test "discard" {
  let b = @io.Buffer::from(Slice::new([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))
  guard let (10, None) = @io.copy(@io.discard, b)

}
