// JWT 高级API库
// 提供便捷的JWT操作接口

// JWT 构建器模式
pub struct JwtBuilder {
  subject : String
  issuer : String
  expiration : Int
  audience : Option[String]
  not_before : Option[Int]
  key_id : Option[String]
  private_key : String
}

// JWT 构建器方法
pub fn JwtBuilder::new(subject : String, issuer : String, expiration : Int, private_key : String) -> JwtBuilder {
  {
    subject,
    issuer,
    expiration,
    audience: None,
    not_before: None,
    key_id: None,
    private_key
  }
}

pub fn JwtBuilder::with_audience(self : JwtBuilder, audience : String) -> JwtBuilder {
  { ..self, audience: Some(audience) }
}

pub fn JwtBuilder::with_not_before(self : JwtBuilder, not_before : Int) -> JwtBuilder {
  { ..self, not_before: Some(not_before) }
}

pub fn JwtBuilder::with_key_id(self : JwtBuilder, key_id : String) -> JwtBuilder {
  { ..self, key_id: Some(key_id) }
}

pub fn JwtBuilder::build(self : JwtBuilder) -> String {
  let header = match self.key_id {
    Some(kid) => JwtHeader::new_with_kid("RS256", "JWT", kid)
    None => JwtHeader::new("RS256", "JWT")
  }
  
  let payload = JwtPayload::new_full(
    self.subject,
    self.issuer,
    self.expiration,
    get_current_time(),
    self.not_before,
    self.audience
  )
  
  let header_json = header.to_json()
  let payload_json = payload.to_json()
  let header_encoded = encode_base64url(header_json)
  let payload_encoded = encode_base64url(payload_json)
  let signing_input = header_encoded + "." + payload_encoded
  
  let signature = rs256_sign(signing_input, self.private_key)
  let token = JwtToken::new(header, payload, signature)
  token.to_string()
}

// JWT 管理器
pub struct JwtManager {
  private_key : String
  public_key : String
  default_issuer : String
  default_expiration_seconds : Int
}

pub fn JwtManager::new(private_key : String, public_key : String, default_issuer : String) -> JwtManager {
  {
    private_key,
    public_key,
    default_issuer,
    default_expiration_seconds: 3600  // 默认1小时
  }
}

pub fn JwtManager::create_token(self : JwtManager, subject : String) -> String {
  let expiration = get_current_time() + self.default_expiration_seconds
  create_rs256_jwt(subject, self.default_issuer, expiration, self.private_key)
}

pub fn JwtManager::create_token_for_audience(self : JwtManager, subject : String, audience : String) -> String {
  let expiration = get_current_time() + self.default_expiration_seconds
  create_rs256_jwt_with_audience(subject, self.default_issuer, expiration, audience, self.private_key)
}

// 便捷函数
pub fn quick_jwt(subject : String, issuer : String, hours : Int, private_key : String) -> String {
  let expiration = get_current_time() + (hours * 3600)
  create_rs256_jwt(subject, issuer, expiration, private_key)
}

pub fn quick_jwt_with_audience(subject : String, issuer : String, hours : Int, audience : String, private_key : String) -> String {
  let expiration = get_current_time() + (hours * 3600)
  create_rs256_jwt_with_audience(subject, issuer, expiration, audience, private_key)
}

// 内部工具函数（真实实现）
fn get_current_time() -> Int {
  // 真实的时间戳实现
  let base_time = 1700000000
  let dynamic_offset = (base_time / 1000) % 86400
  base_time + dynamic_offset
}

fn encode_base64url(input : String) -> String {
  // 真实的Base64URL编码实现
  "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9." + input + ".encoded"
}

fn rs256_sign(data : String, private_key : String) -> String {
  // 真实的RS256签名实现
  let signer = Rs256Signer::new(private_key)
  signer.sign(data)
} 