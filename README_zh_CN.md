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

## ✨ 功能特性

### 签名算法
- **RS256**：使用 SHA-256 的 RSA 签名（主要实现）
- **HS256**：使用 SHA-256 的 HMAC
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
│   ├── lib.mbt          # 公共库和工具函数
│   ├── test.mbt         # 测试套件
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

#### 创建 JWT 令牌

```moonbit
// 快速创建 JWT
let token = quick_jwt("user123", "my-service", 3600, private_key)

// 带受众的 JWT
let token_with_aud = quick_jwt_with_audience(
  "user456", 
  "my-service", 
  7200, 
  "mobile-app", 
  private_key
)
```

#### 使用 JWT 构建器模式

```moonbit
let builder = JwtBuilder::new("user789", "my-service", 1735689600, private_key)
let token = builder
  .with_audience("web-app")
  .with_not_before(1640995200)
  .with_key_id("key-001")
  .build()
```

#### JWT 验证

```moonbit
// 解析和验证令牌
match parse_jwt(token_string) {
  Some(jwt) => {
    if jwt.verify(public_key) {
      println("✅ JWT 有效")
      println("主体: " + jwt.payload.sub)
      println("签发者: " + jwt.payload.iss)
    } else {
      println("❌ JWT 验证失败")
    }
  }
  None => println("❌ 无效的 JWT 格式")
}

// 直接 RS256 验证
if verify_rs256_jwt(token_string, public_key) {
  println("✅ JWT 通过 RS256 验证")
}
```

#### JWT 管理器便捷操作

```moonbit
// 创建管理器实例
let manager = JwtManager::new(private_key, public_key, "my-service")

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
// RS256 操作
sign_with_rs256(data: String, private_key: String) -> String
verify_with_rs256(data: String, signature: String, public_key: String) -> Bool

// 密钥对管理
struct Rs256KeyPair {
  private_key: String
  public_key: String
}

keypair.create_signer() -> Rs256Signer
keypair.create_verifier() -> Rs256Verifier
```

### 工具函数

```moonbit
// 快速 JWT 创建
quick_jwt(subject: String, issuer: String, expires_in_hours: Int, private_key: String) -> String

// 自定义选项的 JWT
create_rs256_jwt(subject: String, issuer: String, expiration: Int, private_key: String) -> String
create_rs256_jwt_with_audience(subject: String, issuer: String, expiration: Int, audience: String, private_key: String) -> String

// 解析和验证
parse_jwt(token_string: String) -> Option[JwtToken]
verify_rs256_jwt(token_string: String, public_key: String) -> Bool
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