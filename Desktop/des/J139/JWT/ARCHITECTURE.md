# JWT 库架构设计

## 概述

本项目使用 MoonBit 语言实现了一个 JWT (JSON Web Token) 库，重点展示了接口设计和 RS256 算法支持。项目采用模块化设计，通过特征接口实现算法的标准化和可扩展性。

## 架构设计原则

### 1. 接口抽象
- 使用特征(trait)定义算法接口
- 支持多种算法的统一调用
- 提供泛型编程支持

### 2. 模块分离
- 哈希算法模块：`hash.mbt`
- 签名算法模块：`signature.mbt`  
- JWT 核心模块：`jwt.mbt`
- 库接口模块：`lib.mbt`

### 3. 可扩展性
- 预留标准接口供新算法实现
- 支持插件式算法添加
- 类型安全的扩展机制

## 核心接口设计

### 哈希算法接口 (Hasher)

```moonbit
pub trait Hasher {
  /// 计算字符串的哈希值
  hash(Self, String) -> String
  
  /// 获取哈希算法名称
  algorithm_name(Self) -> String
  
  /// 获取输出哈希值的长度（字节数）
  output_size(Self) -> Int
}
```

**设计理念：**
- 统一的哈希计算接口
- 支持算法元数据查询
- 简洁的API设计

**实现的算法：**
- SHA-256：安全哈希算法
- MD5：演示用的传统算法

### 签名算法接口 (Signer)

```moonbit
pub trait Signer {
  /// 对消息进行签名
  sign(Self, String) -> String
  
  /// 验证签名
  verify(Self, String, String) -> Bool
  
  /// 获取算法名称
  algorithm_name(Self) -> String
}
```

**设计理念：**
- 签名和验证的统一接口
- 支持不同的签名算法
- 类型安全的签名操作

**实现的算法：**
- RS256：RSA + SHA-256 签名算法

## JWT 架构

### 数据结构设计

```moonbit
/// JWT 头部信息
pub struct JwtHeader {
  alg : String  // 算法类型
  typ : String  // 令牌类型
}

/// JWT 载荷信息  
pub struct JwtPayload {
  sub : String  // 主题
  iss : String  // 发行者
  exp : Int     // 过期时间
  iat : Int     // 发行时间
}

/// 完整的 JWT 结构
pub struct Jwt {
  header : JwtHeader
  payload : JwtPayload
  signature : String
}
```

### JWT 编解码器

```moonbit
pub struct JwtCodec {
  signer : String  // 签名器标识
}
```

**功能：**
- JWT 令牌编码
- JWT 令牌验证
- JSON 序列化
- Base64 URL 编码

## 扩展点设计

### 1. 新哈希算法扩展

添加新的哈希算法只需实现 `Hasher` 特征：

```moonbit
pub struct Sha3 {
  name : String
}

impl Hasher for Sha3 with hash(self, input) {
  // SHA-3 实现
}

impl Hasher for Sha3 with algorithm_name(self) {
  "SHA-3"
}

impl Hasher for Sha3 with output_size(self) {
  32
}
```

### 2. 新签名算法扩展

添加新的签名算法只需实现 `Signer` 特征：

```moonbit
pub struct Es256Signer {
  ecdsa_key : EcdsaKey
}

impl Signer for Es256Signer with sign(self, message) {
  // ECDSA P-256 + SHA-256 实现
}

impl Signer for Es256Signer with verify(self, message, signature) {
  // ECDSA 验证实现
}

impl Signer for Es256Signer with algorithm_name(self) {
  "ES256"
}
```

### 3. JWT 功能扩展

可以扩展更多的 JWT 标准声明：

```moonbit
pub struct ExtendedJwtPayload {
  // 标准声明
  sub : String
  iss : String
  exp : Int
  iat : Int
  
  // 扩展声明
  aud : String    // 受众
  nbf : Int       // 生效时间
  jti : String    // JWT ID
  
  // 自定义声明
  roles : Array[String]
  permissions : Array[String]
}
```

## 泛型编程支持

项目提供泛型函数支持不同算法的统一使用：

```moonbit
/// 通用哈希函数
pub fn compute_hash[H : Hasher](hasher : H, input : String) -> String {
  hasher.hash(input)
}

/// 通用签名函数
pub fn sign_message[S : Signer](signer : S, message : String) -> String {
  signer.sign(message)
}

/// 通用验证函数
pub fn verify_signature[S : Signer](signer : S, message : String, signature : String) -> Bool {
  signer.verify(message, signature)
}
```

## 类型安全设计

### 1. 强类型约束
- 所有接口都有明确的类型签名
- 编译时类型检查
- 特征约束确保正确实现

### 2. 不可变数据结构
- JWT 组件使用不可变结构体
- 减少状态管理复杂性
- 提高并发安全性

### 3. 错误处理
虽然当前实现简化了错误处理，但架构支持添加更完善的错误处理：

```moonbit
// 未来可以添加的错误类型
enum JwtError {
  InvalidToken
  ExpiredToken
  InvalidSignature
  UnsupportedAlgorithm
}

// 带错误处理的接口
trait SecureHasher {
  hash_secure(Self, String) -> Result[String, HashError]
}
```

## 性能考虑

### 1. 零拷贝设计
- 字符串操作避免不必要的复制
- 结构体字段直接访问
- 高效的内存使用

### 2. 算法选择
- SHA-256：平衡安全性和性能
- RSA：广泛支持，适合 JWT
- 预留更高效算法接口

### 3. 缓存机制
可以添加签名验证缓存：

```moonbit
pub struct CachedSigner[S : Signer] {
  inner : S
  cache : Map[String, Bool]
}
```

## 安全考虑

### 1. 算法安全性
- 使用现代安全算法
- 禁用不安全的算法
- 支持算法升级路径

### 2. 密钥管理
- 支持不同的密钥类型
- 密钥轮换机制
- 安全的密钥存储

### 3. 时间验证
- 过期时间检查
- 时钟偏移容忍
- 重放攻击防护

## 总结

这个 JWT 库架构展示了：

1. **清晰的接口设计**：通过特征定义统一的算法接口
2. **良好的扩展性**：支持新算法的无缝添加
3. **类型安全**：利用 MoonBit 的类型系统确保正确性
4. **模块化设计**：职责分离，便于维护
5. **标准化实现**：为 MoonBit 生态提供参考

通过这种设计，为 MoonBit 语言构建密码学库和认证系统提供了一个可靠的基础框架。 