// 最小可用的 RSA 实现（PKCS#1 v1.5 签名验证所需）
// 依赖 bigint.mbt 提供的大整数与模幂

///|
pub struct RsaPublicKey {
  n : BigInt // 模数
  e : BigInt // 公钥指数
}

///|
pub struct RsaPrivateKey {
  n : BigInt // 模数
  d : BigInt // 私钥指数
}

///|
/// 从 JWK（base64url 的 n、e）构造公钥
pub fn RsaPublicKey::from_jwk(
  n_b64url : String,
  e_b64url : String,
) -> RsaPublicKey {
  let n_bytes = base64url_decode_to_bytes(n_b64url)
  let e_bytes = base64url_decode_to_bytes(e_b64url)
  println(
    "[RSA] JWK n_bytes=" +
    n_bytes.length().to_string() +
    ", e_bytes=" +
    e_bytes.length().to_string(),
  )
  let n = BigInt::from_bytes_be(n_bytes)
  let e = BigInt::from_bytes_be(e_bytes)
  println("[RSA] n_bitlen=" + big_bitlen(n).to_string())
  { n, e }
}

///|
/// 从 JWK（base64url 的 n、d）构造私钥
pub fn RsaPrivateKey::from_jwk(
  n_b64url : String,
  d_b64url : String,
) -> RsaPrivateKey {
  let n_bytes = base64url_decode_to_bytes(n_b64url)
  let d_bytes = base64url_decode_to_bytes(d_b64url)
  println(
    "[RSA] JWK(priv) n_bytes=" +
    n_bytes.length().to_string() +
    ", d_bytes=" +
    d_bytes.length().to_string(),
  )
  let n = BigInt::from_bytes_be(n_bytes)
  let d = BigInt::from_bytes_be(d_bytes)
  println("[RSA] priv n_bitlen=" + big_bitlen(n).to_string())
  { n, d }
}

///|
/// 原始 RSA 运算：m^exp mod n，其中 m 为大端字节表示的消息，返回与 n 同长度的字节数组
fn rsa_raw_modexp(msg_be : Array[Int], exp : BigInt, n : BigInt) -> Array[Int] {
  let m = BigInt::from_bytes_be(msg_be)
  let c = big_modexp(m, exp, n)
  // 输出固定长度等于模数字节长度
  let modulus_bits = big_bitlen(n)
  let modulus_bytes = (modulus_bits + 7) / 8
  c.to_bytes_be_fixed(modulus_bytes)
}

///|
/// EMSA-PKCS1-v1_5 编码（仅支持 SHA-256，DigestInfo 按照 RFC 8017 附录）
fn emsa_pkcs1_v1_5_encode(hash_hex : String, em_len : Int) -> Array[Int] {
  // SHA-256 的 DigestInfo：
  // 30 31 30 0d 06 09 60 86 48 01 65 03 04 02 01 05 00 04 20 || H
  let digest_info_prefix = [
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04,
    0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
  ]
  let hash_bytes = hex_to_bytes(hash_hex)
  let t_len = digest_info_prefix.length() + hash_bytes.length()
  if em_len < t_len + 11 {
    println(
      "[RSA] EMSA fail: em_len=" +
      em_len.to_string() +
      ", t_len=" +
      t_len.to_string(),
    )
    // 编码错误，空间不足
    return Array::new()
  }
  let ps_len = em_len - t_len - 3
  let em = Array::new()
  em.push(0x00)
  em.push(0x01)
  // PS 全 0xFF
  let mut i = 0
  while i < ps_len {
    em.push(0xFF)
    i = i + 1
  }
  em.push(0x00)
  // T = DigestInfo || H
  for b in digest_info_prefix {
    em.push(b)
  }
  for b in hash_bytes {
    em.push(b)
  }
  em
}

///|
/// 将十六进制字符串转字节
fn hex_to_bytes(hex : String) -> Array[Int] {
  let out = Array::new()
  let mut i = 0
  while i + 1 < hex.length() {
    let h = hex[i]
    let l = hex[i + 1]
    let hv = hex_nibble(h)
    let lv = hex_nibble(l)
    out.push((hv << 4) | lv)
    i = i + 2
  }
  out
}

///|
fn hex_nibble(c : Int) -> Int {
  if c >= 48 && c <= 57 {
    return c - 48
  }
  if c >= 97 && c <= 102 {
    return 10 + c - 97
  }
  if c >= 65 && c <= 70 {
    return 10 + c - 65
  }
  0
}

///|
/// RSA PKCS#1 v1.5 签名（仅 SHA-256）
pub fn rsa_sign_pkcs1_v1_5_sha256(
  private_key : RsaPrivateKey,
  hash_hex : String,
) -> Array[Int] {
  let n_bits = big_bitlen(private_key.n)
  let k = (n_bits + 7) / 8 // 模数字节长度
  let em = emsa_pkcs1_v1_5_encode(hash_hex, k)
  // 调试：打印EM前3字节
  if em.length() >= 3 {
    println(
      "[RSA] EM[0..2]=" +
      em[0].to_string() +
      "," +
      em[1].to_string() +
      "," +
      em[2].to_string(),
    )
  } else {
    println("[RSA] EM too short: " + em.length().to_string())
  }
  rsa_raw_modexp(em, private_key.d, private_key.n)
}

///|
/// RSA PKCS#1 v1.5 验证（仅 SHA-256）
pub fn rsa_verify_pkcs1_v1_5_sha256(
  pubk : RsaPublicKey,
  hash_hex : String,
  signature : Array[Int],
) -> Bool {
  let n_bits = big_bitlen(pubk.n)
  let k = (n_bits + 7) / 8
  if signature.length() != k {
    println(
      "[RSA] verify: k=" +
      k.to_string() +
      ", sig_len=" +
      signature.length().to_string(),
    )
    return false
  }
  // s^e mod n 应该等于编码后的 EM
  let em = rsa_raw_modexp(signature, pubk.e, pubk.n)
  let expected = emsa_pkcs1_v1_5_encode(hash_hex, k)
  // 常量时间相等比较（简化：逐字节比对）
  if em.length() != expected.length() {
    return false
  }
  // 调试信息（帮助定位不匹配原因）
  println(
    "[RSA] k=" +
    k.to_string() +
    ", sig_len=" +
    signature.length().to_string() +
    ", em[0..2]=" +
    em[0].to_string() +
    "," +
    em[1].to_string() +
    "," +
    em[2].to_string(),
  )
  println(
    "[RSA] expected[0..2]=" +
    expected[0].to_string() +
    "," +
    expected[1].to_string() +
    "," +
    expected[2].to_string(),
  )
  let mut ok = true
  let mut i = 0
  while i < em.length() {
    if em[i] != expected[i] {
      ok = false
    }
    i = i + 1
  }
  ok
}

// Base64URL 字节转换函数由 base64.mbt 提供
