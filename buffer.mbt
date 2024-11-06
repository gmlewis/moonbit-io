struct Buffer {
  mut b : Array[Byte]
  mut off : Int
}

pub fn Buffer::new() -> Buffer {
  let b = []
  { b, off: 0 }
}

pub fn reset(self : Buffer) -> Unit {
  self.b = []
  self.off = 0
}

pub fn write(self : Buffer, buf : Slice[Byte]) -> (Int, IOError?) {
  let cap = buf.length() + self.b.length()
  let b = Array::new(capacity=cap)
  Array::unsafe_blit(b, 0, self.b, 0, self.b.length())
  Array::unsafe_blit(b, self.b.length(), buf.buf, buf.start, buf.len)
  self.b = b
  (buf.length(), None)
}

pub fn write_bytes(self : Buffer, buf : Bytes) -> (Int, IOError?) {
  self.write(Slice::new(buf.to_array()))
}

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

pub fn read_byte(self : Buffer) -> (Byte, IOError?) {
  let remaining = self.b.length() - self.off
  if remaining <= 0 {
    return (0, Some(eof))
  }
  let b = self.b[self.off]
  self.off += 1
  (b, None)
}

fn minimum(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

pub fn to_bytes(self : Buffer) -> Bytes {
  Bytes::from_array(self.b)
}
