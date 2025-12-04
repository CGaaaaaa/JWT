// Base64 URL 编码实现
// 参考 RFC 4648 标准
// JWT 使用 Base64 URL-safe 编码（不带填充）

///|
/// 将索引转换为 Base64 字符
fn index_to_char(index : Int, url_safe : Bool) -> Char {
  if index < 26 {
    Int::unsafe_to_char(index + 65) // A-Z
  } else if index < 52 {
    Int::unsafe_to_char(index - 26 + 97) // a-z
  } else if index < 62 {
    Int::unsafe_to_char(index - 52 + 48) // 0-9
  } else if index == 62 {
    if url_safe {
      '-'
    } else {
      '+'
    }
  } else if url_safe {
    '_'
  } else {
    '/'
  }
}

///|
/// 将字符转换为 Base64 索引
fn char_to_index(char : Char, url_safe : Bool) -> Int {
  let code = char.to_int()
  if code >= 65 && code <= 90 {
    code - 65 // A-Z
  } else if code >= 97 && code <= 122 {
    code - 97 + 26 // a-z
  } else if code >= 48 && code <= 57 {
    code - 48 + 52 // 0-9
  } else if url_safe {
    if code == 45 {
      62
    } else {
      63
    } // '-' or '_'
  } else if code == 43 {
    62 // '+'
  } else {
    63 // '/'
  }
}

///|
/// Base64 编码器状态
priv struct Base64Encoder {
  mut i : Int
  mut buffer : Int
}

///|
/// 创建新的编码器
fn Base64Encoder::new() -> Base64Encoder {
  { i: 0, buffer: 0 }
}

///|
/// 编码字节序列到 Base64
fn Base64Encoder::encode_bytes(
  self : Base64Encoder,
  bytes : Array[Int],
  url_safe : Bool,
  padding : Bool,
) -> Array[Char] {
  let result = Array::new()
  for byte in bytes {
    match self.i % 3 {
      0 => {
        result.push(index_to_char(byte >> 2, url_safe))
        self.buffer = (byte & 0b11) << 4
      }
      1 => {
        result.push(index_to_char(self.buffer | (byte >> 4), url_safe))
        self.buffer = (byte & 0b1111) << 2
      }
      2 => {
        result.push(index_to_char(self.buffer | (byte >> 6), url_safe))
        result.push(index_to_char(byte & 0b111111, url_safe))
        self.buffer = 0
      }
      _ => ()
    }
    self.i = self.i + 1
  }

  // 处理填充
  if padding {
    match self.i % 3 {
      0 => ()
      1 => {
        result.push(index_to_char(self.buffer, url_safe))
        result.push('=')
        result.push('=')
      }
      2 => {
        result.push(index_to_char(self.buffer, url_safe))
        result.push('=')
      }
      _ => ()
    }
  } else {
    // JWT 标准：无填充模式，仍需输出最后的 buffer
    match self.i % 3 {
      0 => ()
      1 | 2 => result.push(index_to_char(self.buffer, url_safe))
      _ => ()
    }
  }
  result
}

///|
/// 将字符串转换为字节数组
fn string_to_bytes(s : String) -> Array[Int] {
  let bytes : Array[Int] = Array::new()
  for i = 0; i < s.length(); i = i + 1 {
    bytes.push(s[i])
  }
  bytes
}

///|
/// 将字符串解码为字节数组（Base64URL -> bytes）
pub fn base64url_decode_to_bytes(input : String) -> Array[Int] {
  let decoder = Base64Decoder::new()
  let chars = string_to_chars(input)
  decoder.decode_chars(chars, true)
}

///| Base64 URL 编码（不带填充，符合 JWT 标准）

///|
/// 参考 RFC 7515 Section 2
pub fn base64url_encode_str(input : String) -> String {
  let encoder = Base64Encoder::new()
  let bytes = string_to_bytes(input)
  let encoded_chars = encoder.encode_bytes(bytes, true, false)
  let mut result = ""
  for char in encoded_chars {
    result = result + char.to_string()
  }
  result
}

///|
/// Base64URL 编码字节数组
pub fn base64url_encode_bytes(bytes : Array[Int]) -> String {
  let encoder = Base64Encoder::new()
  let encoded_chars = encoder.encode_bytes(bytes, true, false)
  let mut result = ""
  for char in encoded_chars {
    result = result + char.to_string()
  }
  result
}

///|
/// 标准 Base64 编码（带填充）
pub fn base64_encode(input : String) -> String {
  let encoder = Base64Encoder::new()
  let bytes = string_to_bytes(input)
  let encoded_chars = encoder.encode_bytes(bytes, false, true)
  let mut result = ""
  for char in encoded_chars {
    result = result + char.to_string()
  }
  result
}

///|
/// Base64 解码器状态
priv struct Base64Decoder {
  mut i : Int
  mut buffer : Int
}

///|
/// 创建新的解码器
fn Base64Decoder::new() -> Base64Decoder {
  { i: 0, buffer: 0 }
}

///|
/// 解码 Base64 到字节序列
fn Base64Decoder::decode_chars(
  self : Base64Decoder,
  chars : Array[Char],
  url_safe : Bool,
) -> Array[Int] {
  let result = Array::new()
  for ch in chars {
    if ch == '=' {
      break // 遇到填充字符，停止解码
    }
    let idx = char_to_index(ch, url_safe)
    match self.i % 4 {
      0 => self.buffer = idx << 2
      1 => {
        result.push(self.buffer | (idx >> 4))
        self.buffer = (idx & 0b1111) << 4
      }
      2 => {
        result.push(self.buffer | (idx >> 2))
        self.buffer = (idx & 0b11) << 6
      }
      3 => {
        result.push(self.buffer | idx)
        self.buffer = 0
      }
      _ => ()
    }
    self.i = self.i + 1
  }
  result
}

///|
/// 将字符串转换为字符数组
fn string_to_chars(s : String) -> Array[Char] {
  let chars : Array[Char] = Array::new()
  for i = 0; i < s.length(); i = i + 1 {
    chars.push(Int::unsafe_to_char(s[i]))
  }
  chars
}

///|
/// 将字节数组转换为字符串
fn bytes_to_string(bytes : Array[Int]) -> String {
  let mut result = ""
  for byte in bytes {
    result = result + Int::unsafe_to_char(byte).to_string()
  }
  result
}

///|
/// Base64 URL 解码
pub fn base64url_decode(input : String) -> String {
  let decoder = Base64Decoder::new()
  let chars = string_to_chars(input)
  let decoded_bytes = decoder.decode_chars(chars, true)
  bytes_to_string(decoded_bytes)
}

///|
/// 标准 Base64 解码
pub fn base64_decode(input : String) -> String {
  let decoder = Base64Decoder::new()
  let chars = string_to_chars(input)
  let decoded_bytes = decoder.decode_chars(chars, false)
  bytes_to_string(decoded_bytes)
}
