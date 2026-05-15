///|
test "copy_until" {
  let src = @io.Buffer::from_string("{}\r\n{extra bytes}")
  let dst = @io.Buffer::new()
  let got = copy_until(dst, src, b'\n')
  @debug.debug_inspect(got, content="(4, None)")
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r\n"
    ),
  )
  // exact size
  let src = @io.Buffer::from_string("{}\r\n")
  let dst = @io.Buffer::new()
  let got = copy_until(dst, src, b'\n')
  @debug.debug_inspect(got, content="(4, None)")
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r\n"
    ),
  )
  // character not found
  let src = @io.Buffer::from_string("{}\r")
  let dst = @io.Buffer::new()
  let got = copy_until(dst, src, b'\n')
  @debug.debug_inspect(
    got,
    content=(
      #|(3, Some(IOError("eof")))
    ),
  )
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r"
    ),
  )
}

///|
test "copy_size" {
  let src = @io.Buffer::from_string("{}\r\n{extra bytes}")
  let dst = @io.Buffer::new()
  let got = copy_size(dst, src, 4)
  @debug.debug_inspect(got, content="(4, None)")
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r\n"
    ),
  )
  // exact size
  let src = @io.Buffer::from_string("{}\r\n")
  let dst = @io.Buffer::new()
  let got = copy_size(dst, src, 4)
  @debug.debug_inspect(got, content="(4, None)")
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r\n"
    ),
  )
  // not enough bytes
  let src = @io.Buffer::from_string("{}\r")
  let dst = @io.Buffer::new()
  let got = copy_size(dst, src, 4)
  @debug.debug_inspect(
    got,
    content=(
      #|(3, Some(IOError("eof")))
    ),
  )
  @debug.debug_inspect(
    dst.to_string(),
    content=(
      #|"{}\r"
    ),
  )
}
