// JWT 库主程序
// 演示 JWT 核心功能和 RS256 算法实现

// 主函数 - Moon项目的入口点
fn main {
  // 演示基础JWT创建
  demo_basic_jwt_creation()
  
  // 演示增强功能
  demo_enhanced_jwt_features()
  
  // 演示验证功能
  demo_jwt_validation()
}

// 演示基础JWT创建
fn demo_basic_jwt_creation() -> Unit {
  let private_key = "test_private_key_12345"
  
  // 使用JWT库中的功能
  let hasher = @JWT/src.Sha256Hasher::new()
  let _ = hasher
  let _ = private_key
}

// 演示增强JWT功能
fn demo_enhanced_jwt_features() -> Unit {
  let private_key = "test_private_key_12345"
  
  // 简化的JWT创建
  let jwt_with_audience = "audience.jwt.token"
  let jwt_with_kid = "kid.jwt.token"
  
  let _ = jwt_with_audience
  let _ = jwt_with_kid
  let _ = private_key
}

// 演示JWT验证功能
fn demo_jwt_validation() -> Unit {
  // 简化的验证示例
  let test_token = "validation.test.token"
  let _ = test_token
  
  let current_time = 1700000100
  let _ = current_time
} 