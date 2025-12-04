# JWT Library for MoonBit

[![CI](https://github.com/CGaaaaaa/JWT/actions/workflows/ci.yml/badge.svg)](https://github.com/CGaaaaaa/JWT/actions/workflows/ci.yml)

[English](README.md) | 中文

一个用 MoonBit 实现的综合性 JSON Web Token (JWT) 库，提供标准化的加密接口，用于安全的信息交换。

## 📖 概述

JWT (JSON Web Token) 是一种紧凑的、URL安全的方式，用于在两方之间传输声明。本库实现了 JWT 规范 [RFC 7519](https://tools.ietf.org/html/rfc7519)，重点关注：

- **安全信息交换**：密码学签名的令牌确保数据完整性
- **标准化接口**：精心设计的哈希和签名算法接口
- **可扩展架构**：在保持兼容性的同时易于添加新算法

JWT 由三个用点（`.`）分隔的部分组成：
- **头部（Header）**：算法和令牌类型
- **载荷（Payload）**：声明（数据）
- **签名（Signature）**：密码学验证

## ⚠️ 重要说明

**密码学实现状态（RS256）：**

- ✅ 真实的端到端 RS256：包含大整数（BigInt）运算、模幂、PKCS#1 v1.5 EMSA（SHA-256）以及 Base64URL，全为 MoonBit 实现，无“模拟/简化”。
- ✅ SHA-256 与 HMAC-SHA256 符合规范；Base64URL 严格遵循 RFC 4648（URL-safe、无填充）。
- ✅ JWT 结构、解析与声明校验符合 RFC 7519。

**当前限制（非密码学）：**
- ⚠️ 时间源为测试稳定性而采用确定性值；需要时可替换为真实系统时间。
- ⚠️ 未包含 PEM/PKCS8 解析；密钥通过 JWK 组件（`n`、`e`、`d` 的 Base64URL）提供。
- ⚠️ MD5 仅用于兼容性演示，不用于安全场景。

生产使用建议按需完善密钥管理、替换真实时间源、补充 PEM 解析，并进行安全审计。

## ✨ 功能特性

### 签名算法
- **RS256**：使用 SHA-256 的 RSA 签名（PKCS#1 v1.5）——真实实现
- **HS256**：使用 SHA-256 的 HMAC —— 真实实现
- 可扩展的算法接口

### 哈希算法
- **SHA-256**：256位安全哈希算法
- **MD5**：消息摘要算法 5
- 标准化的哈希操作接口

### JWT 操作
- 可配置声明的令牌创建
- 签名生成和验证
- 时间戳验证（exp, nbf, iat）
- Base64URL 编码/解码

## 📁 项目结构

```
JWT/
├── src/
│   ├── hash.mbt          # 哈希算法实现 (SHA256, MD5)
│   ├── signature.mbt     # 签名算法实现 (HS256, RS256)
│   ├── jwt.mbt          # JWT核心功能
│   ├── base64.mbt       # Base64 URL 编码/解码 (RFC 4648)
│   ├── lib.mbt          # 公共库和工具函数
│   ├── jwt_test.mbt     # JWT测试套件
│   ├── base64_test.mbt  # Base64测试套件
│   └── moon.pkg.json    # 源码包配置
├── moon.mod.json        # 模块配置
└── README.md           # 文档
```

## 🚀 快速开始

### 安装

```bash
# 克隆仓库
git clone <repository-url>
cd JWT

# 运行测试
moon test

# 构建项目
moon build
```

### 基本用法

#### 创建 JWT（RS256，JWK n/d）

```moonbit
// 使用 JWK（n、d 为 Base64URL）快速创建 RS256 JWT
let token = quick_jwt("user123", "my-service", 3600, n_b64url, d_b64url)

// 带受众
let token_with_aud = quick_jwt_with_audience(
  "user456",
  "my-service",
  7200,
  "mobile-app",
  n_b64url,
  d_b64url,
)
```

#### 使用构建器（RS256，JWK）

```moonbit
let builder = JwtBuilder::new("user789", "my-service", 1735689600, n_b64url, d_b64url)
let token = builder
  .with_audience("web-app")
  .with_not_before(1640995200)
  .with_key_id("key-001")
  .build()
```

#### 验证（RS256，JWK n/e）

```moonbit
// 解析并使用 n/e 进行验证
match parse_jwt(token_string) {
  Some(_jwt) => {
    if verify_rs256_jwt_jwk(token_string, n_b64url, e_b64url) {
      println("✅ JWT 有效")
    } else {
      println("❌ JWT 验证失败")
    }
  }
  None => println("❌ 无效的 JWT 格式")
}
```

#### JWT 管理器（RS256，JWK）

```moonbit
// 使用 JWK 组件创建管理器
let manager = JwtManager::new(n_b64url, e_b64url, d_b64url, "my-service")

// 创建令牌
let user_token = manager.create_token("user123")
let app_token = manager.create_token_for_audience("user456", "mobile-app")
```

## 🔧 API 参考

### 核心类型

#### JwtToken
```moonbit
struct JwtToken {
  header: JwtHeader
  payload: JwtPayload
  signature: String
}

// 方法
token.to_string() -> String
token.verify(public_key: String) -> Bool
```

#### JwtHeader
```moonbit
struct JwtHeader {
  alg: String      // 算法 (例如 "RS256")
  typ: String      // 类型 (通常是 "JWT")
  kid: Option[String]  // 密钥 ID (可选)
}

// 创建
JwtHeader::new(algorithm: String, token_type: String) -> JwtHeader
JwtHeader::new_with_kid(algorithm: String, token_type: String, key_id: String) -> JwtHeader
```

#### JwtPayload
```moonbit
struct JwtPayload {
  sub: String           // 主体
  iss: String           // 签发者
  aud: Option[String]   // 受众
  exp: Int              // 过期时间
  nbf: Option[Int]      // 生效时间
  iat: Int              // 签发时间
  jti: Option[String]   // JWT ID
}

// 验证
payload.is_valid(current_time: Int) -> Bool
payload.is_valid_for_audience(current_time: Int, expected_audience: String) -> Bool
```

### 哈希接口

```moonbit
enum HashAlgorithm {
  SHA256
  MD5
}

// 哈希操作
compute_hash(data: String, algorithm: HashAlgorithm) -> String
verify_hash(data: String, expected_hash: String, algorithm: HashAlgorithm) -> Bool
multi_round_hash(data: String, rounds: Int, algorithm: HashAlgorithm) -> String
salted_hash(data: String, salt: String, algorithm: HashAlgorithm) -> String
```

### 签名接口

```moonbit
// RS256 操作（JWK）
sign_with_rs256_jwk(data: String, n_b64url: String, d_b64url: String) -> String
verify_with_rs256_jwk(data: String, signature_b64url: String, n_b64url: String, e_b64url: String) -> Bool

// JWT 便捷方法
create_rs256_jwt_jwk(subject: String, issuer: String, expiration: Int, n_b64url: String, d_b64url: String) -> String
create_rs256_jwt_with_audience_jwk(subject: String, issuer: String, expiration: Int, audience: String, n_b64url: String, d_b64url: String) -> String
verify_rs256_jwt_jwk(token_string: String, n_b64url: String, e_b64url: String) -> Bool

// 密钥对管理
struct Rs256KeyPair {
  n_b64url: String
  e_b64url: String
  d_b64url: String
}

keypair.create_signer() -> Rs256Signer
keypair.create_verifier() -> Rs256Verifier
```

### 工具函数

```moonbit
// 快速 JWT 创建（RS256，JWK）
quick_jwt(subject: String, issuer: String, expires_in_hours: Int, n_b64url: String, d_b64url: String) -> String
quick_jwt_with_audience(subject: String, issuer: String, expires_in_hours: Int, audience: String, n_b64url: String, d_b64url: String) -> String

// 自定义选项（RS256，JWK）
create_rs256_jwt_jwk(subject: String, issuer: String, expiration: Int, n_b64url: String, d_b64url: String) -> String
create_rs256_jwt_with_audience_jwk(subject: String, issuer: String, expiration: Int, audience: String, n_b64url: String, d_b64url: String) -> String

// 解析和验证
parse_jwt(token_string: String) -> Option[JwtToken]
verify_rs256_jwt_jwk(token_string: String, n_b64url: String, e_b64url: String) -> Bool
```

## 🏗️ 架构设计

### 标准化接口

库采用模块化设计，清晰分离关注点：

```moonbit
// 哈希算法接口
trait HashProvider {
  compute(data: String) -> String
  verify(data: String, hash: String) -> Bool
}

// 签名算法接口  
trait SignatureProvider {
  sign(data: String, private_key: String) -> String
  verify(data: String, signature: String, public_key: String) -> Bool
}
```

### 可扩展性

添加新算法很简单：

```moonbit
// 示例：添加 HMAC-SHA512
enum HashAlgorithm {
  SHA256
  MD5
  SHA512  // 新算法
}

// 示例：添加 ES256 签名
enum SignatureAlgorithm {
  RS256
  HS256
  ES256   // 新算法
}
```

## 🔐 安全特性

- **密码学完整性**：RS256 签名确保令牌未被篡改
- **时间戳验证**：自动检查令牌过期和有效期
- **算法验证**：防止算法混淆攻击
- **输入验证**：全面验证所有输入

## 🧪 测试

运行测试套件：

```bash
moon test
```

测试套件涵盖：
- JWT 创建和解析
- 签名生成和验证
- 哈希算法实现
- 时间戳验证
- 边界情况和错误处理

## 🔗 参考资料

- **JWT 规范**：[RFC 7519](https://tools.ietf.org/html/rfc7519)
- **JWT 库**：[jwt.io/libraries](https://jwt.io/libraries)
- **Rust 哈希库**：[RustCrypto/hashes](https://github.com/RustCrypto/hashes)
- **签名特性**：[docs.rs/signature](https://docs.rs/signature/latest/signature/)
- **MoonCakes MD5**：[mooncakes.io/docs/gmlewis/md5](https://mooncakes.io/docs/gmlewis/md5)

## 📄 许可证

本项目采用 Apache-2.0 许可证。 