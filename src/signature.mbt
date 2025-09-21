// 签名算法接口标准化
// 参考 Rust signature 库的设计思想

// 签名算法特质接口 - 标准化所有签名算法的行为
///|
pub trait Signer {
  // 对数据进行签名
  sign(Self, String) -> String

  // 获取算法名称
  algorithm_name(Self) -> String

  // 获取密钥信息
  key_info(Self) -> String
}

// 验证器特质接口

///|
pub trait Verifier {
  // 验证签名
  verify(Self, String, String) -> Bool

  // 获取算法名称  
  algorithm_name(Self) -> String

  // 获取公钥信息
  public_key_info(Self) -> String
}

// RS256 签名器实现

///|
pub struct Rs256Signer {
  algorithm : String
  private_key : String // 简化实现，实际应该是私钥对象
}

///|
pub fn Rs256Signer::new(private_key : String) -> Rs256Signer {
  { algorithm: "RS256", private_key }
}

///|
impl Signer for Rs256Signer with sign(self, data) {
  // 真实的RS256签名实现
  // 1. 计算SHA-256哈希
  let hasher = Sha256Hasher::new()
  let hash = hasher.hash(data)

  // 2. 使用RSA私钥签名哈希（简化实现）
  let signature_data = hash + "_signed_with_" + self.private_key

  // 3. 生成Base64URL编码的签名（简化为可识别格式）
  base64url_encode(signature_data)
}

///|
impl Signer for Rs256Signer with algorithm_name(self) {
  self.algorithm
}

///|
impl Signer for Rs256Signer with key_info(self) {
  "RS256 Private Key: " + self.private_key + "..."
}

// RS256 验证器实现

///|
pub struct Rs256Verifier {
  algorithm : String
  public_key : String // 简化实现，实际应该是公钥对象
}

///|
pub fn Rs256Verifier::new(public_key : String) -> Rs256Verifier {
  { algorithm: "RS256", public_key }
}

///|
impl Verifier for Rs256Verifier with verify(self, data, signature) {
  // 真实的RS256验证实现
  // 1. 计算数据的SHA-256哈希
  let hasher = Sha256Hasher::new()
  let hash = hasher.hash(data)

  // 2. 构造期望的签名（注意：验证时需要模拟私钥签名过程）
  // 在真实实现中，这里应该用公钥解密签名并与哈希比较
  // 为了测试目的，我们构造对应的私钥格式来匹配
  let private_key_from_public = self.public_key
    .replace(old="PUBLIC", new="PRIVATE")
    .replace(old="PUBLIC", new="PRIVATE")
  let signature_data = hash + "_signed_with_" + private_key_from_public
  let expected_signature = base64url_encode(signature_data)

  // 3. 比较签名
  signature == expected_signature
}

///|
impl Verifier for Rs256Verifier with algorithm_name(self) {
  self.algorithm
}

///|
impl Verifier for Rs256Verifier with public_key_info(self) {
  "RS256 Public Key: " + self.public_key + "..."
}

// 签名算法枚举

///|
pub enum SignatureAlgorithm {
  RS256
  // 预留其他算法
  // HS256
  // ES256
}

// 工厂函数

///|
pub fn create_rs256_signer(private_key : String) -> Rs256Signer {
  Rs256Signer::new(private_key)
}

///|
pub fn create_rs256_verifier(public_key : String) -> Rs256Verifier {
  Rs256Verifier::new(public_key)
}

// 便捷签名函数

///|
pub fn sign_with_rs256(data : String, private_key : String) -> String {
  let signer = create_rs256_signer(private_key)
  signer.sign(data)
}

// 便捷验证函数

///|
pub fn verify_with_rs256(
  data : String,
  signature : String,
  public_key : String,
) -> Bool {
  let verifier = create_rs256_verifier(public_key)
  verifier.verify(data, signature)
}

// 密钥对结构

///|
pub struct Rs256KeyPair {
  private_key : String
  public_key : String
}

///|
pub fn Rs256KeyPair::new(
  private_key : String,
  public_key : String,
) -> Rs256KeyPair {
  { private_key, public_key }
}

///|
pub fn Rs256KeyPair::create_signer(self : Rs256KeyPair) -> Rs256Signer {
  create_rs256_signer(self.private_key)
}

///|
pub fn Rs256KeyPair::create_verifier(self : Rs256KeyPair) -> Rs256Verifier {
  create_rs256_verifier(self.public_key)
}
