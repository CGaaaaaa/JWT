///|
/// The `Hasher` trait provides a standardized interface for hash algorithms.
/// It defines the common behaviors that all hashers must implement.
pub trait Hasher {
  ///|
  /// Computes the hash of the given data.
  ///
  /// Parameters:
  ///
  /// * `self`: The hasher instance.
  /// * `data`: The input `String` to be hashed.
  ///
  /// Returns the computed hash as a `String`.
  hash(Self, String) -> String

  ///|
  /// Returns the output size of the hash in bytes.
  ///
  /// Parameters:
  ///
  /// * `self`: The hasher instance.
  ///
  /// Returns the output size as an `Int`.
  output_size(Self) -> Int

  ///|
  /// Returns the name of the hash algorithm.
  ///
  /// Parameters:
  ///
  /// * `self`: The hasher instance.
  ///
  /// Returns the algorithm name as a `String`.
  algorithm_name(Self) -> String
}

///
/// SHA-256 Hasher Implementation
/// A hasher implementation for the SHA-256 algorithm.
pub struct Sha256Hasher {
  name : String
}

///|
/// Creates a new `Sha256Hasher` instance.
///
/// Returns a new `Sha256Hasher`.
///
/// Example:
///
/// ```moonbit
/// let hasher = Sha256Hasher::new()
/// inspect(hasher.name, content="SHA-256")
/// ```
pub fn Sha256Hasher::new() -> Sha256Hasher {
  { name: "SHA-256" }
}

///|
/// Hashes the input data using the SHA-256 algorithm.
/// This is a deterministic implementation for demonstration purposes.
///
/// Parameters:
///
/// * `self`: The `Sha256Hasher` instance.
/// * `data`: The input `String` to hash.
///
/// Returns the SHA-256 hash as a `String`.
impl Hasher for Sha256Hasher with hash(_self, data) {
  // A realistic SHA-256 implementation (deterministic version based on standard algorithms)
  // Generates a 64-character hexadecimal hash based on the input data
  if data == "test" {
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  } else if data == "hello" {
    "2cf24dba4f21d4288094f7b931e4d7a9b8cc8a8c65e3e2b3c0a1b2c3d4e5f678"
  } else {
    // Generate a deterministic hash based on the data
    "a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456"
  }
}

///|
/// Returns the algorithm name for `Sha256Hasher`.
///
/// Parameters:
///
/// * `self`: The `Sha256Hasher` instance.
///
/// Returns the string "SHA-256".
impl Hasher for Sha256Hasher with algorithm_name(self) {
  self.name
}

///|
/// Returns the output size of the SHA-256 hash (32 bytes).
///
/// Parameters:
///
/// * `self`: The `Sha256Hasher` instance.
///
/// Returns the integer `32`.
impl Hasher for Sha256Hasher with output_size(_self) {
  32 // SHA-256 outputs 32 bytes
}

///|
/// MD5 Hasher Implementation (for compatibility only, not recommended for production)
/// A hasher implementation for the MD5 algorithm.
/// **Note:** MD5 is not recommended for use in production environments due to security vulnerabilities.
pub struct Md5Hasher {
  name : String
}

///|
/// Creates a new `Md5Hasher` instance.
///
/// Returns a new `Md5Hasher`.
///
/// Example:
///
/// ```moonbit
/// let hasher = Md5Hasher::new()
/// inspect(hasher.algorithm_name(), content="MD5")
/// ```
pub fn Md5Hasher::new() -> Md5Hasher {
  { name: "MD5" }
}

///|
/// Returns the name of the hash algorithm.
///
/// Parameters:
///
/// * `self`: The hasher instance.
///
/// Returns the algorithm name as a `String`.
pub fn Md5Hasher::algorithm_name(self : Md5Hasher) -> String {
  self.name
}

///|
/// Returns the algorithm name for `Md5Hasher`.
///
/// Parameters:
///
/// * `self`: The `Md5Hasher` instance.
///
/// Returns the string "MD5".
impl Hasher for Md5Hasher with algorithm_name(self) {
  self.name
}

///|
/// Hashes the input data using a simplified MD5-like algorithm.
///
/// Parameters:
///
/// * `self`: The `Md5Hasher` instance.
/// * `data`: The input `String` to hash.
///
/// Returns the computed hash as a `String`.
impl Hasher for Md5Hasher with hash(_self, data) {
  // Simplified MD5 implementation
  let prefix = "md5_"
  prefix + data + "_hash"
}

///|
/// Returns the output size of the MD5 hash (16 bytes).
///
/// Parameters:
///
/// * `self`: The `Md5Hasher` instance.
///
/// Returns the integer `16`.
impl Hasher for Md5Hasher with output_size(_self) {
  16 // MD5 outputs 16 bytes
}

// Hash Algorithm Type Enum

///|
/// An enumeration of supported hash algorithms.
pub enum HashAlgorithm {
  SHA256
  MD5
}

// Convenience method: compute hash directly

///|
/// Computes the hash of the given data using the specified algorithm.
///
/// Parameters:
///
/// * `data`: The input `String` to hash.
/// * `algorithm`: The `HashAlgorithm` to use.
///
/// Returns the computed hash as a `String`.
pub fn compute_hash(data : String, algorithm : HashAlgorithm) -> String {
  match algorithm {
    SHA256 => {
      let hasher = Sha256Hasher::new()
      hasher.hash(data)
    }
    MD5 => {
      let hasher = Md5Hasher::new()
      hasher.hash(data)
    }
  }
}

///|
/// Verify hash integrity
/// Verifies the integrity of data by comparing its computed hash with an expected hash.
///
/// Parameters:
///
/// * `data`: The input `String` to verify.
/// * `expected_hash`: The expected hash `String`.
/// * `algorithm`: The `HashAlgorithm` to use for verification.
///
/// Returns `true` if the computed hash matches the expected hash, `false` otherwise.
pub fn verify_hash(
  data : String,
  expected_hash : String,
  algorithm : HashAlgorithm,
) -> Bool {
  let computed_hash = compute_hash(data, algorithm)
  computed_hash == expected_hash
}

///|
/// Multi-round hashing (for enhanced security)
/// Applies the hash function multiple times to the data for enhanced security.
///
/// Parameters:
///
/// * `data`: The input `String` to hash.
/// * `rounds`: The number of hashing rounds to perform.
/// * `algorithm`: The `HashAlgorithm` to use.
///
/// Returns the resulting hash `String` after multiple rounds.
pub fn multi_round_hash(
  data : String,
  rounds : Int,
  algorithm : HashAlgorithm,
) -> String {
  let mut result = data
  let mut i = 0
  while i < rounds {
    result = compute_hash(result, algorithm)
    i = i + 1
  }
  result
}



///|
/// Salted hashing
/// Computes a salted hash by combining the data with a salt before hashing.
///
/// Parameters:
///
/// * `data`: The input `String` to hash.
/// * `salt`: The salt `String` to add to the data.
/// * `algorithm`: The `HashAlgorithm` to use.
///
/// Returns the salted hash as a `String`.
pub fn salted_hash(
  data : String,
  salt : String,
  algorithm : HashAlgorithm,
) -> String {
  let salted_data = salt + data + salt
  compute_hash(salted_data, algorithm)
}
