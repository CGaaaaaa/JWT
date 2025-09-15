test "boolean encoding and decoding" {
  let bool_true = DerValue::Boolean(true)
  match encode_der(bool_true) {
    Ok(encoded) => {
      if encoded != [b'\x01', b'\x01', b'\xFF'] {
        fail("Boolean true encoding failed")
      }
      
      match decode_der(encoded) {
        Ok(DerValue::Boolean(true)) => ()
        _ => fail("Boolean true decoding failed")
      }
    }
    Err(_) => fail("Boolean true encoding failed")
  }
  
  let bool_false = DerValue::Boolean(false)
  match encode_der(bool_false) {
    Ok(encoded_false) => {
      if encoded_false != [b'\x01', b'\x01', b'\x00'] {
        fail("Boolean false encoding failed")
      }
      
      match decode_der(encoded_false) {
        Ok(DerValue::Boolean(false)) => ()
        _ => fail("Boolean false decoding failed")
      }
    }
    Err(_) => fail("Boolean false encoding failed")
  }
}

test "integer encoding and decoding" {
  let int_val = DerValue::Integer(42L)
  match encode_der(int_val) {
    Ok(encoded) => {
      if encoded != [b'\x02', b'\x01', b'\x2A'] {
        fail("Integer 42 encoding failed")
      }
      
      match decode_der(encoded) {
        Ok(DerValue::Integer(value)) => {
          if value != 42L {
            fail("Integer 42 decoding failed")
          }
        }
        _ => fail("Integer 42 decoding failed")
      }
    }
    Err(_) => fail("Integer 42 encoding failed")
  }
  
  // Test zero
  let zero_val = DerValue::Integer(0L)
  match encode_der(zero_val) {
    Ok(encoded_zero) => {
      if encoded_zero != [b'\x02', b'\x01', b'\x00'] {
        fail("Integer 0 encoding failed")
      }
      
      match decode_der(encoded_zero) {
        Ok(DerValue::Integer(value)) => {
          if value != 0L {
            fail("Integer 0 decoding failed")
          }
        }
        _ => fail("Integer 0 decoding failed")
      }
    }
    Err(_) => fail("Integer 0 encoding failed")
  }
  
  // Test negative integer
  let neg_val = DerValue::Integer(-42L)
  match encode_der(neg_val) {
    Ok(encoded_neg) => {
      match decode_der(encoded_neg) {
        Ok(DerValue::Integer(value)) => {
          if value != -42L {
            fail("Negative integer decoding failed")
          }
        }
        _ => fail("Negative integer decoding failed")
      }
    }
    Err(_) => fail("Negative integer encoding failed")
  }
  
  // Test large positive integer
  let large_val = DerValue::Integer(65536L)
  match encode_der(large_val) {
    Ok(encoded_large) => {
      match decode_der(encoded_large) {
        Ok(DerValue::Integer(value)) => {
          if value != 65536L {
            fail("Large integer decoding failed")
          }
        }
        _ => fail("Large integer decoding failed")
      }
    }
    Err(_) => fail("Large integer encoding failed")
  }
}

test "null encoding and decoding" {
  let null_val = DerValue::Null
  match encode_der(null_val) {
    Ok(encoded) => {
      if encoded != [b'\x05', b'\x00'] {
        fail("Null encoding failed")
      }
      
      match decode_der(encoded) {
        Ok(DerValue::Null) => ()
        _ => fail("Null decoding failed")
      }
    }
    Err(_) => fail("Null encoding failed")
  }
}

test "hex conversion" {
  let bytes = [b'\x01', b'\x23', b'\x45', b'\x67', b'\x89', b'\xAB', b'\xCD', b'\xEF']
  let hex = bytes_to_hex(bytes)
  if hex != "0123456789ABCDEF" {
    fail("Hex conversion failed")
  }
  
  // Test empty bytes
  let empty_bytes = []
  let empty_hex = bytes_to_hex(empty_bytes)
  if empty_hex != "" {
    fail("Empty hex conversion failed")
  }
  
  // Test single byte
  let single_byte = [b'\xFF']
  let single_hex = bytes_to_hex(single_byte)
  if single_hex != "FF" {
    fail("Single byte hex conversion failed")
  }
} 

test "SEQUENCE OF encoding and decoding" {
  // Test SEQUENCE OF with multiple integers
  let seq_of = DerValue::SequenceOf([
    DerValue::Integer(1L),
    DerValue::Integer(2L),
    DerValue::Integer(3L)
  ])
  
  match encode_der(seq_of) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Sequence(values)) => {
          // Since SEQUENCE OF is decoded as regular SEQUENCE
          if values.length() != 3 {
            fail("SEQUENCE OF should have 3 elements")
          }
          match values[0] {
            DerValue::Integer(i) => {
              if i != 1L {
                fail("First element should be 1")
              }
            }
            _ => fail("First element should be Integer")
          }
        }
        _ => fail("SEQUENCE OF decoding failed")
      }
    }
    Err(_) => fail("SEQUENCE OF encoding failed")
  }
  
  // Test empty SEQUENCE OF
  let empty_seq_of = DerValue::SequenceOf([])
  match encode_der(empty_seq_of) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Sequence(values)) => {
          if values.length() != 0 {
            fail("Empty SEQUENCE OF should have 0 elements")
          }
        }
        _ => fail("Empty SEQUENCE OF decoding failed")
      }
    }
    Err(_) => fail("Empty SEQUENCE OF encoding failed")
  }
}

test "SET OF encoding" {
  // Test SET OF with multiple strings
  let set_of = DerValue::SetOf([
    DerValue::PrintableString("A"),
    DerValue::PrintableString("B")
  ])
  
  match encode_der(set_of) {
    Ok(encoded) => {
      // Verify it starts with SET tag (0x31)
      if encoded[0].to_int() != 0x31 {
        fail("SET OF should start with SET tag")
      }
    }
    Err(_) => fail("SET OF encoding failed")
  }
  
  // Test empty SET OF
  let empty_set_of = DerValue::SetOf([])
  match encode_der(empty_set_of) {
    Ok(encoded) => {
      if encoded[0].to_int() != 0x31 {
        fail("Empty SET OF should start with SET tag")
      }
    }
    Err(_) => fail("Empty SET OF encoding failed")
  }
}

test "CHOICE type encoding" {
  // Test CHOICE with custom tag
  let choice = DerValue::Choice(0x81, DerValue::Integer(42L))
  
  match encode_der(choice) {
    Ok(encoded) => {
      // Verify it starts with choice tag (0x81)
      if encoded[0].to_int() != 0x81 {
        fail("CHOICE should start with choice tag")
      }
    }
    Err(_) => fail("CHOICE encoding failed")
  }
  
  // Test CHOICE with different tag
  let choice2 = DerValue::Choice(0xA0, DerValue::Boolean(true))
  match encode_der(choice2) {
    Ok(encoded) => {
      if encoded[0].to_int() != 0xA0 {
        fail("CHOICE with 0xA0 tag failed")
      }
    }
    Err(_) => fail("CHOICE with 0xA0 encoding failed")
  }
}

test "IMPLICIT tag encoding" {
  // Test IMPLICIT tag
  let implicit = DerValue::ImplicitTag(0x80, DerValue::Boolean(true))
  
  match encode_der(implicit) {
    Ok(encoded) => {
      // Verify it starts with implicit tag (0x80)
      if encoded[0].to_int() != 0x80 {
        fail("IMPLICIT tag should start with implicit tag")
      }
    }
    Err(_) => fail("IMPLICIT tag encoding failed")
  }
  
  // Test IMPLICIT tag with different tag
  let implicit2 = DerValue::ImplicitTag(0xA1, DerValue::Integer(123L))
  match encode_der(implicit2) {
    Ok(encoded) => {
      if encoded[0].to_int() != 0xA1 {
        fail("IMPLICIT tag with 0xA1 failed")
      }
    }
    Err(_) => fail("IMPLICIT tag with 0xA1 encoding failed")
  }
}

test "BitString encoding and decoding" {
  // Test normal BitString
  let bit_str = DerValue::BitString(bitstring_new([b'\xA0', b'\xB0'], 4))
  match encode_der(bit_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::BitString(bs)) => {
          if bs.unused_bits != 4 {
            fail("BitString unused bits should be 4")
          }
          if bs.data.length() != 2 {
            fail("BitString should have 2 bytes")
          }
        }
        _ => fail("BitString decoding failed")
      }
    }
    Err(_) => fail("BitString encoding failed")
  }
  
  // Test empty BitString
  let empty_bit_str = DerValue::BitString(bitstring_new([], 0))
  match encode_der(empty_bit_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::BitString(bs)) => {
          if bs.unused_bits != 0 {
            fail("Empty BitString unused bits should be 0")
          }
          if bs.data.length() != 0 {
            fail("Empty BitString should have 0 bytes")
          }
        }
        _ => fail("Empty BitString decoding failed")
      }
    }
    Err(_) => fail("Empty BitString encoding failed")
  }
}

test "BitString error cases" {
  // Test invalid unused bits (> 7)
  let invalid_bit_str = DerValue::BitString(bitstring_new([b'\xA0'], 8))
  match encode_der(invalid_bit_str) {
    Ok(_) => fail("Should fail with unused_bits > 7")
    Err(DerError::InvalidBitString(_)) => ()
    Err(_) => fail("Should return InvalidBitString error")
  }
  
  // Test invalid unused bits (< 0)
  let invalid_bit_str2 = DerValue::BitString(bitstring_new([b'\xA0'], -1))
  match encode_der(invalid_bit_str2) {
    Ok(_) => fail("Should fail with unused_bits < 0")
    Err(DerError::InvalidBitString(_)) => ()
    Err(_) => fail("Should return InvalidBitString error")
  }
}

test "OctetString encoding and decoding" {
  // Test normal OctetString
  let octet_str = DerValue::OctetString([b'\x01', b'\x02', b'\x03'])
  match encode_der(octet_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::OctetString(data)) => {
          if data.length() != 3 {
            fail("OctetString should have 3 bytes")
          }
          if data[0] != b'\x01' || data[1] != b'\x02' || data[2] != b'\x03' {
            fail("OctetString data mismatch")
          }
        }
        _ => fail("OctetString decoding failed")
      }
    }
    Err(_) => fail("OctetString encoding failed")
  }
  
  // Test empty OctetString
  let empty_octet_str = DerValue::OctetString([])
  match encode_der(empty_octet_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::OctetString(data)) => {
          if data.length() != 0 {
            fail("Empty OctetString should have 0 bytes")
          }
        }
        _ => fail("Empty OctetString decoding failed")
      }
    }
    Err(_) => fail("Empty OctetString encoding failed")
  }
}

test "ObjectIdentifier encoding and decoding" {
  // Test standard OID
  match oid_from_string("1.2.840.113549.1.1.1") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          match decode_der(encoded) {
            Ok(DerValue::ObjectId(decoded_oid)) => {
              let oid_str = oid_to_string(decoded_oid)
              if oid_str != "1.2.840.113549.1.1.1" {
                fail("OID round-trip failed")
              }
            }
            _ => fail("OID decoding failed")
          }
        }
        Err(_) => fail("OID encoding failed")
      }
    }
    Err(_) => fail("OID creation failed")
  }
  
  // Test simple OID
  match oid_from_string("1.2") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          match decode_der(encoded) {
            Ok(DerValue::ObjectId(decoded_oid)) => {
              let oid_str = oid_to_string(decoded_oid)
              if oid_str != "1.2" {
                fail("Simple OID round-trip failed")
              }
            }
            _ => fail("Simple OID decoding failed")
          }
        }
        Err(_) => fail("Simple OID encoding failed")
      }
    }
    Err(_) => fail("Simple OID creation failed")
  }
  
  // Test OID with zero component
  match oid_from_string("1.0.0") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          match decode_der(encoded) {
            Ok(DerValue::ObjectId(decoded_oid)) => {
              let oid_str = oid_to_string(decoded_oid)
              if oid_str != "1.0.0" {
                fail("OID with zero component round-trip failed")
              }
            }
            _ => fail("OID with zero component decoding failed")
          }
        }
        Err(_) => fail("OID with zero component encoding failed")
      }
    }
    Err(_) => fail("OID with zero component creation failed")
  }
}

test "ObjectIdentifier error cases" {
  // Test invalid OID (too few components)
  match oid_from_string("1") {
    Ok(_) => fail("Should fail with too few components")
    Err(msg) => {
      if msg.length() < 10 {
        fail("Wrong error message for too few components")
      }
    }
  }
  
  // Test invalid OID (empty component)
  match oid_from_string("1..2") {
    Ok(_) => fail("Should fail with empty component")
    Err(msg) => {
      if msg.length() < 10 {
        fail("Wrong error message for empty component")
      }
    }
  }
  
  // Test invalid OID (non-numeric component)
  match oid_from_string("1.abc.2") {
    Ok(_) => fail("Should fail with non-numeric component")
    Err(msg) => {
      if msg.length() < 10 {
        fail("Wrong error message for non-numeric component")
      }
    }
  }
  
  // Test empty OID string
  match oid_from_string("") {
    Ok(_) => fail("Should fail with empty string")
    Err(_) => () // Expected to fail
  }
}

test "OID encoding error cases" {
  // Test OID with invalid first/second component combination
  let invalid_oid = oid_new([3, 0])  // First component > 2
  let oid_val = DerValue::ObjectId(invalid_oid)
  match encode_der(oid_val) {
    Ok(_) => fail("Should fail with invalid first component")
    Err(DerError::InvalidOid(_)) => ()
    Err(_) => fail("Should return InvalidOid error")
  }
  
  // Test OID with too few components
  let short_oid = oid_new([1])
  let short_oid_val = DerValue::ObjectId(short_oid)
  match encode_der(short_oid_val) {
    Ok(_) => fail("Should fail with too few components")
    Err(DerError::InvalidOid(_)) => ()
    Err(_) => fail("Should return InvalidOid error")
  }
}

test "PrintableString encoding and decoding" {
  // Test valid PrintableString
  let print_str = DerValue::PrintableString("Hello World")
  match encode_der(print_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::PrintableString(s)) => {
          if s != "Hello World" {
            fail("PrintableString round-trip failed")
          }
        }
        _ => fail("PrintableString decoding failed")
      }
    }
    Err(_) => fail("PrintableString encoding failed")
  }
  
  // Test PrintableString with numbers and spaces
  let num_str = DerValue::PrintableString("Test 123")
  match encode_der(num_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::PrintableString(s)) => {
          if s != "Test 123" {
            fail("PrintableString with numbers round-trip failed")
          }
        }
        _ => fail("PrintableString with numbers decoding failed")
      }
    }
    Err(_) => fail("PrintableString with numbers encoding failed")
  }
  
  // Test empty PrintableString
  let empty_str = DerValue::PrintableString("")
  match encode_der(empty_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::PrintableString(s)) => {
          if s != "" {
            fail("Empty PrintableString round-trip failed")
          }
        }
        _ => fail("Empty PrintableString decoding failed")
      }
    }
    Err(_) => fail("Empty PrintableString encoding failed")
  }
}

test "PrintableString error cases" {
  // Test invalid PrintableString (contains invalid characters)
  let invalid_str = DerValue::PrintableString("Hello@World")
  match encode_der(invalid_str) {
    Ok(_) => fail("Should fail with invalid characters")
    Err(DerError::InvalidStringEncoding(_)) => ()
    Err(_) => fail("Should return InvalidStringEncoding error")
  }
  
  // Test invalid PrintableString (contains unicode)
  let unicode_str = DerValue::PrintableString("Hello 世界")
  match encode_der(unicode_str) {
    Ok(_) => fail("Should fail with unicode characters")
    Err(DerError::InvalidStringEncoding(_)) => ()
    Err(_) => fail("Should return InvalidStringEncoding error")
  }
}

test "IA5String encoding and decoding" {
  // Test valid IA5String
  let ia5_str = DerValue::IA5String("test@example.com")
  match encode_der(ia5_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::IA5String(s)) => {
          if s != "test@example.com" {
            fail("IA5String round-trip failed")
          }
        }
        _ => fail("IA5String decoding failed")
      }
    }
    Err(_) => fail("IA5String encoding failed")
  }
  
  // Test IA5String with special characters
  let special_str = DerValue::IA5String("!@#$%^&*()")
  match encode_der(special_str) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::IA5String(s)) => {
          if s != "!@#$%^&*()" {
            fail("IA5String with special chars round-trip failed")
          }
        }
        _ => fail("IA5String with special chars decoding failed")
      }
    }
    Err(_) => fail("IA5String with special chars encoding failed")
  }
}

test "IA5String error cases" {
  // Test invalid IA5String (contains non-ASCII)
  let invalid_str = DerValue::IA5String("Hello 世界")
  match encode_der(invalid_str) {
    Ok(_) => fail("Should fail with non-ASCII characters")
    Err(DerError::InvalidStringEncoding(_)) => ()
    Err(_) => fail("Should return InvalidStringEncoding error")
  }
}

test "Sequence encoding and decoding" {
  // Test complex nested sequence
  let nested_seq = DerValue::Sequence([
    DerValue::Integer(42L),
    DerValue::Boolean(true),
    DerValue::Null,
    DerValue::Sequence([
      DerValue::PrintableString("Nested"),
      DerValue::Integer(123L)
    ])
  ])
  
  match encode_der(nested_seq) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Sequence(values)) => {
          if values.length() != 4 {
            fail("Nested sequence should have 4 elements")
          }
          // Check nested sequence
          match values[3] {
            DerValue::Sequence(nested) => {
              if nested.length() != 2 {
                fail("Inner sequence should have 2 elements")
              }
            }
            _ => fail("Fourth element should be Sequence")
          }
        }
        _ => fail("Nested sequence decoding failed")
      }
    }
    Err(_) => fail("Nested sequence encoding failed")
  }
}

test "Set encoding and decoding" {
  // Test Set with multiple types
  let set_val = DerValue::Set([
    DerValue::Integer(1L),
    DerValue::Boolean(false),
    DerValue::PrintableString("Test")
  ])
  
  match encode_der(set_val) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Set(values)) => {
          if values.length() != 3 {
            fail("Set should have 3 elements")
          }
        }
        _ => fail("Set decoding failed")
      }
    }
    Err(_) => fail("Set encoding failed")
  }
}

test "decode error cases" {
  // Test empty data
  let empty_data = []
  match decode_der(empty_data) {
    Ok(_) => fail("Should fail with empty data")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
  
  // Test truncated length
  let truncated_length = [b'\x02'] // INTEGER tag but no length
  match decode_der(truncated_length) {
    Ok(_) => fail("Should fail with truncated length")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
  
  // Test invalid length encoding
  let invalid_length = [b'\x02', b'\x80'] // INTEGER with indefinite length (not allowed in DER)
  match decode_der(invalid_length) {
    Ok(_) => fail("Should fail with indefinite length")
    Err(DerError::InvalidLength(_)) => ()
    Err(_) => fail("Should return InvalidLength error")
  }
  
  // Test truncated content
  let truncated_content = [b'\x02', b'\x02', b'\x01'] // INTEGER says 2 bytes but only 1 provided
  match decode_der(truncated_content) {
    Ok(_) => fail("Should fail with truncated content")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
  
  // Test unknown tag
  let unknown_tag = [b'\xFF', b'\x01', b'\x00'] // Unknown tag
  match decode_der(unknown_tag) {
    Ok(_) => fail("Should fail with unknown tag")
    Err(DerError::InvalidTag(_)) => ()
    Err(_) => fail("Should return InvalidTag error")
  }
}

test "length encoding and decoding" {
  // Test short form length
  let short_len = encode_length(42)
  if short_len.length() != 1 || short_len[0].to_int() != 42 {
    fail("Short length encoding failed")
  }
  
  match decode_length(short_len, 0) {
    Ok((length, next_offset)) => {
      if length != 42 || next_offset != 1 {
        fail("Short length decoding failed")
      }
    }
    Err(_) => fail("Short length decoding failed")
  }
  
  // Test long form length
  let long_len = encode_length(256)
  if long_len.length() != 3 || long_len[0].to_int() != 0x82 {
    fail("Long length encoding failed")
  }
  
  match decode_length(long_len, 0) {
    Ok((length, next_offset)) => {
      if length != 256 || next_offset != 3 {
        fail("Long length decoding failed")
      }
    }
    Err(_) => fail("Long length decoding failed")
  }
}

test "length decoding error cases" {
  // Test decode_length with offset >= data.length()
  let data = [b'\x01']
  match decode_length(data, 1) {
    Ok(_) => fail("Should fail with offset >= data.length()")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
  
  // Test decode_length with truncated long form
  let truncated_long = [b'\x82', b'\x01'] // Says 2 bytes but only 1 provided
  match decode_length(truncated_long, 0) {
    Ok(_) => fail("Should fail with truncated long form")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
}

test "string validation functions" {
  // Test is_printable_string with valid characters
  if not(is_printable_string("ABC123 ()")) {
    fail("Valid printable string should pass")
  }
  
  // Test is_printable_string with invalid characters
  if is_printable_string("ABC@123") {
    fail("Invalid printable string should fail")
  }
  
  // Test is_ia5_string with valid ASCII
  if not(is_ia5_string("test@example.com")) {
    fail("Valid IA5 string should pass")
  }
  
  // Test is_ia5_string with non-ASCII
  if is_ia5_string("test世界") {
    fail("Non-ASCII IA5 string should fail")
  }
}

test "bytes_to_string function" {
  // Test valid ASCII bytes
  let ascii_bytes = [b'H', b'e', b'l', b'l', b'o']
  match bytes_to_string(ascii_bytes) {
    Ok(s) => {
      if s != "Hello" {
        fail("ASCII bytes to string conversion failed")
      }
    }
    Err(_) => fail("ASCII bytes to string should succeed")
  }
  
  // Test invalid bytes (> 127)
  let invalid_bytes = [b'H', b'e', 200, b'o']
  match bytes_to_string(invalid_bytes) {
    Ok(_) => fail("Should fail with non-ASCII bytes")
    Err(msg) => {
      if msg.length() < 5 {
        fail("Wrong error message for non-ASCII bytes")
      }
    }
  }
}

test "sequence encoding with nested error" {
  // Create a sequence with an invalid element that will cause encoding to fail
  let invalid_oid = oid_new([3, 0])  // Invalid OID
  let seq_with_error = DerValue::Sequence([
    DerValue::Integer(42L),
    DerValue::ObjectId(invalid_oid)  // This will cause an error
  ])
  
  match encode_der(seq_with_error) {
    Ok(_) => fail("Should fail due to invalid OID in sequence")
    Err(DerError::InvalidOid(_)) => ()
    Err(_) => fail("Should return InvalidOid error")
  }
}

test "pretty_print function" {
  // Test pretty printing of various types
  let bool_val = DerValue::Boolean(true)
  let pretty = pretty_print(bool_val)
  if pretty.length() < 10 {
    fail("Boolean pretty print failed")
  }
  
  let int_val = DerValue::Integer(42L)
  let int_pretty = pretty_print(int_val)
  if int_pretty.length() < 10 {
    fail("Integer pretty print failed")
  }
  
  let null_val = DerValue::Null
  let null_pretty = pretty_print(null_val)
  if null_pretty.length() < 4 {
    fail("NULL pretty print failed")
  }
  
  // Test nested sequence pretty printing
  let nested = DerValue::Sequence([
    DerValue::Integer(1L),
    DerValue::Boolean(false)
  ])
  let nested_pretty = pretty_print(nested)
  if nested_pretty.length() < 20 {
    fail("Nested sequence pretty print failed")
  }
} 

test "large integers" {
  // Test very large positive integer
  let large_pos = DerValue::Integer(16777216L) // 2^24
  match encode_der(large_pos) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Integer(value)) => {
          if value != 16777216L {
            fail("Large positive integer round-trip failed")
          }
        }
        _ => fail("Large positive integer decoding failed")
      }
    }
    Err(_) => fail("Large positive integer encoding failed")
  }
  
  // Test very large negative integer
  let large_neg = DerValue::Integer(-16777216L) // -2^24
  match encode_der(large_neg) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Integer(value)) => {
          if value != -16777216L {
            fail("Large negative integer round-trip failed")
          }
        }
        _ => fail("Large negative integer decoding failed")
      }
    }
    Err(_) => fail("Large negative integer encoding failed")
  }
  
  // Test -1 (special case for two's complement)
  let minus_one = DerValue::Integer(-1L)
  match encode_der(minus_one) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Integer(value)) => {
          if value != -1L {
            fail("Minus one round-trip failed")
          }
        }
        _ => fail("Minus one decoding failed")
      }
    }
    Err(_) => fail("Minus one encoding failed")
  }
}

test "long form length encoding" {
  // Test length that requires long form (> 127)
  let long_data = []
  for i in 0..<200 {
    long_data.push(b'\x00')
  }
  let long_octet = DerValue::OctetString(long_data)
  
  match encode_der(long_octet) {
    Ok(encoded) => {
      // Check that it uses long form length encoding
      if encoded[1].to_int() != 0x81 { // Long form with 1 byte for length
        fail("Should use long form length encoding")
      }
      match decode_der(encoded) {
        Ok(DerValue::OctetString(data)) => {
          if data.length() != 200 {
            fail("Long octet string round-trip failed")
          }
        }
        _ => fail("Long octet string decoding failed")
      }
    }
    Err(_) => fail("Long octet string encoding failed")
  }
}

test "empty string types" {
  // Test empty PrintableString
  let empty_print = DerValue::PrintableString("")
  match encode_der(empty_print) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::PrintableString(s)) => {
          if s != "" {
            fail("Empty PrintableString round-trip failed")
          }
        }
        _ => fail("Empty PrintableString decoding failed")
      }
    }
    Err(_) => fail("Empty PrintableString encoding failed")
  }
  
  // Test empty IA5String
  let empty_ia5 = DerValue::IA5String("")
  match encode_der(empty_ia5) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::IA5String(s)) => {
          if s != "" {
            fail("Empty IA5String round-trip failed")
          }
        }
        _ => fail("Empty IA5String decoding failed")
      }
    }
    Err(_) => fail("Empty IA5String encoding failed")
  }
}

test "oid_new function" {
  // Test oid_new function directly
  let oid = oid_new([1, 2, 3, 4, 5])
  let oid_str = oid_to_string(oid)
  if oid_str != "1.2.3.4.5" {
    fail("oid_new and oid_to_string failed")
  }
  
  // Test single component OID (edge case)
  let single_oid = oid_new([0])
  let single_str = oid_to_string(single_oid)
  if single_str != "0" {
    fail("Single component OID failed")
  }
}

test "OID boundary values" {
  // Test OID with maximum valid first component values
  match oid_from_string("2.175") { // Maximum for first=2
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          match decode_der(encoded) {
            Ok(DerValue::ObjectId(decoded_oid)) => {
              let oid_str = oid_to_string(decoded_oid)
              if oid_str != "2.175" {
                fail("OID 2.175 round-trip failed")
              }
            }
            _ => fail("OID 2.175 decoding failed")
          }
        }
        Err(_) => fail("OID 2.175 encoding failed")
      }
    }
    Err(_) => fail("OID 2.175 creation failed")
  }
  
  // Test OID with large component values
  match oid_from_string("1.2.65536.1024") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      match encode_der(oid_val) {
        Ok(encoded) => {
          match decode_der(encoded) {
            Ok(DerValue::ObjectId(decoded_oid)) => {
              let oid_str = oid_to_string(decoded_oid)
              if oid_str != "1.2.65536.1024" {
                fail("Large component OID round-trip failed")
              }
            }
            _ => fail("Large component OID decoding failed")
          }
        }
        Err(_) => fail("Large component OID encoding failed")
      }
    }
    Err(_) => fail("Large component OID creation failed")
  }
}

test "decode malformed data" {
  // Test decoding with invalid tag/length combinations
  let malformed1 = [b'\x02', b'\x01'] // INTEGER tag, length 1, but no content
  match decode_der(malformed1) {
    Ok(_) => fail("Should fail with missing content")
    Err(DerError::InsufficientData) => ()
    Err(_) => fail("Should return InsufficientData error")
  }
  
  // Test BOOLEAN with wrong length
  let malformed_bool = [b'\x01', b'\x02', b'\xFF', b'\x00'] // BOOLEAN with length 2
  match decode_der(malformed_bool) {
    Ok(_) => fail("Should fail with invalid BOOLEAN length")
    Err(DerError::InvalidLength(_)) => ()
    Err(_) => fail("Should return InvalidLength error")
  }
  
  // Test BIT STRING with too many unused bits
  let malformed_bits = [b'\x03', b'\x02', b'\x08', b'\xFF'] // 8 unused bits (invalid)
  match decode_der(malformed_bits) {
    Ok(_) => fail("Should fail with too many unused bits")
    Err(DerError::InvalidBitString(_)) => ()
    Err(_) => fail("Should return InvalidBitString error")
  }
  
  // Test empty INTEGER
  let empty_int = [b'\x02', b'\x00'] // INTEGER with length 0
  match decode_der(empty_int) {
    Ok(_) => fail("Should fail with empty INTEGER")
    Err(DerError::InvalidLength(_)) => ()
    Err(_) => fail("Should return InvalidLength error")
  }
  
  // Test empty BIT STRING
  let empty_bits = [b'\x03', b'\x00'] // BIT STRING with length 0
  match decode_der(empty_bits) {
    Ok(_) => fail("Should fail with empty BIT STRING")
    Err(DerError::InvalidLength(_)) => ()
    Err(_) => fail("Should return InvalidLength error")
  }
}

test "decode_oid edge cases" {
  // Test OID decoding with various edge cases by manually creating encoded data
  
  // Test minimal OID (1.0)
  let minimal_oid_data = [b'\x06', b'\x01', b'\x28'] // OID tag, length 1, content 40 (1*40+0)
  match decode_der(minimal_oid_data) {
    Ok(DerValue::ObjectId(oid)) => {
      let oid_str = oid_to_string(oid)
      if oid_str != "1.0" {
        fail("Minimal OID decoding failed")
      }
    }
    _ => fail("Minimal OID decoding failed")
  }
  
  // Test OID with first byte >= 80 (should decode as 2.x)
  let oid_2x_data = [b'\x06', b'\x01', b'\x50'] // OID tag, length 1, content 80 (2*40+0)
  match decode_der(oid_2x_data) {
    Ok(DerValue::ObjectId(oid)) => {
      let oid_str = oid_to_string(oid)
      if oid_str != "2.0" {
        fail("OID 2.0 decoding failed")
      }
    }
    _ => fail("OID 2.0 decoding failed")
  }
  
  // Test empty OID (should fail)
  let empty_oid_data = [b'\x06', b'\x00'] // OID tag, length 0
  match decode_der(empty_oid_data) {
    Ok(_) => fail("Should fail with empty OID")
    Err(DerError::InvalidOid(_)) => ()
    Err(_) => fail("Should return InvalidOid error")
  }
}

test "SET and SET OF decoding" {
  // Test SET decoding
  let set_data = DerValue::Set([
    DerValue::PrintableString("Hello"),
    DerValue::Integer(42L)
  ])
  
  match encode_der(set_data) {
    Ok(encoded) => {
      match decode_der(encoded) {
        Ok(DerValue::Set(values)) => {
          if values.length() != 2 {
            fail("SET should have 2 elements")
          }
        }
        _ => fail("SET decoding failed")
      }
    }
    Err(_) => fail("SET encoding failed")
  }
}

test "string_to_bytes function" {
  // Test string_to_bytes with various inputs
  let ascii_str = "Hello"
  let bytes = string_to_bytes(ascii_str)
  if bytes.length() != 5 {
    fail("string_to_bytes length failed")
  }
  if bytes[0] != b'H' || bytes[4] != b'o' {
    fail("string_to_bytes content failed")
  }
  
  // Test empty string
  let empty_str = ""
  let empty_bytes = string_to_bytes(empty_str)
  if empty_bytes.length() != 0 {
    fail("Empty string should produce empty bytes")
  }
}

test "pretty_print_indent function" {
  // Test indented pretty printing
  let nested_seq = DerValue::Sequence([
    DerValue::Integer(1L),
    DerValue::Sequence([
      DerValue::Boolean(true),
      DerValue::Null
    ])
  ])
  
  let indented = pretty_print_indent(nested_seq, 2)
  if indented.length() < 50 {
    fail("Indented pretty print failed")
  }
}

test "all DerValue types pretty printing" {
  // Test pretty printing of all DerValue types by checking output length
  let bit_str = DerValue::BitString(bitstring_new([b'\xA0'], 4))
  let bit_pretty = pretty_print(bit_str)
  if bit_pretty.length() < 10 {
    fail("BitString pretty print failed")
  }
  
  let octet_str = DerValue::OctetString([b'\x01', b'\x02'])
  let octet_pretty = pretty_print(octet_str)
  if octet_pretty.length() < 10 {
    fail("OctetString pretty print failed")
  }
  
  match oid_from_string("1.2.3") {
    Ok(oid) => {
      let oid_val = DerValue::ObjectId(oid)
      let oid_pretty = pretty_print(oid_val)
      if oid_pretty.length() < 15 {
        fail("ObjectId pretty print failed")
      }
    }
    Err(_) => fail("OID creation for pretty print test failed")
  }
  
  let print_str = DerValue::PrintableString("Test")
  let print_pretty = pretty_print(print_str)
  if print_pretty.length() < 15 {
    fail("PrintableString pretty print failed")
  }
  
  let ia5_str = DerValue::IA5String("test@example.com")
  let ia5_pretty = pretty_print(ia5_str)
  if ia5_pretty.length() < 15 {
    fail("IA5String pretty print failed")
  }
  
  let set_val = DerValue::Set([DerValue::Integer(1L)])
  let set_pretty = pretty_print(set_val)
  if set_pretty.length() < 10 {
    fail("Set pretty print failed")
  }
  
  let seq_of = DerValue::SequenceOf([DerValue::Integer(1L)])
  let seq_of_pretty = pretty_print(seq_of)
  if seq_of_pretty.length() < 15 {
    fail("SequenceOf pretty print failed")
  }
  
  let set_of = DerValue::SetOf([DerValue::Integer(1L)])
  let set_of_pretty = pretty_print(set_of)
  if set_of_pretty.length() < 10 {
    fail("SetOf pretty print failed")
  }
  
  let choice = DerValue::Choice(0x81, DerValue::Integer(42L))
  let choice_pretty = pretty_print(choice)
  if choice_pretty.length() < 10 {
    fail("Choice pretty print failed")
  }
  
  let implicit = DerValue::ImplicitTag(0x80, DerValue::Boolean(true))
  let implicit_pretty = pretty_print(implicit)
  if implicit_pretty.length() < 10 {
    fail("ImplicitTag pretty print failed")
  }
} 