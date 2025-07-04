// This file is based on the Go implementation found here:
// https://cs.opensource.google/go/go/+/refs/tags/go1.23.2:src/io/io.go
// which has the copyright notice:
// copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

/// Package io provides basic interfaces to I/O primitives.
/// Its primary job is to wrap existing implementations of such primitives,
/// such as those in package os, into shared public interfaces that
/// abstract the functionality, plus some other related primitives.
///
/// Because these interfaces and primitives wrap lower-level operations with
/// various implementations, unless otherwise informed clients should not
/// assume they are safe for parallel execution.

///|
/// Seek whence values.
pub(all) enum Whence {
  /// seek relative to the origin of the file
  SeekStart
  /// seek relative to the current offset
  SeekCurrent
  /// seek relative to the end
  SeekEnd
}

///|
/// An IOError can be tested with equality checks.
pub(all) suberror IOError String derive(Show, Eq)

///|
/// err_short_write means that a write accepted fewer bytes than requested
/// but failed to return an explicit error.
pub let err_short_write : IOError = IOError("short write")

///|
/// err_invalid_write means that a write returned an impossible count.
pub let err_invalid_write : IOError = IOError("invalid write result")

///|
/// err_short_buffer means that a read required a longer buffer than was provided.
pub let err_short_buffer : IOError = IOError("short buffer")

///|
/// eof is the error returned by Read when no more input is available.
/// (Read must return eof itself, not an error wrapping eof,
/// because callers will test for eof using ==.)
/// Functions should return eof only to signal a graceful end of input.
/// If the eof occurs unexpectedly in a structured data stream,
/// the appropriate error is either [err_unexpected_eof] or some other error
/// giving more detail.
pub let eof : IOError = IOError("eof")

///|
/// err_unexpected_eof means that eof was encountered in the
/// middle of reading a fixed-size block or data structure.
pub let err_unexpected_eof : IOError = IOError("unexpected eof")

///|
/// err_no_progress is returned by some clients of a [Reader] when
/// many calls to Read have failed to return any data or error,
/// usually the sign of a broken [Reader] implementation.
pub let err_no_progress : IOError = IOError(
  "multiple Read calls return no data or error",
)

///|
/// Reader is the interface that wraps the basic Read method.
///
/// Read reads up to len(p) bytes into p. It returns the number of bytes
/// read (0 <= n <= len(p)) and any error encountered. Even if Read
/// returns n < len(p), it may use all of p as scratch space during the call.
/// If some data is available but not len(p) bytes, Read conventionally
/// returns what is available instead of waiting for more.
///
/// When Read encounters an error or end-of-file condition after
/// successfully reading n > 0 bytes, it returns the number of
/// bytes read. It may return the (non-None) error from the same call
/// or return the error (and n == 0) from a subsequent call.
/// An instance of this general case is that a Reader returning
/// a non-zero number of bytes at the end of the input stream may
/// return either err == eof or err == None. The next Read should
/// return 0, eof.
///
/// Callers should always process the n > 0 bytes returned before
/// considering the error err. Doing so correctly handles I/O errors
/// that happen after reading some bytes and also both of the
/// allowed eof behaviors.
///
/// If len(p) == 0, Read should always return n == 0. It may return a
/// non-None error if some error condition is known, such as eof.
///
/// Implementations of Read are discouraged from returning a
/// zero byte count with a None error, except when len(p) == 0.
/// Callers should treat a return of 0 and None as indicating that
/// nothing happened; in particular it does not indicate eof.
///
/// Implementations must not retain p.
pub(open) trait Reader {
  read(Self, Slice[Byte]) -> (Int, IOError?)
}

///|
/// Writer is the interface that wraps the basic Write method.
///
/// Write writes len(p) bytes from p to the underlying data stream.
/// It returns the number of bytes written from p (0 <= n <= len(p))
/// and any error encountered that caused the write to stop early.
/// Write must return a non-None error if it returns n < len(p).
/// Write must not modify the slice data, even temporarily.
///
/// Implementations must not retain p.
pub(open) trait Writer {
  write(Self, Slice[Byte]) -> (Int, IOError?)
}

///|
/// Closer is the interface that wraps the basic Close method.
///
/// The behavior of Close after the first call is undefined.
/// Specific implementations may document their own behavior.
pub(open) trait Closer {
  close(Self) -> IOError?
}

///|
/// Seeker is the interface that wraps the basic Seek method.
///
/// Seek sets the offset for the next Read or Write to offset,
/// interpreted according to whence:
/// [SeekStart] means relative to the start of the file,
/// [SeekCurrent] means relative to the current offset, and
/// [SeekEnd] means relative to the end
/// (for example, offset = -2 specifies the penultimate byte of the file).
/// Seek returns the new offset relative to the start of the
/// file or an error, if any.
///
/// Seeking to an offset before the start of the file is an error.
/// Seeking to any positive offset may be allowed, but if the new offset exceeds
/// the size of the underlying object the behavior of subsequent I/O operations
/// is implementation-dependent.
pub(open) trait Seeker {
  seek(Self, Int64, Whence) -> (Int64, IOError?)
}

///|
/// ReadWriter is the interface that groups the basic Read and Write methods.
pub(open) trait ReadWriter: Reader + Writer {}

///|
/// ReadCloser is the interface that groups the basic Read and Close methods.
pub(open) trait ReadCloser: Reader + Closer {}

///|
/// WriteCloser is the interface that groups the basic Write and Close methods.
pub(open) trait WriteCloser: Writer + Closer {}

///|
/// ReadWriteCloser is the interface that groups the basic Read, Write and Close methods.
pub(open) trait ReadWriteCloser: Reader + Writer + Closer {}

///|
/// ReadSeeker is the interface that groups the basic Read and Seek methods.
pub(open) trait ReadSeeker: Reader + Seeker {}

///|
/// ReadSeekCloser is the interface that groups the basic Read, Seek and Close
/// methods.
pub(open) trait ReadSeekCloser: Reader + Seeker + Closer {}

///|
/// WriteSeeker is the interface that groups the basic Write and Seek methods.
pub(open) trait WriteSeeker: Writer + Seeker {}

///|
/// ReadWriteSeeker is the interface that groups the basic Read, Write and Seek methods.
pub(open) trait ReadWriteSeeker: Reader + Writer + Seeker {}

///|
/// ReaderFrom is the interface that wraps the read_from method.
///
/// read_from reads data from r until eof or error.
/// The return value n is the number of bytes read.
/// Any error except eof encountered during the read is also returned.
///
/// The [copy] function uses [ReaderFrom] if available.
pub(open) trait ReaderFrom {
  read_from(Self, &Reader) -> (Int64, IOError?)
}

///|
/// WriterTo is the interface that wraps the write_to method.
///
/// write_to writes data to w until there's no more data to write or
/// when an error occurs. The return value n is the number of bytes
/// written. Any error encountered during the write is also returned.
///
/// The copy function uses WriterTo if available.
pub(open) trait WriterTo {
  write_to(Self, &Writer) -> (Int64, IOError?)
}

///|
/// ReaderAt is the interface that wraps the basic read_at method.
///
/// read_at reads len(p) bytes into p starting at offset off in the
/// underlying input source. It returns the number of bytes
/// read (0 <= n <= len(p)) and any error encountered.
///
/// When read_at returns n < len(p), it returns a non-None error
/// explaining why more bytes were not returned. In this respect,
/// read_at is stricter than Read.
///
/// Even if read_at returns n < len(p), it may use all of p as scratch
/// space during the call. If some data is available but not len(p) bytes,
/// read_at blocks until either all the data is available or an error occurs.
/// In this respect read_at is different from Read.
///
/// If the n = len(p) bytes returned by read_at are at the end of the
/// input source, read_at may return either err == eof or err == None.
///
/// If read_at is reading from an input source with a seek offset,
/// read_at should not affect nor be affected by the underlying
/// seek offset.
///
/// Clients of read_at can execute parallel read_at calls on the
/// same input source.
///
/// Implementations must not retain p.
pub(open) trait ReaderAt {
  read_at(Self, Slice[Byte], Int64) -> (Int, IOError?)
}

///|
/// WriterAt is the interface that wraps the basic write_at method.
///
/// write_at writes len(p) bytes from p to the underlying data stream
/// at offset off. It returns the number of bytes written from p (0 <= n <= len(p))
/// and any error encountered that caused the write to stop early.
/// write_at must return a non-None error if it returns n < len(p).
///
/// If write_at is writing to a destination with a seek offset,
/// write_at should not affect nor be affected by the underlying
/// seek offset.
///
/// Clients of write_at can execute parallel write_at calls on the same
/// destination if the ranges do not overlap.
///
/// Implementations must not retain p.
pub(open) trait WriterAt {
  write_at(Self, Slice[Byte], Int64) -> (Int, IOError?)
}

///|
/// ByteReader is the interface that wraps the read_byte method.
///
/// read_byte reads and returns the next byte from the input or
/// any error encountered. If read_byte returns an error, no input
/// byte was consumed, and the returned byte value is undefined.
///
/// read_byte provides an efficient interface for byte-at-time
/// processing. A [Reader] that does not implement  ByteReader
/// can be wrapped using bufio.NewReader to add this method.
pub(open) trait ByteReader {
  read_byte(Self) -> (Byte, IOError?)
}

///|
/// ByteScanner is the interface that adds the unread_byte method to the
/// basic read_byte method.
///
/// unread_byte causes the next call to read_byte to return the last byte read.
/// If the last operation was not a successful call to read_byte, unread_byte may
/// return an error, unread the last byte read (or the byte prior to the
/// last-unread byte), or (in implementations that support the [Seeker] interface)
/// seek to one byte before the current offset.
pub(open) trait ByteScanner: ByteReader {
  unread_byte(Self) -> IOError?
}

///|
/// ByteWriter is the interface that wraps the write_byte method.
pub(open) trait ByteWriter {
  write_byte(Self, Byte) -> IOError?
}

///|
/// read_at_least reads from r into buf until it has read at least min bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is eof only if no bytes were read.
/// If an eof happens after reading fewer than min bytes,
/// read_at_least returns [err_unexpected_eof].
/// If min is greater than the length of buf, read_at_least returns [err_short_buffer].
/// On return, n >= min if and only if err == None.
/// If r returns an error having read at least min bytes, the error is dropped.
fn read_at_least(r : &Reader, buf : Slice[Byte], min : Int) -> (Int, IOError?) {
  let mut n = 0
  let mut err = None
  if buf.length() < min {
    return (0, Some(err_short_buffer))
  }
  while n < min && err == None {
    let v = r.read(buf[n:])
    n += v.0
    err = v.1
  }
  if n >= min {
    err = None
  } else if n > 0 && err == Some(eof) {
    err = Some(err_unexpected_eof)
  }
  (n, err)
}

///|
/// read_full reads exactly len(buf) bytes from r into buf.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is eof only if no bytes were read.
/// If an eof happens after reading some but not all the bytes,
/// read_full returns [err_unexpected_eof].
/// On return, n == len(buf) if and only if err == None.
/// If r returns an error having read at least len(buf) bytes, the error is dropped.
pub fn read_full(r : &Reader, buf : Slice[Byte]) -> (Int, IOError?) {
  read_at_least(r, buf, buf.length())
}

///|
/// copy_n copies n bytes (or until an error) from src to dst.
/// It returns the number of bytes copied and the earliest
/// error encountered while copying.
/// On return, written == n if and only if err == None.
///
/// If dst implements [ReaderFrom], the copy is implemented using it.
pub fn copy_n(dst : &Writer, src : &Reader, n : Int64) -> (Int64, IOError?) {
  let v = copy(dst, LimitedReader::new(src, n))
  let written = v.0
  let mut err = v.1
  if written == n {
    return (n, None)
  }
  if written < n && err == None {
    // src stopped early; must have been eof.
    err = Some(eof)
  }
  (written, err)
}

///|
/// copy copies from src to dst until either eof is reached
/// on src or an error occurs. It returns the number of bytes
/// copied and the first error encountered while copying, if any.
///
/// A successful copy returns err == None, not err == eof.
/// Because copy is defined to read from src until eof, it does
/// not treat an eof from Read as an error to be reported.
///
/// If src implements [WriterTo],
/// the copy is implemented by calling src.write_to(dst).
/// Otherwise, if dst implements [ReaderFrom],
/// the copy is implemented by calling dst.read_from(src).
pub fn copy(dst : &Writer, src : &Reader) -> (Int64, IOError?) {
  return copy_buffer(dst, src, None)
}

///|
/// copy_buffer is identical to copy except that it stages through the
/// provided buffer (if one is required) rather than allocating a
/// temporary one. If buf is None, one is allocated; otherwise if it has
/// zero length, copy_buffer panics.
///
/// If either src implements [WriterTo] or dst implements [ReaderFrom],
/// buf will not be used to perform the copy.
pub fn copy_buffer(
  dst : &Writer,
  src : &Reader,
  buf : Slice[Byte]?
) -> (Int64, IOError?) {
  if buf != None && buf.unwrap().length() == 0 {
    return (0, Some(IOError("empty buffer in copy_buffer")))
  }
  let mut buf = buf

  // TODO:
  // // If the reader has a write_to method, use it to do the copy.
  // // Avoids an allocation and a copy.
  // if wt, ok := src.(WriterTo); ok {
  // 	return wt.write_to(dst)
  // }
  // // Similarly, if the writer has a read_from method, use it to do the copy.
  // if rf, ok := dst.(ReaderFrom); ok {
  // 	return rf.read_from(src)
  // }

  //
  if buf == None {
    let size = 32 * 1024
    // TODO:
    // if l, ok := src.(*LimitedReader); ok && Int64(size) > l.N {
    // 	if l.N < 1 {
    // 		size = 1
    // 	} else {
    // 		size = int(l.N)
    // 	}
    // }
    buf = Some(Slice::new(Array::make(size, b'\x00')))
  }
  let buf = buf.unwrap()

  //
  let mut written = 0L
  let mut err = None
  for {
    let (nr, er) = src.read(buf)
    if nr > 0 {
      let (nw, ew) = dst.write(buf[:nr])
      let mut nw = nw
      let mut ew = ew
      if nw < 0 || nr < nw {
        nw = 0
        if ew == None {
          ew = Some(err_invalid_write)
        }
      }
      written += nw.to_int64()
      if ew != None {
        err = ew
        break
      }
      if nr != nw {
        err = Some(err_short_write)
        break
      }
    }
    if er != None {
      if er != Some(eof) {
        err = er
      }
      break
    }
  }
  (written, err)
}

///|
/// LimitedReader::new returns a Reader that reads from r
/// but stops with eof after n bytes.
/// The underlying implementation is a LimitedReader.
pub fn LimitedReader::new(r : &Reader, n : Int64) -> LimitedReader {
  { r, n }
}

///|
let _trait3 : &Reader = LimitedReader::new(discard, 0)

///|
/// A LimitedReader reads from R but limits the amount of
/// data returned to just N bytes. Each call to Read
/// updates N to reflect the new amount remaining.
/// Read returns eof when N <= 0 or when the underlying R returns eof.
struct LimitedReader {
  r : &Reader // underlying reader
  mut n : Int64 // max bytes remaining
}

///|
pub impl Reader for LimitedReader with read(self, p) {
  if self.n <= 0 {
    return (0, Some(eof))
  }
  let mut p = p
  if p.length().to_int64() > self.n {
    p = p[:self.n.to_int()]
  }
  let (n, err) = self.r.read(p)
  self.n -= n.to_int64()
  (n, err)
}

///|
/// SectionReader::new returns a [SectionReader] that reads from r
/// starting at offset off and stops with eof after n bytes.
pub fn SectionReader::new(
  r : &ReaderAt,
  off : Int64,
  n : Int64
) -> SectionReader {
  let mut remaining = 0L
  if off <= @int64.max_value - n {
    remaining = n + off
  } else {
    // Overflow, with no way to return error.
    // Assume we can read up to an offset of 1<<63 - 1.
    remaining = @int64.max_value
  }
  { r, base: off, off, limit: remaining, n }
}

///|
/// SectionReader implements Read, Seek, and read_at on a section
/// of an underlying [ReaderAt].
struct SectionReader {
  r : &ReaderAt // constant after creation
  base : Int64 // constant after creation
  mut off : Int64
  limit : Int64 // constant after creation
  n : Int64 // constant after creation
}

///|
pub fn SectionReader::read(
  self : SectionReader,
  p : Slice[Byte]
) -> (Int, IOError?) {
  if self.off >= self.limit {
    return (0, Some(eof))
  }
  let max = self.limit - self.off
  let mut p = p
  if p.length().to_int64() > max {
    p = p[:max.to_int()]
  }
  let (n, err) = self.r.read_at(p, self.off)
  self.off += n.to_int64()
  (n, err)
}

///|
pub let err_whence : IOError = IOError("Seek: invalid whence")

///|
pub let err_offset : IOError = IOError("Seek: invalid offset")

///|
pub fn seek(
  self : SectionReader,
  offset : Int64,
  whence : Whence
) -> (Int64, IOError?) {
  let mut offset = offset
  match whence {
    SeekStart => offset += self.base
    SeekCurrent => offset += self.off
    SeekEnd => offset += self.limit
  }
  if offset < self.base {
    return (0, Some(err_offset))
  }
  self.off = offset
  (offset - self.base, None)
}

///|
pub fn read_at(
  self : SectionReader,
  p : Slice[Byte],
  off : Int64
) -> (Int, IOError?) {
  let mut off = off
  if off < 0 || off >= self.size() {
    return (0, Some(eof))
  }
  off += self.base
  let max = self.limit - off
  let mut p = p
  if p.length().to_int64() > max {
    p = p[:max.to_int()]
    let (n, err) = self.r.read_at(p, off)
    let mut err = err
    if err == None {
      err = Some(eof)
    }
    return (n, err)
  }
  self.r.read_at(p, off)
}

///|
/// Size returns the size of the section in bytes.
fn size(self : SectionReader) -> Int64 {
  return self.limit - self.base
}

///|
/// Outer returns the underlying [ReaderAt] and offsets for the section.
///
/// The returned values are the same that were passed to [SectionReader::new]
/// when the [SectionReader] was created.
pub fn outer(self : SectionReader) -> (&ReaderAt, Int64, Int64) {
  (self.r, self.base, self.n)
}

///|
/// An OffsetWriter maps writes at offset base to offset base+off in the underlying writer.
struct OffsetWriter {
  w : &WriterAt
  base : Int64 // the original offset
  mut off : Int64 // the current offset
}

///|
/// OffsetWriter::new returns an [OffsetWriter] that writes to w
/// starting at offset off.
pub fn OffsetWriter::new(w : &WriterAt, off : Int64) -> OffsetWriter {
  { w, base: off, off }
}

///|
pub fn OffsetWriter::write(
  self : OffsetWriter,
  p : Slice[Byte]
) -> (Int, IOError?) {
  let (n, err) = self.w.write_at(p, self.off)
  self.off += n.to_int64()
  (n, err)
}

///|
pub fn write_at(
  self : OffsetWriter,
  p : Slice[Byte],
  off : Int64
) -> (Int, IOError?) {
  if off < 0 {
    return (0, Some(err_offset))
  }
  let off = off + self.base
  self.w.write_at(p, off)
}

///|
pub fn OffsetWriter::seek(
  self : OffsetWriter,
  offset : Int64,
  whence : Whence
) -> (Int64, IOError?) {
  let mut offset = offset
  match whence {
    SeekStart => offset += self.base
    SeekCurrent => offset += self.off
    _ => return (0, Some(err_whence))
  }
  if offset < self.base {
    return (0, Some(err_offset))
  }
  self.off = offset
  (offset - self.base, None)
}

///|
/// TeeReader::new returns a [Reader] that writes to w what it reads from r.
/// All reads from r performed through it are matched with
/// corresponding writes to w. There is no internal buffering -
/// the write must complete before the read completes.
/// Any error encountered while writing is reported as a read error.
pub fn TeeReader::new(r : &Reader, w : &Writer) -> TeeReader {
  { r, w }
}

///|
struct TeeReader {
  r : &Reader
  w : &Writer
}

///|
let _trait : &Reader = TeeReader::new(discard, discard)

///|
pub impl Reader for TeeReader with read(self, p) {
  let (n, err) = self.r.read(p)
  if n > 0 {
    let (n, err) = self.w.write(p[:n])
    if err != None {
      return (n, err)
    }
  }
  (n, err)
}

///|
/// discard is a [Writer] on which all Write calls succeed
/// without doing anything.
pub let discard : Discard = Discard::{  }

///|
/// `discard` satisfies the `Writer` trait.
let _discardIsWriter : &Writer = discard

///|
/// `discard` satisfies the `Reader` trait.
let _discardIsReader : &Reader = discard

///|
struct Discard {}

///|
pub impl Reader for Discard with read(_self, _b) {
  (0, Some(eof))
}

///|
/// Discard implements ReaderFrom as an optimization so copy to
/// io.Discard can avoid doing unnecessary work.
/// let _ : &ReaderFrom = discard
pub impl Writer for Discard with write(_self, p) {
  // possible compiler bug - this `pub` should not be needed here but buffer_test.mbt fails if missing.
  (p.length(), None)
}

///|
pub fn Discard::read_from(_self : Discard, r : &Reader) -> (Int64, IOError?) {
  let buf = Slice::new(Array::make(8192, b'\x00'))
  let mut n = 0L
  for {
    let v = r.read(buf)
    n += v.0.to_int64()
    let err = v.1
    if err != None {
      if err == Some(eof) {
        return (n, None)
      }
      return (n, err)
    }
  }
}

///|
/// NopCloser::new returns a [ReadCloser] with a no-op Close method wrapping
/// the provided [Reader] r.
/// If r implements [WriterTo], the returned [ReadCloser] will implement [WriterTo]
/// by forwarding calls to r.
pub fn NopCloser::new(r : &Reader) -> NopCloser {
  // TODO:
  // let _, ok := r.(WriterTo)
  // if ok {
  // 	return NopCloserWriterTo{r}
  // }
  { r, }
}

///|
/// `NopCloser` satisfies the `ReadCloser` trait.
let _NopCloser : &ReadCloser = NopCloser::new(Buffer::new())

///|
pub impl Reader for NopCloser with read(self, b) {
  self.r.read(b)
}

///|
struct NopCloser {
  r : &Reader
}

///|
pub impl Closer for NopCloser with close(_self) {
  None
}

// TODO:
// ///| NopCloserWriterTo is for internal use only. Do not make public.
// struct NopCloserWriterTo {
//   // TODO: r : &Reader
// }
//
// ///|
// fn NopCloserWriterTo::close(_self : NopCloserWriterTo) -> IOError? {
//   None
// }

// TODO:
// fn write_to(self : NopCloserWriterTo, w : &Writer) -> (Int64, IOEerror?) {
//   // return c.Reader.(WriterTo).WriteTo(w)
//   self.r.write_to(w)
// }

///|
/// read_all reads from r until an error or eof and returns the data it read.
/// A successful call returns err == None, not err == eof. Because read_all is
/// defined to read from src until eof, it does not treat an eof from Read
/// as an error to be reported.
pub fn read_all(r : &Reader) -> (Slice[Byte], IOError?) {
  let mb = 1 << 20
  let mut cap = 512
  let mut arr = Array::make(cap, b'\x00')
  let mut b = Slice::new(arr, end=0)
  for {
    let (n, err) = r.read(b[b.length():cap])
    let mut err = err
    b = b[:b.length() + n]
    if err != None {
      if err == Some(eof) {
        err = None
      }
      return (b, err)
    }
    if b.length() == cap {
      if cap < mb {
        // naive doubling of memory up until 1<<20
        cap *= 2
      } else {
        // thereafter, just add another 1<<20
        cap += mb
      }
      let new_arr = Array::new(capacity=cap)
      // Array::unsafe_blit(new_arr, 0, arr, 0, b.length())  // Doesn't work on wasm, wasm-gc, native
      for i in 0..<b.length() {
        new_arr.push(arr[i])
      }
      arr = new_arr
      b = Slice::new(arr)[:b.length()]
    }
  }
}
