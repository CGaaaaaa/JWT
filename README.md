# JWT Library for MoonBit

[![CI](https://github.com/CGaaaaaa/JWT/actions/workflows/ci.yml/badge.svg)](https://github.com/CGaaaaaa/JWT/actions/workflows/ci.yml)

English | [中文](README_zh_CN.md)

A comprehensive JSON Web Token (JWT) library implemented in MoonBit, providing standardized cryptographic interfaces for secure information exchange.

## 📖 Overview

JWT (JSON Web Token) is a compact, URL-safe means of representing claims to be transferred between two parties. This library implements the JWT specification [RFC 7519](https://tools.ietf.org/html/rfc7519) with a focus on:

- **Secure Information Exchange**: Cryptographically signed tokens ensure data integrity
- **Standardized Interfaces**: Well-designed hash and signature algorithm interfaces
- **Extensible Architecture**: Easy to add new algorithms while maintaining compatibility

A JWT consists of three parts separated by dots (`.`):
- **Header**: Algorithm and token type
- **Payload**: Claims (data)
- **Signature**: Cryptographic verification

## ✨ Features

### Signature Algorithms
- **RS256**: RSA Signature with SHA-256 (primary implementation)
- **HS256**: HMAC with SHA-256
- Extensible interface for additional algorithms

### Hash Algorithms
- **SHA-256**: Secure Hash Algorithm 256-bit
- **MD5**: Message Digest Algorithm 5
- Standardized interface for hash operations

### JWT Operations
- Token creation with configurable claims
- Signature generation and verification
- Timestamp validation (exp, nbf, iat)
- Base64URL encoding/decoding

## 📁 Project Structure

```
JWT/
├── src/
│   ├── hash.mbt          # Hash algorithm implementation (SHA256, MD5)
│   ├── signature.mbt     # Signature algorithm implementation (HS256, RS256)
│   ├── jwt.mbt          # JWT core functionality
│   ├── lib.mbt          # Public library and utility functions
│   ├── test.mbt         # Test suite
│   └── moon.pkg.json    # Source package configuration
├── moon.mod.json        # Module configuration
└── README.md           # Documentation
```

## 🚀 Quick Start

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd JWT

# Run tests
moon test

# Build the project
moon build
```

### Basic Usage

#### Creating a JWT Token

```moonbit
// Quick JWT creation
let token = quick_jwt("user123", "my-service", 3600, private_key)

// JWT with audience
let token_with_aud = quick_jwt_with_audience(
  "user456", 
  "my-service", 
  7200, 
  "mobile-app", 
  private_key
)
```

#### Using JWT Builder Pattern

```moonbit
let builder = JwtBuilder::new("user789", "my-service", 1735689600, private_key)
let token = builder
  .with_audience("web-app")
  .with_not_before(1640995200)
  .with_key_id("key-001")
  .build()
```

#### JWT Verification

```moonbit
// Parse and verify token
match parse_jwt(token_string) {
  Some(jwt) => {
    if jwt.verify(public_key) {
      println("✅ JWT is valid")
      println("Subject: " + jwt.payload.sub)
      println("Issuer: " + jwt.payload.iss)
    } else {
      println("❌ JWT verification failed")
    }
  }
  None => println("❌ Invalid JWT format")
}

// Direct RS256 verification
if verify_rs256_jwt(token_string, public_key) {
  println("✅ JWT verified with RS256")
}
```

#### JWT Manager for Convenient Operations

```moonbit
// Create manager instance
let manager = JwtManager::new(private_key, public_key, "my-service")

// Create tokens
let user_token = manager.create_token("user123")
let app_token = manager.create_token_for_audience("user456", "mobile-app")
```

## 🔧 API Reference

### Core Types

#### JwtToken
```moonbit
struct JwtToken {
  header: JwtHeader
  payload: JwtPayload
  signature: String
}

// Methods
token.to_string() -> String
token.verify(public_key: String) -> Bool
```

#### JwtHeader
```moonbit
struct JwtHeader {
  alg: String      // Algorithm (e.g., "RS256")
  typ: String      // Type (typically "JWT")
  kid: Option[String]  // Key ID (optional)
}

// Creation
JwtHeader::new(algorithm: String, token_type: String) -> JwtHeader
JwtHeader::new_with_kid(algorithm: String, token_type: String, key_id: String) -> JwtHeader
```

#### JwtPayload
```moonbit
struct JwtPayload {
  sub: String           // Subject
  iss: String           // Issuer
  aud: Option[String]   // Audience
  exp: Int              // Expiration time
  nbf: Option[Int]      // Not before
  iat: Int              // Issued at
  jti: Option[String]   // JWT ID
}

// Validation
payload.is_valid(current_time: Int) -> Bool
payload.is_valid_for_audience(current_time: Int, expected_audience: String) -> Bool
```

### Hash Interface

```moonbit
enum HashAlgorithm {
  SHA256
  MD5
}

// Hash operations
compute_hash(data: String, algorithm: HashAlgorithm) -> String
verify_hash(data: String, expected_hash: String, algorithm: HashAlgorithm) -> Bool
multi_round_hash(data: String, rounds: Int, algorithm: HashAlgorithm) -> String
salted_hash(data: String, salt: String, algorithm: HashAlgorithm) -> String
```

### Signature Interface

```moonbit
// RS256 operations
sign_with_rs256(data: String, private_key: String) -> String
verify_with_rs256(data: String, signature: String, public_key: String) -> Bool

// Key pair management
struct Rs256KeyPair {
  private_key: String
  public_key: String
}

keypair.create_signer() -> Rs256Signer
keypair.create_verifier() -> Rs256Verifier
```

### Utility Functions

```moonbit
// Quick JWT creation
quick_jwt(subject: String, issuer: String, expires_in_hours: Int, private_key: String) -> String

// JWT with custom options
create_rs256_jwt(subject: String, issuer: String, expiration: Int, private_key: String) -> String
create_rs256_jwt_with_audience(subject: String, issuer: String, expiration: Int, audience: String, private_key: String) -> String

// Parsing and verification
parse_jwt(token_string: String) -> Option[JwtToken]
verify_rs256_jwt(token_string: String, public_key: String) -> Bool
```

## 🏗️ Architecture Design

### Standardized Interfaces

The library follows a modular design with clear separation of concerns:

```moonbit
// Hash algorithm interface
trait HashProvider {
  compute(data: String) -> String
  verify(data: String, hash: String) -> Bool
}

// Signature algorithm interface  
trait SignatureProvider {
  sign(data: String, private_key: String) -> String
  verify(data: String, signature: String, public_key: String) -> Bool
}
```

### Extensibility

Adding new algorithms is straightforward:

```moonbit
// Example: Adding HMAC-SHA512
enum HashAlgorithm {
  SHA256
  MD5
  SHA512  // New algorithm
}

// Example: Adding ES256 signature
enum SignatureAlgorithm {
  RS256
  HS256
  ES256   // New algorithm
}
```

## 🔐 Security Features

- **Cryptographic Integrity**: RS256 signature ensures token hasn't been tampered with
- **Timestamp Validation**: Automatic checking of token expiration and validity periods
- **Algorithm Verification**: Prevents algorithm confusion attacks
- **Input Validation**: Comprehensive validation of all inputs

## 🧪 Testing

Run the test suite:

```bash
moon test
```

The test suite covers:
- JWT creation and parsing
- Signature generation and verification
- Hash algorithm implementations
- Timestamp validation
- Edge cases and error handling

## 🔗 References

- **JWT Specification**: [RFC 7519](https://tools.ietf.org/html/rfc7519)
- **JWT Libraries**: [jwt.io/libraries](https://jwt.io/libraries)
- **Rust Hashes**: [RustCrypto/hashes](https://github.com/RustCrypto/hashes)
- **Signature Traits**: [docs.rs/signature](https://docs.rs/signature/latest/signature/)
- **MoonCakes MD5**: [mooncakes.io/docs/gmlewis/md5](https://mooncakes.io/docs/gmlewis/md5)

## 📄 License

This project is licensed under the Apache-2.0 License. 