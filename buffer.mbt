///|
struct Buffer {
  mut b : Array[Byte]
  mut off : Int
}

///|
pub fn Buffer::new() -> Buffer {
  let b = []
  { b, off: 0 }
}

///|
let _trait4 : &Reader = Buffer::new()

///|
let _trait5 : &Writer = Buffer::new()

///|
pub fn Buffer::from(s : Slice[Byte]) -> Buffer {
  let b = s.to_bytes().to_array()
  { b, off: 0 }
}

///|
pub fn reset(self : Buffer) -> Unit {
  self.b = []
  self.off = 0
}

///|
pub fn write(self : Buffer, buf : Slice[Byte]) -> (Int, IOError?) {
  let blen = self.b.length()
  let buflen = buf.length()
  self.b = Array::makei(blen + buflen, fn(i) {
    if i < blen {
      self.b[i]
    } else {
      buf.buf[buf.start + i - blen]
    }
  })
  (buflen, None)
}

///|
pub fn write_bytes(self : Buffer, buf : Bytes) -> (Int, IOError?) {
  self.write(Slice::new(buf.to_array()))
}

// `write_string` converts the MoonBit UTF-16 String to UTF-8 and
// writes the bytes to the buffer.
///|
pub fn write_string(self : Buffer, s : String) -> (Int, IOError?) {
  let b = @base64.str2bytes(s)
  self.write_bytes(b)
}

///|
pub fn read(self : Buffer, buf : Slice[Byte]) -> (Int, IOError?) {
  let remaining = self.b.length() - self.off
  if remaining <= 0 || buf.length() == 0 {
    return (0, Some(eof))
  }
  let n = minimum(remaining, buf.length())
  Array::unsafe_blit(buf.buf, buf.start, self.b, self.off, n)
  self.off += n
  (n, None)
}

///|
pub fn read_byte(self : Buffer) -> (Byte, IOError?) {
  let remaining = self.b.length() - self.off
  if remaining <= 0 {
    return (0, Some(eof))
  }
  let b = self.b[self.off]
  self.off += 1
  (b, None)
}

///|
pub fn read_from(self : Buffer, r : &Reader) -> (Int64, IOError?) {
  copy(self, r)
}

///|
fn minimum(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
pub fn to_bytes(self : Buffer) -> Bytes {
  Bytes::from_array(self.b)
}

///|
pub fn to_slice(self : Buffer) -> Slice[Byte] {
  Slice::new(self.b)
}

///|
pub fn length(self : Buffer) -> Int {
  self.b.length()
}
