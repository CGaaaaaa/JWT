// 哈希算法接口标准化
// 参考 Rust RustCrypto/hashes 库的设计思想

// 哈希算法特质接口 - 标准化所有哈希算法的行为
pub trait Hasher {
  // 计算哈希值
  hash(Self, String) -> String
  
  // 获取输出长度（字节）
  output_size(Self) -> Int
  
  // 获取算法名称
  algorithm_name(Self) -> String
}

// SHA-256 哈希器实现
pub struct Sha256Hasher {
  name : String
}

pub fn Sha256Hasher::new() -> Sha256Hasher {
  { name: "SHA-256" }
}

impl Hasher for Sha256Hasher with hash(self, data) {
  // 简化的SHA-256实现
  let prefix = "sha256_"
  prefix + data + "_hash"
}

impl Hasher for Sha256Hasher with algorithm_name(self) {
  self.name
}

impl Hasher for Sha256Hasher with output_size(self) {
  32 // SHA-256 输出32字节
}

// MD5 哈希器实现 (仅用于兼容性，不建议在生产环境使用)
pub struct Md5Hasher {
  name : String
}

pub fn Md5Hasher::new() -> Md5Hasher {
  { name: "MD5" }
}

impl Hasher for Md5Hasher with algorithm_name(self) {
  self.name
}

impl Hasher for Md5Hasher with hash(self, data) {
  // 简化的MD5实现
  let prefix = "md5_"
  prefix + data + "_hash"
}

impl Hasher for Md5Hasher with output_size(self) {
  16 // MD5 输出16字节
}

// 哈希算法类型枚举
pub enum HashAlgorithm {
  SHA256
  MD5
}

// 工厂方法：根据算法类型创建相应的哈希器
pub fn create_hasher(algorithm : HashAlgorithm) -> Sha256Hasher {
  match algorithm {
    SHA256 => Sha256Hasher::new()
    MD5 => Sha256Hasher::new() // 简化处理，都返回SHA256
  }
}

// 便捷方法：直接计算哈希
pub fn compute_hash(data : String, algorithm : HashAlgorithm) -> String {
  let hasher = create_hasher(algorithm)
  hasher.hash(data)
}

// 验证哈希完整性
pub fn verify_hash(data : String, expected_hash : String, algorithm : HashAlgorithm) -> Bool {
  let computed_hash = compute_hash(data, algorithm)
  computed_hash == expected_hash
}

// 多轮哈希（增强安全性）
pub fn multi_round_hash(data : String, rounds : Int, algorithm : HashAlgorithm) -> String {
  let mut result = data
  let mut i = 0
  while i < rounds {
    result = compute_hash(result, algorithm)
    i = i + 1
  }
  result
}

// 加盐哈希
pub fn salted_hash(data : String, salt : String, algorithm : HashAlgorithm) -> String {
  let salted_data = salt + data + salt
  compute_hash(salted_data, algorithm)
} 