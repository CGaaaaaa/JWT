// 简易任意精度整数（BigInt）实现 - 16位进制（base = 2^16）
// 仅实现 RSA 所需的最小运算：比较、加减、乘法、按位左移、按位右移1位、奇偶判断、模、模幂

///|
pub struct BigInt {
  // 小端存储：limbs[0] 为最低位，每个 limb 为 16bit（0..65535）
  limbs : Array[Int]
}

///|
pub fn BigInt::zero() -> BigInt {
  { limbs: Array::new() }
}

///|
pub fn BigInt::from_int(x : Int) -> BigInt {
  if x == 0 {
    return BigInt::zero()
  }
  let mut v = x
  let limbs = Array::new()
  let a = { limbs, }
  while v > 0 {
    a.limbs.push(v & 0xFF)
    v = v >> 8
  }
  a
}

///|
/// 从大端字节创建 BigInt
pub fn BigInt::from_bytes_be(bytes : Array[Int]) -> BigInt {
  let mut a = BigInt::zero()
  for i = 0; i < bytes.length(); i = i + 1 {
    a = big_shl_bits(a, 8)
    a = big_add_small(a, bytes[i] & 0xFF)
  }
  big_normalize(a)
}

///|
/// 导出为固定长度（大端）字节数组，不足左侧补0
pub fn BigInt::to_bytes_be_fixed(self : BigInt, length : Int) -> Array[Int] {
  let mut tmp = self
  let bytes = Array::new()
  // 先取出所有字节（小端取余法），再反转
  while not(big_is_zero(tmp)) {
    let dm = big_divmod_small(tmp, 256)
    let q = dm.0
    let r = dm.1
    bytes.push(r)
    tmp = q
  }
  // 现在 bytes 为小端字节序，将其转换为固定长度大端
  let out = Array::new()
  let mut i = 0
  while i < length - bytes.length() {
    out.push(0)
    i = i + 1
  }
  // 追加反向后的字节
  let mut j = bytes.length() - 1
  while bytes.length() > 0 && j >= 0 {
    out.push(bytes[j])
    if j == 0 {
      break
    }
    j = j - 1
  }
  out
}

///|
pub fn big_is_zero(a : BigInt) -> Bool {
  a.limbs.length() == 0
}

///|
pub fn big_copy(a : BigInt) -> BigInt {
  let b = Array::new()
  for v in a.limbs {
    b.push(v)
  }
  { limbs: b }
}

///|
pub fn big_normalize(a : BigInt) -> BigInt {
  // 找到最高的非零 limb 索引
  if a.limbs.length() == 0 {
    return a
  }
  let mut idx = a.limbs.length() - 1
  while true {
    if a.limbs[idx] != 0 {
      break
    }
    if idx == 0 {
      return BigInt::zero()
    }
    idx = idx - 1
  }
  // 复制至 idx（包含）
  let limbs2 = Array::new()
  let mut i = 0
  while i <= idx {
    limbs2.push(a.limbs[i])
    i = i + 1
  }
  { limbs: limbs2 }
}

///|
/// 比较：a < b 返回 -1，等于返回 0，大于返回 1
pub fn big_compare(a : BigInt, b : BigInt) -> Int {
  let la = a.limbs.length()
  let lb = b.limbs.length()
  if la < lb {
    return -1
  }
  if la > lb {
    return 1
  }
  if la == 0 {
    return 0
  }
  // 同长度，从高位到低位比较
  let mut i = la - 1
  while true {
    let av = a.limbs[i] & 0xFF
    let bv = b.limbs[i] & 0xFF
    if av < bv {
      return -1
    }
    if av > bv {
      return 1
    }
    if i == 0 {
      break
    }
    i = i - 1
  }
  0
}

///|
/// a + b
pub fn big_add(a : BigInt, b : BigInt) -> BigInt {
  let la = a.limbs.length()
  let lb = b.limbs.length()
  let n = if la > lb { la } else { lb }
  let out = Array::new()
  let res = { limbs: out }
  let mut carry = 0
  let mut i = 0
  while i < n {
    let av = if i < la { a.limbs[i] & 0xFF } else { 0 }
    let bv = if i < lb { b.limbs[i] & 0xFF } else { 0 }
    let sum = av + bv + carry
    res.limbs.push(sum & 0xFF)
    carry = sum >> 8
    i = i + 1
  }
  if carry > 0 {
    res.limbs.push(carry & 0xFF)
  }
  big_normalize(res)
}

///|
/// a - b，要求 a >= b
pub fn big_sub(a : BigInt, b : BigInt) -> BigInt {
  let la = a.limbs.length()
  let lb = b.limbs.length()
  let out = Array::new()
  let res = { limbs: out }
  let mut borrow = 0
  let mut i = 0
  while i < la {
    let av = a.limbs[i] & 0xFF
    let bv = if i < lb { b.limbs[i] & 0xFF } else { 0 }
    let mut diff = av - bv - borrow
    if diff < 0 {
      diff = diff + 0x100
      borrow = 1
    } else {
      borrow = 0
    }
    res.limbs.push(diff & 0xFF)
    i = i + 1
  }
  big_normalize(res)
}

///|
/// a 与小整数相加（0 <= small < 65536）
pub fn big_add_small(a : BigInt, small : Int) -> BigInt {
  let out = Array::new()
  let res = { limbs: out }
  let mut carry = small & 0xFF
  let mut i = 0
  while i < a.limbs.length() {
    let av = a.limbs[i] & 0xFF
    let sum = av + carry
    res.limbs.push(sum & 0xFF)
    carry = sum >> 8
    i = i + 1
  }
  if carry > 0 {
    res.limbs.push(carry)
  }
  big_normalize(res)
}

///|
/// a * 小整数（0 <= m < 65536）
pub fn big_mul_small(a : BigInt, m : Int) -> BigInt {
  if big_is_zero(a) {
    return a
  }
  let out = Array::new()
  let res = { limbs: out }
  let mut carry = 0
  let mut i = 0
  while i < a.limbs.length() {
    let av = a.limbs[i] & 0xFF
    let prod = av * (m & 0xFF) + carry
    res.limbs.push(prod & 0xFF)
    carry = prod >> 8
    i = i + 1
  }
  if carry > 0 {
    res.limbs.push(carry & 0xFF)
  }
  big_normalize(res)
}

///|
/// a * b（学校乘法）
pub fn big_mul(a : BigInt, b : BigInt) -> BigInt {
  if big_is_zero(a) || big_is_zero(b) {
    return BigInt::zero()
  }
  let la = a.limbs.length()
  let lb = b.limbs.length()
  let out = Array::new()
  let res = { limbs: out }
  // 预分配 la + lb + 1 个 limb
  let mut i = 0
  while i < la + lb + 1 {
    res.limbs.push(0)
    i = i + 1
  }
  i = 0
  while i < la {
    let mut carry = 0
    let av = a.limbs[i] & 0xFF
    let mut j = 0
    while j < lb {
      let bv = b.limbs[j] & 0xFF
      let idx = i + j
      let sum = (res.limbs[idx] & 0xFF) + av * bv + carry
      res.limbs[idx] = sum & 0xFF
      carry = sum >> 8
      j = j + 1
    }
    // 传播剩余的进位
    let mut k = i + lb
    while carry > 0 {
      let sum2 = (res.limbs[k] & 0xFF) + carry
      res.limbs[k] = sum2 & 0xFF
      carry = sum2 >> 8
      k = k + 1
    }
    i = i + 1
  }
  big_normalize(res)
}

///|
/// 左移 bit_count 位（bit_count 可以大于16）
pub fn big_shl_bits(a : BigInt, bit_count : Int) -> BigInt {
  if big_is_zero(a) {
    return a
  }
  let word_shifts = bit_count / 8
  let rem_bits = bit_count % 8
  let out = Array::new()
  let res = { limbs: out }
  // 先补 word_shifts 个 0
  let mut i = 0
  while i < word_shifts {
    res.limbs.push(0)
    i = i + 1
  }
  let mut carry = 0
  i = 0
  while i < a.limbs.length() {
    let cur = a.limbs[i] & 0xFF
    let shifted = ((cur << rem_bits) & 0xFF) + carry
    res.limbs.push(shifted & 0xFF)
    carry = cur << rem_bits >> 8
    i = i + 1
  }
  if carry > 0 {
    res.limbs.push(carry & 0xFF)
  }
  big_normalize(res)
}

///|
/// 右移 1 位
pub fn big_shr1(a : BigInt) -> BigInt {
  if big_is_zero(a) {
    return a
  }
  let out = Array::new()
  let res = { limbs: out }
  let mut carry = 0
  let mut i = a.limbs.length() - 1
  while true {
    let cur = a.limbs[i] & 0xFF
    let next_carry = cur & 1
    let shifted = (cur >> 1) | (carry << 7)
    // 在结果数组中追加（先收集，最后再反转）
    res.limbs.push(shifted & 0xFF)
    carry = next_carry
    if i == 0 {
      break
    }
    i = i - 1
  }
  // 反转回小端顺序
  let rev = Array::new()
  let mut j = res.limbs.length() - 1
  while res.limbs.length() > 0 && j >= 0 {
    rev.push(res.limbs[j])
    if j == 0 {
      break
    }
    j = j - 1
  }
  big_normalize({ limbs: rev })
}

///|
pub fn big_is_odd(a : BigInt) -> Bool {
  if big_is_zero(a) {
    return false
  }
  (a.limbs[0] & 1) == 1
}

///|
/// 计算位长度
pub fn big_bitlen(a : BigInt) -> Int {
  let la = a.limbs.length()
  if la == 0 {
    return 0
  }
  let hi = a.limbs[la - 1] & 0xFF
  let mut bits = (la - 1) * 8
  let mut v = hi
  while v > 0 {
    bits = bits + 1
    v = v >> 1
  }
  bits
}

///|
/// 取模：a mod m（使用移位-减法的二进制长除法）
pub fn big_mod(a : BigInt, m : BigInt) -> BigInt {
  if big_is_zero(m) {
    return BigInt::zero()
  }
  let mut r = big_copy(a)
  let cmp = big_compare(r, m)
  if cmp < 0 {
    return r
  }
  if cmp == 0 {
    return BigInt::zero()
  }
  let mbits = big_bitlen(m)
  while big_compare(r, m) >= 0 {
    let rbits = big_bitlen(r)
    let mut shift = rbits - mbits
    if shift < 0 {
      break
    }
    let mut ms = big_shl_bits(big_copy(m), shift)
    if big_compare(r, ms) < 0 {
      shift = shift - 1
      ms = big_shl_bits(big_copy(m), shift)
    }
    r = big_sub(r, ms)
    // 规范化，避免多余高位 0 导致位数估计过大
    r = big_normalize(r)
  }
  big_normalize(r)
}

///|
/// (a * b) mod m
pub fn big_mul_mod(a : BigInt, b : BigInt, m : BigInt) -> BigInt {
  let p = big_mul(a, b)
  big_mod(p, m)
}

///|
/// 模幂：base^exp mod m（右到左二进制法）
pub fn big_modexp(base : BigInt, exp : BigInt, m : BigInt) -> BigInt {
  let mut result = BigInt::from_int(1)
  let mut b = big_mod(base, m)
  let mut e = exp
  while not(big_is_zero(e)) {
    if big_is_odd(e) {
      result = big_mul_mod(result, b, m)
    }
    b = big_mul_mod(b, b, m)
    e = big_shr1(e)
  }
  big_mod(result, m)
}

///|
/// 大整数 / 小整数，返回 (商, 余数)，其中 0 <= div < 65536
pub fn big_divmod_small(a : BigInt, div : Int) -> (BigInt, Int) {
  let out = Array::new()
  let q = { limbs: out }
  if div <= 0 {
    return (BigInt::zero(), 0)
  }
  let mut carry = 0
  if a.limbs.length() == 0 {
    return (BigInt::zero(), 0)
  }
  let mut i = a.limbs.length() - 1
  // 高位到低位进行除法
  while true {
    let cur = (carry << 8) + (a.limbs[i] & 0xFF)
    let qdigit = cur / div
    carry = cur % div
    q.limbs.push(qdigit & 0xFF)
    if i == 0 {
      break
    }
    i = i - 1
  }
  // 结果当前是高位在前的顺序，反转成小端
  let rev = Array::new()
  let mut j = q.limbs.length() - 1
  while q.limbs.length() > 0 && j >= 0 {
    rev.push(q.limbs[j])
    if j == 0 {
      break
    }
    j = j - 1
  }
  (big_normalize({ limbs: rev }), carry)
}
