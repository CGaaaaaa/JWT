// Base64 编码测试

test "base64url_encode - simple text" {
  let input = "Hello"
  let encoded = base64url_encode_str(input)
  // "Hello" 的 Base64 URL 编码（无填充）应该是 "SGVsbG8"
  println("Input: " + input)
  println("Encoded: " + encoded)
  inspect!(encoded, content="SGVsbG8")
}

test "base64url_encode - JWT header" {
  let header = "{\"alg\":\"RS256\",\"typ\":\"JWT\"}"
  let encoded = base64url_encode_str(header)
  println("Header: " + header)
  println("Encoded: " + encoded)
  // 验证编码不为空
  if encoded.length() == 0 {
    abort("Encoded header is empty")
  }
  // JWT 不应该有填充
  if encoded.contains("=") {
    abort("JWT should not contain padding")
  }
}

test "base64url_encode - empty string" {
  let input = ""
  let encoded = base64url_encode_str(input)
  println("Empty input encoded: [" + encoded + "]")
  inspect!(encoded.length(), content="0")
}

test "base64_encode_decode - roundtrip" {
  let original = "The quick brown fox"
  let encoded = base64_encode(original)
  let decoded = base64_decode(encoded)
  println("Original: " + original)
  println("Encoded: " + encoded)
  println("Decoded: " + decoded)
  if original != decoded {
    abort("Roundtrip failed: original != decoded")
  }
}

test "base64url_encode_decode - roundtrip" {
  let original = "JWT Token Data"
  let encoded = base64url_encode_str(original)
  let decoded = base64url_decode(encoded)
  println("Original: " + original)
  println("Encoded: " + encoded)
  println("Decoded: " + decoded)
  if original != decoded {
    abort("Roundtrip failed: original != decoded")
  }
}

test "base64url vs base64 - character differences" {
  // URL-safe 使用 - 和 _ 而不是 + 和 /
  let input = "subjects?_d"
  let url_safe = base64url_encode_str(input)
  let standard = base64_encode(input)
  println("Input: " + input)
  println("URL-safe: " + url_safe)
  println("Standard: " + standard)
  // 应该不同（一个有填充，一个没有）
  if url_safe == standard {
    abort("URL-safe and standard encodings should be different")
  }
}

