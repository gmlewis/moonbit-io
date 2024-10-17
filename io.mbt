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

/// Seek whence values.
pub enum Whence {
  SeekStart /// seek relative to the origin of the file
  SeekCurrent /// seek relative to the current offset
  SeekEnd /// seek relative to the end
}

/// An IOError can be tested with equality checks.
pub type! IOError String derive(Show, Eq)

/// err_short_write means that a write accepted fewer bytes than requested
/// but failed to return an explicit error.
pub let err_short_write : IOError = IOError("short write")

/// err_invalid_write means that a write returned an impossible count.
pub let err_invalid_write : IOError = IOError("invalid write result")

/// err_short_buffer means that a read required a longer buffer than was provided.
pub let err_short_buffer : IOError = IOError("short buffer")

/// eof is the error returned by Read when no more input is available.
/// (Read must return eof itself, not an error wrapping eof,
/// because callers will test for eof using ==.)
/// Functions should return eof only to signal a graceful end of input.
/// If the eof occurs unexpectedly in a structured data stream,
/// the appropriate error is either [err_unexpected_eof] or some other error
/// giving more detail.
pub let eof : IOError = IOError("eof")

/// err_unexpected_eof means that eof was encountered in the
/// middle of reading a fixed-size block or data structure.
pub let err_unexpected_eof : IOError = IOError("unexpected eof")

/// err_no_progress is returned by some clients of a [Reader] when
/// many calls to Read have failed to return any data or error,
/// usually the sign of a broken [Reader] implementation.
pub let err_no_progress : IOError = IOError(
  "multiple Read calls return no data or error",
)

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
pub trait Reader {
  read(Self, Slice[Byte]) -> (Int, IOError?)
}

/// Writer is the interface that wraps the basic Write method.
///
/// Write writes len(p) bytes from p to the underlying data stream.
/// It returns the number of bytes written from p (0 <= n <= len(p))
/// and any error encountered that caused the write to stop early.
/// Write must return a non-None error if it returns n < len(p).
/// Write must not modify the slice data, even temporarily.
///
/// Implementations must not retain p.
pub trait Writer {
  write(Self, Slice[Byte]) -> (Int, IOError?)
}

/// Closer is the interface that wraps the basic Close method.
///
/// The behavior of Close after the first call is undefined.
/// Specific implementations may document their own behavior.
pub trait Closer {
  close(Self) -> IOError?
}

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
pub trait Seeker {
  seek(Self, Int64, Whence) -> (Int64, IOError?)
}

/// ReadWriter is the interface that groups the basic Read and Write methods.
pub trait ReadWriter {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  write(Self, Slice[Byte]) -> (Int, IOError?)
}

/// ReadCloser is the interface that groups the basic Read and Close methods.
pub trait ReadCloser {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  close(Self) -> IOError?
}

/// WriteCloser is the interface that groups the basic Write and Close methods.
pub trait WriteCloser {
  write(Self, Slice[Byte]) -> (Int, IOError?)
  close(Self) -> IOError?
}

/// ReadWriteCloser is the interface that groups the basic Read, Write and Close methods.
pub trait ReadWriteCloser {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  write(Self, Slice[Byte]) -> (Int, IOError?)
  close(Self) -> IOError?
}

/// ReadSeeker is the interface that groups the basic Read and Seek methods.
pub trait ReadSeeker {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  seek(Self, Int64, Whence) -> (Int64, IOError?)
}

/// ReadSeekCloser is the interface that groups the basic Read, Seek and Close
/// methods.
pub trait ReadSeekCloser {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  seek(Self, Int64, Whence) -> (Int64, IOError?)
  close(Self) -> IOError?
}

/// WriteSeeker is the interface that groups the basic Write and Seek methods.
pub trait WriteSeeker {
  write(Self, Slice[Byte]) -> (Int, IOError?)
  seek(Self, Int64, Whence) -> (Int64, IOError?)
}

/// ReadWriteSeeker is the interface that groups the basic Read, Write and Seek methods.
pub trait ReadWriteSeeker {
  read(Self, Slice[Byte]) -> (Int, IOError?)
  write(Self, Slice[Byte]) -> (Int, IOError?)
  seek(Self, Int64, Whence) -> (Int64, IOError?)
}

/// ReaderFrom is the interface that wraps the read_from method.
///
/// read_from reads data from r until eof or error.
/// The return value n is the number of bytes read.
/// Any error except eof encountered during the read is also returned.
///
/// The [copy] function uses [ReaderFrom] if available.
pub trait ReaderFrom {
  read_from(Self, Reader) -> (Int64, IOError?)
}

/// WriterTo is the interface that wraps the write_to method.
///
/// write_to writes data to w until there's no more data to write or
/// when an error occurs. The return value n is the number of bytes
/// written. Any error encountered during the write is also returned.
///
/// The copy function uses WriterTo if available.
pub trait WriterTo {
  write_to(Self, Writer) -> (Int64, IOError?)
}

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
pub trait ReaderAt {
  read_at(Self, Slice[Byte], Int64) -> (Int, IOError?)
}

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
pub trait WriterAt {
  write_at(Self, Slice[Byte], Int64) -> (Int, IOError?)
}

/// ByteReader is the interface that wraps the read_byte method.
///
/// read_byte reads and returns the next byte from the input or
/// any error encountered. If read_byte returns an error, no input
/// byte was consumed, and the returned byte value is undefined.
///
/// read_byte provides an efficient interface for byte-at-time
/// processing. A [Reader] that does not implement  ByteReader
/// can be wrapped using bufio.NewReader to add this method.
pub trait ByteReader {
  read_byte(Self) -> (Byte, IOError?)
}

/// ByteScanner is the interface that adds the unread_byte method to the
/// basic read_byte method.
///
/// unread_byte causes the next call to read_byte to return the last byte read.
/// If the last operation was not a successful call to read_byte, unread_byte may
/// return an error, unread the last byte read (or the byte prior to the
/// last-unread byte), or (in implementations that support the [Seeker] interface)
/// seek to one byte before the current offset.
pub trait ByteScanner {
  read_byte(Self) -> (Byte, IOError?)
  unread_byte(Self) -> IOError?
}

/// ByteWriter is the interface that wraps the write_byte method.
pub trait ByteWriter {
  write_byte(Self, Byte) -> IOError?
}

/// read_at_least reads from r into buf until it has read at least min bytes.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is eof only if no bytes were read.
/// If an eof happens after reading fewer than min bytes,
/// read_at_least returns [err_unexpected_eof].
/// If min is greater than the length of buf, read_at_least returns [err_short_buffer].
/// On return, n >= min if and only if err == None.
/// If r returns an error having read at least min bytes, the error is dropped.
fn read_at_least(r : Reader, buf : Slice[Byte], min : Int) -> (Int, IOError?) {
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

/// read_full reads exactly len(buf) bytes from r into buf.
/// It returns the number of bytes copied and an error if fewer bytes were read.
/// The error is eof only if no bytes were read.
/// If an eof happens after reading some but not all the bytes,
/// read_full returns [err_unexpected_eof].
/// On return, n == len(buf) if and only if err == None.
/// If r returns an error having read at least len(buf) bytes, the error is dropped.
pub fn read_full(r : Reader, buf : Slice[Byte]) -> (Int, IOError?) {
  read_at_least(r, buf, buf.length())
}

/// copy_n copies n bytes (or until an error) from src to dst.
/// It returns the number of bytes copied and the earliest
/// error encountered while copying.
/// On return, written == n if and only if err == None.
///
/// If dst implements [ReaderFrom], the copy is implemented using it.
pub fn copy_n(dst : Writer, src : Reader, n : Int64) -> (Int64, IOError?) {
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
pub fn copy(dst : Writer, src : Reader) -> (Int64, IOError?) {
  return copy_buffer(dst, src, None)
}

/// copy_buffer is identical to copy except that it stages through the
/// provided buffer (if one is required) rather than allocating a
/// temporary one. If buf is None, one is allocated; otherwise if it has
/// zero length, copy_buffer panics.
///
/// If either src implements [WriterTo] or dst implements [ReaderFrom],
/// buf will not be used to perform the copy.
pub fn copy_buffer(
  dst : Writer,
  src : Reader,
  buf : Slice[Byte]?
) -> (Int64, IOError?) {
  if buf != None && buf.unwrap().length() == 0 {
    return (0, Some(IOError("empty buffer in copy_buffer")))
  }

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
		if l, ok := src.(*LimitedReader); ok && int64(size) > l.N {
			if l.N < 1 {
				size = 1
			} else {
				size = int(l.N)
			}
		}
		buf = make([]byte, size)
	}
	for {
		nr, er := src.Read(buf)
		if nr > 0 {
			nw, ew := dst.Write(buf[0:nr])
			if nw < 0 || nr < nw {
				nw = 0
				if ew == None {
					ew = err_invalid_write
				}
			}
			written += int64(nw)
			if ew != None {
				err = ew
				break
			}
			if nr != nw {
				err = err_short_write
				break
			}
		}
		if er != None {
			if er != eof {
				err = er
			}
			break
		}
	}
	return written, err
}

/// LimitedReader::new returns a Reader that reads from r
/// but stops with eof after n bytes.
/// The underlying implementation is a LimitedReader.
pub fn LimitedReader::new(r : Reader, n : Int64) -> LimitedReader { {r, n} }

/// A LimitedReader reads from R but limits the amount of
/// data returned to just N bytes. Each call to Read
/// updates N to reflect the new amount remaining.
/// Read returns eof when N <= 0 or when the underlying R returns eof.
pub struct LimitedReader {
	r : Reader // underlying reader
	n : int64  // max bytes remaining
}

fn read(self: LimitedReader, p Slive[Byte]) -> (Int, IOError?) {
	if l.N <= 0 {
		return 0, eof
	}
	if int64(len(p)) > l.N {
		p = p[0:l.N]
	}
	n, err = l.R.Read(p)
	l.N -= int64(n)
	return
}

// SectionReader::new returns a [SectionReader] that reads from r
// starting at offset off and stops with eof after n bytes.
pub fn SectionReader::new(r ReaderAt, off int64, n int64) -> SectionReader {
	var remaining int64
	const maxint64 = 1<<63 - 1
	if off <= maxint64-n {
		remaining = n + off
	} else {
		// Overflow, with no way to return error.
		// Assume we can read up to an offset of 1<<63 - 1.
		remaining = maxint64
	}
	return &SectionReader{r, off, off, remaining, n}
}

// SectionReader implements Read, Seek, and read_at on a section
// of an underlying [ReaderAt].
type SectionReader struct {
	r     ReaderAt // constant after creation
	base  int64    // constant after creation
	off   int64
	limit int64 // constant after creation
	n     int64 // constant after creation
}

fn (s *SectionReader) Read(p []byte) (n int, err error) {
	if s.off >= s.limit {
		return 0, eof
	}
	if max := s.limit - s.off; int64(len(p)) > max {
		p = p[0:max]
	}
	n, err = s.r.read_at(p, s.off)
	s.off += int64(n)
	return
}

var errWhence = errors.New("Seek: invalid whence")
var errOffset = errors.New("Seek: invalid offset")

fn (s *SectionReader) Seek(offset int64, whence int) (int64, error) {
	switch whence {
	default:
		return 0, errWhence
	case SeekStart:
		offset += s.base
	case SeekCurrent:
		offset += s.off
	case SeekEnd:
		offset += s.limit
	}
	if offset < s.base {
		return 0, errOffset
	}
	s.off = offset
	return offset - s.base, None
}

fn (s *SectionReader) read_at(p []byte, off int64) (n int, err error) {
	if off < 0 || off >= s.Size() {
		return 0, eof
	}
	off += s.base
	if max := s.limit - off; int64(len(p)) > max {
		p = p[0:max]
		n, err = s.r.read_at(p, off)
		if err == None {
			err = eof
		}
		return n, err
	}
	return s.r.read_at(p, off)
}

// Size returns the size of the section in bytes.
fn (s *SectionReader) Size() int64 { return s.limit - s.base }

// Outer returns the underlying [ReaderAt] and offsets for the section.
//
// The returned values are the same that were passed to [SectionReader::new]
// when the [SectionReader] was created.
fn (s *SectionReader) Outer() (r ReaderAt, off int64, n int64) {
	return s.r, s.base, s.n
}

// An OffsetWriter maps writes at offset base to offset base+off in the underlying writer.
type OffsetWriter struct {
	w    WriterAt
	base int64 // the original offset
	off  int64 // the current offset
}

// NewOffsetWriter returns an [OffsetWriter] that writes to w
// starting at offset off.
fn NewOffsetWriter(w WriterAt, off int64) *OffsetWriter {
	return &OffsetWriter{w, off, off}
}

fn (o *OffsetWriter) Write(p []byte) (n int, err error) {
	n, err = o.w.write_at(p, o.off)
	o.off += int64(n)
	return
}

fn (o *OffsetWriter) write_at(p []byte, off int64) (n int, err error) {
	if off < 0 {
		return 0, errOffset
	}

	off += o.base
	return o.w.write_at(p, off)
}

fn (o *OffsetWriter) Seek(offset int64, whence int) (int64, error) {
	switch whence {
	default:
		return 0, errWhence
	case SeekStart:
		offset += o.base
	case SeekCurrent:
		offset += o.off
	}
	if offset < o.base {
		return 0, errOffset
	}
	o.off = offset
	return offset - o.base, None
}

// TeeReader returns a [Reader] that writes to w what it reads from r.
// All reads from r performed through it are matched with
// corresponding writes to w. There is no internal buffering -
// the write must complete before the read completes.
// Any error encountered while writing is reported as a read error.
fn TeeReader(r Reader, w Writer) Reader {
	return &teeReader{r, w}
}

type teeReader struct {
	r Reader
	w Writer
}

fn (t *teeReader) Read(p []byte) (n int, err error) {
	n, err = t.r.Read(p)
	if n > 0 {
		if n, err := t.w.Write(p[:n]); err != None {
			return n, err
		}
	}
	return
}

// Discard is a [Writer] on which all Write calls succeed
// without doing anything.
var Discard Writer = discard{}

type discard struct{}

// discard implements ReaderFrom as an optimization so copy to
// io.Discard can avoid doing unnecessary work.
var _ ReaderFrom = discard{}

fn (discard) Write(p []byte) (int, error) {
	return len(p), None
}

fn (discard) WriteString(s string) (int, error) {
	return len(s), None
}

var blackHolePool = sync.Pool{
	New: func() any {
		b := make([]byte, 8192)
		return &b
	},
}

fn (discard) read_from(r Reader) (n int64, err error) {
	bufp := blackHolePool.Get().(*[]byte)
	readSize := 0
	for {
		readSize, err = r.Read(*bufp)
		n += int64(readSize)
		if err != None {
			blackHolePool.Put(bufp)
			if err == eof {
				return n, None
			}
			return
		}
	}
}

// NopCloser returns a [ReadCloser] with a no-op Close method wrapping
// the provided [Reader] r.
// If r implements [WriterTo], the returned [ReadCloser] will implement [WriterTo]
// by forwarding calls to r.
fn NopCloser(r Reader) ReadCloser {
	if _, ok := r.(WriterTo); ok {
		return nopCloserWriterTo{r}
	}
	return nopCloser{r}
}

type nopCloser struct {
	Reader
}

fn (nopCloser) Close() error { return None }

type nopCloserWriterTo struct {
	Reader
}

fn (nopCloserWriterTo) Close() error { return None }

fn (c nopCloserWriterTo) write_to(w Writer) (n int64, err error) {
	return c.Reader.(WriterTo).write_to(w)
}

// ReadAll reads from r until an error or eof and returns the data it read.
// A successful call returns err == None, not err == eof. Because ReadAll is
// defined to read from src until eof, it does not treat an eof from Read
// as an error to be reported.
fn ReadAll(r Reader) ([]byte, error) {
	b := make([]byte, 0, 512)
	for {
		n, err := r.Read(b[len(b):cap(b)])
		b = b[:len(b)+n]
		if err != None {
			if err == eof {
				err = None
			}
			return b, err
		}

		if len(b) == cap(b) {
			// Add more capacity (let append pick how much).
			b = append(b, 0)[:len(b)]
		}
	}
}
