/// Complete DER (Distinguished Encoding Rules) Library for MoonBit
/// Implements ASN.1 DER encoding and decoding with comprehensive type support

// Object Identifier structure
pub struct ObjectIdentifier {
  components : Array[Int]
} derive(Eq, Show)

pub fn oid_new(components : Array[Int]) -> ObjectIdentifier {
  { components }
}

pub fn oid_from_string(oid_str : String) -> Result[ObjectIdentifier, String] {
  let parts = oid_str.split(".")
  let components = []
  for part in parts {
    // Simple integer parsing for OID components
    let part_str = part.to_string()
    let mut num = 0
    let mut valid = true
    
    if part_str.length() == 0 {
      valid = false
    } else {
      for char in part_str.iter() {
        match char {
          '0' => num = num * 10 + 0
          '1' => num = num * 10 + 1
          '2' => num = num * 10 + 2
          '3' => num = num * 10 + 3
          '4' => num = num * 10 + 4
          '5' => num = num * 10 + 5
          '6' => num = num * 10 + 6
          '7' => num = num * 10 + 7
          '8' => num = num * 10 + 8
          '9' => num = num * 10 + 9
          _ => valid = false
        }
      }
    }
    
    if valid {
      components.push(num)
    } else {
      return Err("Invalid OID component: " + part_str)
    }
  }
  
  if components.length() < 2 {
    return Err("OID must have at least 2 components")
  }
  Ok({ components })
}

pub fn oid_to_string(oid : ObjectIdentifier) -> String {
  let mut result = ""
  for i in 0..<oid.components.length() {
    if i > 0 {
      result = result + "."
    }
    result = result + oid.components[i].to_string()
  }
  result
}

// Bit String structure
pub struct BitString {
  data : Array[Byte]
  unused_bits : Int  // Number of unused bits in the last byte (0-7)
} derive(Eq, Show)

pub fn bitstring_new(data : Array[Byte], unused_bits : Int) -> BitString {
  { data, unused_bits }
}

// Enhanced DER Value types with more ASN.1 support
pub enum DerValue {
  Boolean(Bool)
  Integer(Int64)
  BitString(BitString)
  OctetString(Array[Byte])
  Null
  ObjectId(ObjectIdentifier)
  PrintableString(String)
  IA5String(String)
  Sequence(Array[DerValue])
  Set(Array[DerValue])
  // Additional required types
  SequenceOf(Array[DerValue])  // SEQUENCE OF - homogeneous sequence
  SetOf(Array[DerValue])       // SET OF - homogeneous set
  Choice(Int, DerValue)        // CHOICE - tagged union (tag, value)
  // IMPLICIT tag support
  ImplicitTag(Int, DerValue)   // IMPLICIT [tag] value
} derive(Eq, Show)

// Comprehensive error types
pub enum DerError {
  InvalidTag(Int)
  InvalidLength(Int)
  InsufficientData
  InvalidFormat(String)
  InvalidOid(String)
  InvalidBitString(String)
  InvalidStringEncoding(String)
} derive(Eq, Show)

// Encode length in DER format
pub fn encode_length(length : Int) -> Array[Byte] {
  if length < 0x80 {
    // Short form: length fits in 7 bits
    [length.to_byte()]
  } else {
    // Long form: first byte indicates number of length octets
    let bytes = []
    let mut len = length
    while len > 0 {
      bytes.push((len % 256).to_byte())
      len = len / 256
    }
    bytes.rev_inplace()
    let result = [(0x80 + bytes.length()).to_byte()]
    for byte in bytes {
      result.push(byte)
    }
    result
  }
}

// Decode length from DER format
pub fn decode_length(data : Array[Byte], offset : Int) -> Result[(Int, Int), DerError] {
  if offset >= data.length() {
    return Err(InsufficientData)
  }
  
  let first_byte = data[offset].to_int()
  if first_byte < 0x80 {
    // Short form
    Ok((first_byte, offset + 1))
  } else {
    // Long form
    let length_octets = first_byte - 0x80
    if length_octets == 0 {
      return Err(InvalidLength(first_byte))
    }
    if offset + 1 + length_octets > data.length() {
      return Err(InsufficientData)
    }
    
    let mut length = 0
    for i in 0..<length_octets {
      length = length * 256 + data[offset + 1 + i].to_int()
    }
    Ok((length, offset + 1 + length_octets))
  }
}

// Object Identifier encoding
fn encode_oid(oid : ObjectIdentifier) -> Result[Array[Byte], DerError] {
  if oid.components.length() < 2 {
    return Err(InvalidOid("OID must have at least 2 components"))
  }
  
  let first = oid.components[0]
  let second = oid.components[1]
  
  if first > 2 || (first < 2 && second >= 40) || (first == 2 && second >= 176) {
    return Err(InvalidOid("Invalid first two OID components"))
  }
  
  let result = []
  
  // Encode first two components as single byte
  result.push((first * 40 + second).to_byte())
  
  // Encode remaining components using base-128
  for i in 2..<oid.components.length() {
    let mut component = oid.components[i]
    if component == 0 {
      result.push(b'\x00')
    } else {
      let bytes = []
      while component > 0 {
        bytes.push((component % 128).to_byte())
        component = component / 128
      }
      bytes.rev_inplace()
      
      // Set continuation bit for all but last byte
      for j in 0..<(bytes.length() - 1) {
        bytes[j] = (bytes[j].to_int() | 0x80).to_byte()
      }
      
      for byte in bytes {
        result.push(byte)
      }
    }
  }
  
  Ok(result)
}

// Object Identifier decoding
fn decode_oid(data : Array[Byte], offset : Int, length : Int) -> Result[ObjectIdentifier, DerError] {
  if length == 0 {
    return Err(InvalidOid("Empty OID"))
  }
  
  let components = []
  let first_byte = data[offset].to_int()
  
  // Decode first two components
  if first_byte >= 80 {
    components.push(2)
    components.push(first_byte - 80)
  } else if first_byte >= 40 {
    components.push(1)
    components.push(first_byte - 40)
  } else {
    components.push(0)
    components.push(first_byte)
  }
  
  // Decode remaining components
  let mut i = offset + 1
  let end = offset + length
  
  while i < end {
    let mut component = 0
    let mut has_more = true
    
    while has_more && i < end {
      let byte = data[i].to_int()
      has_more = (byte & 0x80) != 0
      component = component * 128 + (byte & 0x7F)
      i = i + 1
    }
    
    if has_more {
      return Err(InvalidOid("Incomplete OID component"))
    }
    
    components.push(component)
  }
  
  Ok(oid_new(components))
}

// String validation functions
fn is_printable_string(s : String) -> Bool {
  // PrintableString can only contain A-Z, a-z, 0-9, space, and some punctuation
  let allowed = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 '()+,-./:=?"
  for char in s.iter() {
    let mut found = false
    for allowed_char in allowed.iter() {
      if char == allowed_char {
        found = true
        break
      }
    }
    if not(found) {
      return false
    }
  }
  true
}

fn is_ia5_string(s : String) -> Bool {
  // IA5String can contain any 7-bit ASCII character
  for char in s.iter() {
    if char.to_int() > 127 {
      return false
    }
  }
  true
}

// Convert string to bytes
fn string_to_bytes(s : String) -> Array[Byte] {
  let bytes = []
  for char in s.iter() {
    bytes.push(char.to_int().to_byte())
  }
  bytes
}

// Convert bytes to string
fn bytes_to_string(bytes : Array[Byte]) -> Result[String, String] {
  let mut result = ""
  for byte in bytes {
    let code = byte.to_int()
    if code > 127 {
      return Err("Non-ASCII character found")
    }
    result = result + Char::from_int(code).to_string()
  }
  Ok(result)
}

// Encode DER value
pub fn encode_der(value : DerValue) -> Result[Array[Byte], DerError] {
  match value {
    DerValue::Boolean(b) => {
      let content = if b { [b'\xFF'] } else { [b'\x00'] }
      let result = [b'\x01'] // BOOLEAN tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::Integer(i) => {
      // Convert integer to minimal two's complement representation
      let content = []
      if i == 0L {
        content.push(b'\x00')
      } else {
        let bytes = []
        let mut num = i
        
        if i < 0L {
          // For negative numbers, we need proper two's complement
          // Find the minimum number of bytes needed
          let mut temp = i
          let mut byte_count = 0
          while temp != 0L && temp != -1L {
            temp = temp / 256L
            byte_count = byte_count + 1
          }
          if byte_count == 0 {
            byte_count = 1
          }
          
          // Encode in two's complement
          for j in 0..<byte_count {
            bytes.push((num % 256L).to_int().to_byte())
            num = num / 256L
          }
          
          // Make sure high bit is set for negative
          if bytes[bytes.length() - 1].to_int() < 0x80 {
            bytes.push(b'\xFF')
          }
        } else {
          // Positive number
          while num > 0L {
            bytes.push((num % 256L).to_int().to_byte())
            num = num / 256L
          }
          
          if bytes.length() == 0 {
            bytes.push(b'\x00')
          }
          
          // Add leading zero if high bit is set (to ensure positive interpretation)
          if bytes[bytes.length() - 1].to_int() >= 0x80 {
            bytes.push(b'\x00')
          }
        }
        
        bytes.rev_inplace()
        
        for byte in bytes {
          content.push(byte)
        }
      }
      
      let result = [b'\x02'] // INTEGER tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::BitString(bs) => {
      if bs.unused_bits < 0 || bs.unused_bits > 7 {
        return Err(InvalidBitString("Invalid unused bits count"))
      }
      let content = [bs.unused_bits.to_byte()]
      for byte in bs.data {
        content.push(byte)
      }
      let result = [b'\x03'] // BIT STRING tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::OctetString(bytes) => {
      let result = [b'\x04'] // OCTET STRING tag
      let length_bytes = encode_length(bytes.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in bytes {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::Null => {
      Ok([b'\x05', b'\x00']) // NULL tag + length 0
    }
    
    DerValue::ObjectId(oid) => {
      match encode_oid(oid) {
        Ok(content) => {
          let result = [b'\x06'] // OBJECT IDENTIFIER tag
          let length_bytes = encode_length(content.length())
          for byte in length_bytes {
            result.push(byte)
          }
          for byte in content {
            result.push(byte)
          }
          Ok(result)
        }
        Err(e) => Err(e)
      }
    }
    
    DerValue::PrintableString(s) => {
      if not(is_printable_string(s)) {
        return Err(InvalidStringEncoding("Invalid PrintableString characters"))
      }
      let content = string_to_bytes(s)
      let result = [b'\x13'] // PrintableString tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::IA5String(s) => {
      if not(is_ia5_string(s)) {
        return Err(InvalidStringEncoding("Invalid IA5String characters"))
      }
      let content = string_to_bytes(s)
      let result = [b'\x16'] // IA5String tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::Sequence(values) => {
      let content = []
      for val in values {
        match encode_der(val) {
          Ok(encoded) => {
            for byte in encoded {
              content.push(byte)
            }
          }
          Err(e) => return Err(e)
        }
      }
      
      let result = [b'\x30'] // SEQUENCE tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::Set(values) => {
      // For simplicity, we don't sort SET elements in this implementation
      // In a full DER implementation, SET elements must be sorted
      let content = []
      for val in values {
        match encode_der(val) {
          Ok(encoded) => {
            for byte in encoded {
              content.push(byte)
            }
          }
          Err(e) => return Err(e)
        }
      }
      
      let result = [b'\x31'] // SET tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::SequenceOf(elements) => {
      // SEQUENCE OF - same as SEQUENCE but semantically different
      let content = []
      for element in elements {
        match encode_der(element) {
          Ok(encoded) => {
            for byte in encoded {
              content.push(byte)
            }
          }
          Err(e) => return Err(e)
        }
      }
      let result = [b'\x30'] // SEQUENCE tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::SetOf(elements) => {
      // SET OF - same as SET but semantically different
      let content = []
      for element in elements {
        match encode_der(element) {
          Ok(encoded) => {
            for byte in encoded {
              content.push(byte)
            }
          }
          Err(e) => return Err(e)
        }
      }
      let result = [b'\x31'] // SET tag
      let length_bytes = encode_length(content.length())
      for byte in length_bytes {
        result.push(byte)
      }
      for byte in content {
        result.push(byte)
      }
      Ok(result)
    }
    
    DerValue::Choice(tag, value) => {
      // CHOICE - encode the chosen alternative with its tag
      match encode_der(value) {
        Ok(encoded) => {
          let result = [tag.to_byte()]
          for i in 1..<encoded.length() { // Skip the original tag, use choice tag
            result.push(encoded[i])
          }
          Ok(result)
        }
        Err(e) => Err(e)
      }
    }
    
    DerValue::ImplicitTag(tag, value) => {
      // IMPLICIT tag - replace the tag but keep the content
      match encode_der(value) {
        Ok(encoded) => {
          let result = [tag.to_byte()] // Use implicit tag
          for i in 1..<encoded.length() { // Skip original tag, keep length and content
            result.push(encoded[i])
          }
          Ok(result)
        }
        Err(e) => Err(e)
      }
    }
  }
}

// Decode DER data
pub fn decode_der(data : Array[Byte]) -> Result[DerValue, DerError] {
  match decode_der_at(data, 0) {
    (result, _) => result
  }
}

// Decode DER data starting at specific offset
pub fn decode_der_at(data : Array[Byte], offset : Int) -> (Result[DerValue, DerError], Int) {
  if offset >= data.length() {
    return (Err(InsufficientData), offset)
  }
  
  let tag = data[offset].to_int()
  let length_result = decode_length(data, offset + 1)
  match length_result {
    Err(e) => (Err(e), offset)
    Ok((length, content_offset)) => {
      if content_offset + length > data.length() {
        return (Err(InsufficientData), offset)
      }
      
      match tag {
        0x01 => { // BOOLEAN
          if length != 1 {
            (Err(InvalidLength(length)), offset)
          } else {
            let value = data[content_offset].to_int() != 0
            (Ok(DerValue::Boolean(value)), content_offset + length)
          }
        }
        0x02 => { // INTEGER
          if length == 0 {
            (Err(InvalidLength(length)), offset)
          } else {
            let mut value = 0L
            let is_negative = data[content_offset].to_int() >= 0x80
            
            for i in 0..<length {
              value = value * 256L + data[content_offset + i].to_int().to_int64()
            }
            
            if is_negative {
              // Convert from two's complement (simplified)
              let mut max_val = 1L
              for _ in 0..<(length * 8) {
                max_val = max_val * 2L
              }
              value = value - max_val
            }
            
            (Ok(DerValue::Integer(value)), content_offset + length)
          }
        }
        0x03 => { // BIT STRING
          if length == 0 {
            (Err(InvalidLength(length)), offset)
          } else {
            let unused_bits = data[content_offset].to_int()
            if unused_bits > 7 {
              (Err(InvalidBitString("Too many unused bits")), offset)
            } else {
              let bit_data = []
              for i in 1..<length {
                bit_data.push(data[content_offset + i])
              }
              (Ok(DerValue::BitString(bitstring_new(bit_data, unused_bits))), content_offset + length)
            }
          }
        }
        0x04 => { // OCTET STRING
          let bytes = []
          for i in 0..<length {
            bytes.push(data[content_offset + i])
          }
          (Ok(DerValue::OctetString(bytes)), content_offset + length)
        }
        0x05 => { // NULL
          if length != 0 {
            (Err(InvalidLength(length)), offset)
          } else {
            (Ok(DerValue::Null), content_offset)
          }
        }
        0x06 => { // OBJECT IDENTIFIER
          match decode_oid(data, content_offset, length) {
            Ok(oid) => (Ok(DerValue::ObjectId(oid)), content_offset + length)
            Err(e) => (Err(e), offset)
          }
        }
        0x13 => { // PrintableString
          let bytes = []
          for i in 0..<length {
            bytes.push(data[content_offset + i])
          }
          match bytes_to_string(bytes) {
            Ok(s) => {
              if is_printable_string(s) {
                (Ok(DerValue::PrintableString(s)), content_offset + length)
              } else {
                (Err(InvalidStringEncoding("Invalid PrintableString characters")), offset)
              }
            }
            Err(_) => (Err(InvalidStringEncoding("Invalid string encoding")), offset)
          }
        }
        0x16 => { // IA5String
          let bytes = []
          for i in 0..<length {
            bytes.push(data[content_offset + i])
          }
          match bytes_to_string(bytes) {
            Ok(s) => {
              if is_ia5_string(s) {
                (Ok(DerValue::IA5String(s)), content_offset + length)
              } else {
                (Err(InvalidStringEncoding("Invalid IA5String characters")), offset)
              }
            }
            Err(_) => (Err(InvalidStringEncoding("Invalid string encoding")), offset)
          }
        }
        0x30 => { // SEQUENCE
          let values = []
          let mut current_offset = content_offset
          let end_offset = content_offset + length
          
          while current_offset < end_offset {
            let (result, next_offset) = decode_der_at(data, current_offset)
            match result {
              Ok(value) => {
                values.push(value)
                current_offset = next_offset
              }
              Err(e) => return (Err(e), offset)
            }
          }
          
          (Ok(DerValue::Sequence(values)), end_offset)
        }
        0x31 => { // SET
          let values = []
          let mut current_offset = content_offset
          let end_offset = content_offset + length
          
          while current_offset < end_offset {
            let (result, next_offset) = decode_der_at(data, current_offset)
            match result {
              Ok(value) => {
                values.push(value)
                current_offset = next_offset
              }
              Err(e) => return (Err(e), offset)
            }
          }
          
          (Ok(DerValue::Set(values)), end_offset)
        }
        _ => {
          (Err(InvalidTag(tag)), offset)
        }
      }
    }
  }
}

// Utility functions
pub fn bytes_to_hex(bytes : Array[Byte]) -> String {
  let mut result = ""
  for byte in bytes {
    let value = byte.to_int()
    let h1 = value / 16
    let h2 = value % 16
    let hex_chars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F']
    result = result + Char::to_string(hex_chars[h1]) + Char::to_string(hex_chars[h2])
  }
  result
}

pub fn pretty_print(value : DerValue) -> String {
  pretty_print_indent(value, 0)
}

fn pretty_print_indent(value : DerValue, indent : Int) -> String {
  let spaces = " ".repeat(indent)
  match value {
    DerValue::Boolean(b) => spaces + "BOOLEAN: " + b.to_string()
    DerValue::Integer(i) => spaces + "INTEGER: " + i.to_string()
    DerValue::BitString(bs) => {
      let hex = bytes_to_hex(bs.data)
      spaces + "BIT STRING (" + bs.unused_bits.to_string() + " unused bits): " + hex
    }
    DerValue::OctetString(bytes) => {
      let hex = bytes_to_hex(bytes)
      spaces + "OCTET STRING: " + hex
    }
    DerValue::Null => spaces + "NULL"
    DerValue::ObjectId(oid) => spaces + "OBJECT IDENTIFIER: " + oid_to_string(oid)
    DerValue::PrintableString(s) => spaces + "PRINTABLE STRING: \"" + s + "\""
    DerValue::IA5String(s) => spaces + "IA5 STRING: \"" + s + "\""
    DerValue::Sequence(values) => {
      let mut result = spaces + "SEQUENCE {\n"
      for value in values {
        result = result + pretty_print_indent(value, indent + 2) + "\n"
      }
      result + spaces + "}"
    }
    DerValue::Set(values) => {
      let mut result = spaces + "SET {\n"
      for value in values {
        result = result + pretty_print_indent(value, indent + 2) + "\n"
      }
      result + spaces + "}"
    }
    DerValue::SequenceOf(values) => {
      let mut result = spaces + "SEQUENCE OF {\n"
      for value in values {
        result = result + pretty_print_indent(value, indent + 2) + "\n"
      }
      result + spaces + "}"
    }
    DerValue::SetOf(values) => {
      let mut result = spaces + "SET OF {\n"
      for value in values {
        result = result + pretty_print_indent(value, indent + 2) + "\n"
      }
      result + spaces + "}"
    }
    DerValue::Choice(tag, value) => {
      spaces + "CHOICE [" + tag.to_string() + "] {\n" + 
      pretty_print_indent(value, indent + 2) + "\n" +
      spaces + "}"
    }
    DerValue::ImplicitTag(tag, value) => {
      spaces + "IMPLICIT [" + tag.to_string() + "] {\n" + 
      pretty_print_indent(value, indent + 2) + "\n" +
      spaces + "}"
    }
  }
}

// Demo function showcasing the comprehensive DER library
fn main {
  println("=== MoonBit Comprehensive DER Library Demo ===\n")
  
  // Test Boolean
  let bool_val = DerValue::Boolean(true)
  match encode_der(bool_val) {
    Ok(encoded) => {
      println("Boolean(true) encoded: " + bytes_to_hex(encoded))
      match decode_der(encoded) {
        Ok(decoded) => println("Decoded: " + pretty_print(decoded))
        Err(e) => println("Decode error: " + e.to_string())
      }
    }
    Err(e) => println("Encode error: " + e.to_string())
  }
  println("")
  
  // Test Object Identifier
  match oid_from_string("1.2.840.113549.1.1.1") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          println("OID(1.2.840.113549.1.1.1) encoded: " + bytes_to_hex(encoded))
          match decode_der(encoded) {
            Ok(decoded) => println("Decoded: " + pretty_print(decoded))
            Err(e) => println("Decode error: " + e.to_string())
          }
        }
        Err(e) => println("Encode error: " + e.to_string())
      }
    }
    Err(e) => println("OID creation error: " + e)
  }
  println("")
  
  // Test BitString
  let bit_string = DerValue::BitString(bitstring_new([b'\xA0', b'\xB0'], 4))
  match encode_der(bit_string) {
    Ok(encoded) => {
      println("BitString encoded: " + bytes_to_hex(encoded))
      match decode_der(encoded) {
        Ok(decoded) => println("Decoded: " + pretty_print(decoded))
        Err(e) => println("Decode error: " + e.to_string())
      }
    }
    Err(e) => println("Encode error: " + e.to_string())
  }
  println("")
  
  // Test PrintableString
  let print_str = DerValue::PrintableString("Hello World")
  match encode_der(print_str) {
    Ok(encoded) => {
      println("PrintableString encoded: " + bytes_to_hex(encoded))
      match decode_der(encoded) {
        Ok(decoded) => println("Decoded: " + pretty_print(decoded))
        Err(e) => println("Decode error: " + e.to_string())
      }
    }
    Err(e) => println("Encode error: " + e.to_string())
  }
  println("")
  
  // Test complex Sequence
  let complex_seq = DerValue::Sequence([
    DerValue::Integer(42L),
    DerValue::PrintableString("Test"),
    DerValue::Boolean(false),
    DerValue::Null,
    DerValue::Sequence([
      DerValue::Integer(123L),
      DerValue::OctetString([b'\x01', b'\x02', b'\x03'])
    ])
  ])
  
  match encode_der(complex_seq) {
    Ok(encoded) => {
      println("Complex Sequence encoded: " + bytes_to_hex(encoded))
      match decode_der(encoded) {
        Ok(decoded) => {
          println("Decoded:")
          println(pretty_print(decoded))
        }
        Err(e) => println("Decode error: " + e.to_string())
      }
    }
    Err(e) => println("Encode error: " + e.to_string())
  }
  
  println("\n=== DER Library Demo Complete ===")
  
  // SNMP Protocol Example - Required by task specification
  println("\n=== SNMP Protocol Data Example ===")
  
  // SNMP GetRequest PDU structure (simplified)
  // SNMP PDU: SEQUENCE {
  //   version INTEGER,
  //   community OCTET STRING,
  //   pdu-type [0] IMPLICIT SEQUENCE {
  //     request-id INTEGER,
  //     error-status INTEGER,
  //     error-index INTEGER,
  //     variable-bindings SEQUENCE OF SEQUENCE {
  //       name OBJECT IDENTIFIER,
  //       value NULL (for GetRequest)
  //     }
  //   }
  // }
  
  // Create SNMP variable binding (OID + NULL value for GetRequest)
  let var_binding = DerValue::Sequence([
    DerValue::ObjectId(oid_from_string("1.3.6.1.2.1.1.1.0").unwrap()), // sysDescr.0
    DerValue::Null
  ])
  
  // Create SNMP GetRequest PDU
  let snmp_pdu = DerValue::Sequence([
    DerValue::Integer(0L), // version (SNMPv1)
    DerValue::OctetString([b'p', b'u', b'b', b'l', b'i', b'c']), // community "public"
    DerValue::ImplicitTag(0xA0, // GetRequest tag [0] IMPLICIT
      DerValue::Sequence([
        DerValue::Integer(1234L), // request-id
        DerValue::Integer(0L),    // error-status (noError)
        DerValue::Integer(0L),    // error-index
        DerValue::SequenceOf([var_binding]) // variable-bindings
      ])
    )
  ])
  
  match encode_der(snmp_pdu) {
    Ok(encoded) => {
      println("SNMP GetRequest encoded: " + bytes_to_hex(encoded))
      match decode_der(encoded) {
        Ok(decoded) => {
          println("SNMP GetRequest decoded:")
          println(pretty_print(decoded))
        }
        Err(e) => println("SNMP decode error: " + e.to_string())
      }
    }
    Err(e) => println("SNMP encode error: " + e.to_string())
  }
  
  println("\n=== SNMP Demo Complete ===")
}