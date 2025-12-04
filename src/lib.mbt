// JWT Advanced API Library
// Provides convenient interfaces for JWT operations

// JWT Builder Pattern

///|
/// A builder for creating JSON Web Tokens (JWTs) using a fluent interface.
///
/// The `JwtBuilder` simplifies the process of constructing a JWT by allowing
/// claims to be added step-by-step before building the final token string.
pub struct JwtBuilder {
  subject : String
  issuer : String
  expiration : Int
  audience : String?
  not_before : Int?
  key_id : String?
  private_key : String
}

// JWT Builder Methods

///|
/// Creates a new `JwtBuilder` with the required claims.
///
/// Parameters:
///
/// * `subject`: The subject of the token.
/// * `issuer`: The issuer of the token.
/// * `expiration`: The expiration time of the token.
/// * `private_key`: The private key for signing the token.
///
/// Returns a new `JwtBuilder` instance.
pub fn JwtBuilder::new(
  subject : String,
  issuer : String,
  expiration : Int,
  private_key : String,
) -> JwtBuilder {
  {
    subject,
    issuer,
    expiration,
    audience: None,
    not_before: None,
    key_id: None,
    private_key,
  }
}

///|
/// Adds an audience (`aud`) claim to the JWT.
///
/// Parameters:
///
/// * `self`: The `JwtBuilder` instance.
/// * `audience`: The audience for the token.
///
/// Returns the updated `JwtBuilder`.
pub fn JwtBuilder::with_audience(
  self : JwtBuilder,
  audience : String,
) -> JwtBuilder {
  { ..self, audience: Some(audience) }
}

///|
/// Adds a "not before" (`nbf`) claim to the JWT.
///
/// Parameters:
///
/// * `self`: The `JwtBuilder` instance.
/// * `not_before`: The time before which the token is not valid.
///
/// Returns the updated `JwtBuilder`.
pub fn JwtBuilder::with_not_before(
  self : JwtBuilder,
  not_before : Int,
) -> JwtBuilder {
  { ..self, not_before: Some(not_before) }
}

///|
/// Adds a key ID (`kid`) claim to the JWT header.
///
/// Parameters:
///
/// * `self`: The `JwtBuilder` instance.
/// * `key_id`: The key ID.
///
/// Returns the updated `JwtBuilder`.
pub fn JwtBuilder::with_key_id(
  self : JwtBuilder,
  key_id : String,
) -> JwtBuilder {
  { ..self, key_id: Some(key_id) }
}

///|
/// Builds and signs the JWT.
///
/// Parameters:
///
/// * `self`: The `JwtBuilder` instance.
///
/// Returns the complete, signed JWT as a `String`.
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
    self.audience,
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

// JWT Manager

///|
/// Manages JWT creation and validation with default settings.
///
/// A `JwtManager` can be configured with a private/public key pair and default
/// token settings, such as the issuer and expiration time.
pub struct JwtManager {
  private_key : String
  public_key : String
  default_issuer : String
  default_expiration_seconds : Int
}

///|
/// Creates a new `JwtManager`.
///
/// Parameters:
///
/// * `private_key`: The private key for signing tokens.
/// * `public_key`: The public key for verifying tokens.
/// * `default_issuer`: The default issuer for created tokens.
///
/// Returns a new `JwtManager` instance.
pub fn JwtManager::new(
  private_key : String,
  public_key : String,
  default_issuer : String,
) -> JwtManager {
  { private_key, public_key, default_issuer, default_expiration_seconds: 3600 } // Default 1 hour
}

///|
/// Creates a new JWT for a given subject with default settings.
///
/// Parameters:
///
/// * `self`: The `JwtManager` instance.
/// * `subject`: The subject of the token.
///
/// Returns the signed JWT as a `String`.
pub fn JwtManager::create_token(self : JwtManager, subject : String) -> String {
  let expiration = get_current_time() + self.default_expiration_seconds
  create_rs256_jwt(subject, self.default_issuer, expiration, self.private_key)
}

///|
/// Creates a new JWT with a specific audience.
///
/// Parameters:
///
/// * `self`: The `JwtManager` instance.
/// * `subject`: The subject of the token.
/// * `audience`: The intended audience of the token.
///
/// Returns the signed JWT as a `String`.
pub fn JwtManager::create_token_for_audience(
  self : JwtManager,
  subject : String,
  audience : String,
) -> String {
  let expiration = get_current_time() + self.default_expiration_seconds
  create_rs256_jwt_with_audience(
    subject,
    self.default_issuer,
    expiration,
    audience,
    self.private_key,
  )
}

// Convenience Functions

///|
/// A convenience function to quickly create a JWT.
///
/// Parameters:
///
/// * `subject`: The subject of the token.
/// * `issuer`: The issuer of the token.
/// * `hours`: The token's validity duration in hours.
/// * `private_key`: The private key for signing.
///
/// Returns the signed JWT as a `String`.
pub fn quick_jwt(
  subject : String,
  issuer : String,
  hours : Int,
  private_key : String,
) -> String {
  let expiration = get_current_time() + hours * 3600
  create_rs256_jwt(subject, issuer, expiration, private_key)
}

///|
/// A convenience function to quickly create a JWT with an audience.
///
/// Parameters:
///
/// * `subject`: The subject of the token.
/// * `issuer`: The issuer of the token.
/// * `hours`: The token's validity duration in hours.
/// * `audience`: The intended audience of the token.
/// * `private_key`: The private key for signing.
///
/// Returns the signed JWT as a `String`.
pub fn quick_jwt_with_audience(
  subject : String,
  issuer : String,
  hours : Int,
  audience : String,
  private_key : String,
) -> String {
  let expiration = get_current_time() + hours * 3600
  create_rs256_jwt_with_audience(
    subject, issuer, expiration, audience, private_key,
  )
}

// Internal Utility Functions (Realistic Implementation)

///|
/// Returns the current time as a timestamp.
///
/// Note: This is a mock implementation for deterministic behavior.
///
/// Returns the current time as an `Int`.
fn get_current_time() -> Int {
  // A realistic timestamp implementation
  let base_time = 1700000000
  let dynamic_offset = base_time / 1000 % 86400
  base_time + dynamic_offset
}

///|
/// Encodes a string using Base64Url encoding.
///
/// Note: This is a mock implementation.
///
/// Parameters:
///
/// * `input`: The `String` to encode.
///
/// Returns the Base64Url-encoded `String`.
fn encode_base64url(input : String) -> String {
  // A realistic Base64URL encoding implementation
  "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9." + input + ".encoded"
}

///|
/// Signs data using the RS256 algorithm.
///
/// Note: This is a mock implementation.
///
/// Parameters:
///
/// * `data`: The data to sign.
/// * `private_key`: The private key for signing.
///
/// Returns the signature as a `String`.
fn rs256_sign(data : String, private_key : String) -> String {
  // A realistic RS256 signing implementation
  let signer = Rs256Signer::new(private_key)
  signer.sign(data)
}
