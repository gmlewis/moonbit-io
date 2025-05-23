///|
/// A `Slice` is a slice of an `Array`.
///
/// A separate Slice type was needed because of this issue:
/// https://github.com/moonbitlang/core/issues/1063
///
/// This struct is based on MoonBit's "ArrayView" implementation here:
/// https://github.com/moonbitlang/core/blob/main/builtin/arrayview.mbt
/// which has the following copyright:
///
/// Copyright 2024 International Digital Economy Academy
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///     http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
struct Slice[T] {
  buf : Array[T]
  start : Int
  len : Int
}

///|
/// length returns the length of the slice.
pub fn[T] Slice::length(self : Slice[T]) -> Int {
  self.len
}

///|
pub fn[T] op_get(self : Slice[T], index : Int) -> T {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index]
}

///|
pub fn[T] op_set(self : Slice[T], index : Int, value : T) -> Unit {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.buf[self.start + index] = value
}

///|
pub fn[T] swap(self : Slice[T], i : Int, j : Int) -> Unit {
  guard i >= 0 && i < self.len && j >= 0 && j < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is (\{i}, \{j})",
    )
  }
  let temp = self.buf[self.start + i]
  self.buf[self.start + i] = self.buf[self.start + j]
  self.buf[self.start + j] = temp
}

///|
pub fn[T] Slice::new(buf : Array[T], start~ : Int = 0, end? : Int) -> Slice[T] {
  let len = buf.length()
  let end = match end {
    None => len
    Some(end) => end
  }
  guard start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  Slice::{ buf, start, len: end - start }
}

///|
pub fn[T] as_array_view(self : Slice[T]) -> ArrayView[T] {
  let end = self.len + self.start
  self.buf[self.start:end]
}

///|
pub fn[T] op_as_view(self : Slice[T], start~ : Int = 0, end? : Int) -> Slice[T] {
  let len = self.buf.length()
  let end = match end {
    None => self.len
    Some(end) => end
  }
  guard self.start + start >= 0 && start <= end && end <= len else {
    abort("View start index out of bounds")
  }
  Slice::{ buf: self.buf, start: self.start + start, len: end - start }
}

///|
/// cap returns the total capacity of the slice regardless of the current length.
pub fn[T] cap(self : Slice[T]) -> Int {
  self.buf.length() - self.start
}

///|
/// append appends `s` to the end of the slice, reallocating the underlying
/// array if necessary, then returns the new slice.
pub fn[T] append(self : Slice[T], s : Slice[T]) -> Slice[T] {
  let remaining = self.cap() - self.length()
  if remaining >= s.length() {
    // plenty of room, reuse current internal Array.
    let idx = self.start + self.len
    for i in 0..<s.length() {
      self.buf[idx + i] = s[i]
    }
    return { buf: self.buf, start: self.start, len: self.len + s.length() }
  }
  // reallocate array, copy the data, then return the new slice
  let arr = Array::new(capacity=self.length() + s.length())
  let idx = self.length()
  for i in 0..<idx {
    arr.push(self.buf[i + self.start])
  }
  for i in 0..<s.length() {
    arr.push(s.buf[i + s.start])
  }
  { buf: arr, start: 0, len: self.length() + s.length() }
}

///|
/// push appends `e` to the end of the slice, reallocating the underlying
/// array if necessary, then returns the new slice.
pub fn[T] push(self : Slice[T], e : T) -> Slice[T] {
  self.append(Slice::new([e]))
}

///|
pub fn[A] iter(self : Slice[A]) -> Iter[A] {
  Iter::new(fn(yield_fn) {
    for i = 0; i < self.len; i = i + 1 {
      let v = self.buf[self.start + i]
      guard yield_fn(v) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
pub fn[A] iter2(self : Slice[A]) -> Iter2[Int, A] {
  Iter2::new(fn(yield_fn) {
    for i = 0; i < self.len; i = i + 1 {
      let v = self.buf[self.start + i]
      guard yield_fn(i, v) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
/// Fold out values from an Slice according to certain rules.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].fold(init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn[A, B] fold(self : Slice[A], init~ : B, f : (B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an Slice according to certain rules in reversed turn.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_fold(init=0, fn { sum, elem => sum + elem })
/// sum // 15
/// ```
pub fn[A, B] rev_fold(self : Slice[A], init~ : B, f : (B, A) -> B) -> B {
  for i = self.length() - 1, acc = init; i >= 0; {
    continue i - 1, f(acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an Slice according to certain rules with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].foldi(init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn[A, B] foldi(self : Slice[A], init~ : B, f : (Int, B, A) -> B) -> B {
  for i = 0, acc = init; i < self.length(); {
    continue i + 1, f(i, acc, self[i])
  } else {
    acc
  }
}

///|
/// Fold out values from an Slice according to certain rules in reversed turn with index.
///
/// # Example
/// ```
/// let sum = [1, 2, 3, 4, 5][:].rev_foldi(~init=0, fn { index, sum, elem => sum + index })
/// sum // 10
/// ```
pub fn[A, B] rev_foldi(self : Slice[A], init~ : B, f : (Int, B, A) -> B) -> B {
  let len = self.length()
  for i = len - 1, acc = init; i >= 0; {
    continue i - 1, f(len - i - 1, acc, self[i])
  } else {
    acc
  }
}

///|
pub impl[X : Show] Show for Slice[X] with output(self, logger) {
  logger.write_iter(self.iter())
}

// pub fn Slice::to_string[X : Show](self : Slice[X]) -> String {
//   Show::to_string(self)
// }

///|
pub fn[T] rev_inplace(self : Slice[T]) -> Unit {
  let mid_len = self.length() / 2
  for i = 0; i < mid_len; i = i + 1 {
    let j = self.length() - i - 1
    self.swap(i, j)
  }
}

///|
pub fn[T] each(self : Slice[T], f : (T) -> Unit) -> Unit {
  for i = 0; i < self.length(); i = i + 1 {
    f(self[i])
  }
}

///|
/// Compares two slices for equality.
pub impl[T : Eq] Eq for Slice[T] with op_equal(self, other) {
  guard self.length() == other.length() else { return false }
  for i = 0 {
    // CR: format issue
    if i >= self.length() {
      break true
    }
    if self[i] != other[i] {
      break false
    }
    continue i + 1
  }
}

///|
/// to_bytes returns slice as Bytes.
pub fn Slice::to_bytes(self : Slice[Byte]) -> Bytes {
  Bytes::from_iter(self.iter())
}
