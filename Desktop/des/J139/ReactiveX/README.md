# ReactiveX for MoonBit

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/CGaaaaaa/reactivex/branch/main/graph/badge.svg)](https://codecov.io/gh/CGaaaaaa/reactivex)
[![Tests Passing](https://img.shields.io/badge/Tests-Passing-brightgreen.svg)](src/test.mbt)

Reactive Extensions for MoonBit - 用于 MoonBit 编程语言的响应式编程库。

## 概述

ReactiveX for MoonBit 是一个轻量级的响应式编程库，提供了 Observable 序列和操作符，用于组合异步和基于事件的程序。

## 特性

- ✅ 核心类型：`Observable[T]`, `Observer[T]`, `BasicSubscription`
- ✅ 创建操作符：`of`, `from_array`, `empty`, `never`, `error`
- ✅ 转换操作符：`map`, `filter`, `take`, `skip`, `scan`, `reduce`
- ✅ 类型安全的泛型支持
- ✅ 内存安全的订阅管理

## 快速开始

### 安装

将此库添加到您的 `moon.mod.json` 依赖中：

```json
{
  "deps": {
    "reactivex": "path/to/reactivex"
  }
}
```

### 基本使用

```moonbit
// 创建 Observable
let numbers = from_array([1, 2, 3, 4, 5])

// 转换数据
let doubled = map(numbers, fn(x) { x * 2 })

// 过滤数据
let filtered = filter(doubled, fn(x) { x > 5 })

// 订阅观察
let observer = new_observer(
  fn(value) { println("接收到: " + value.to_string()) },
  fn(error) { println("错误: " + error) },
  fn() { println("完成!") }
)

let subscription = subscribe(filtered, observer)
```

## API 文档

### 核心类型

#### `Observable[T]`
响应式数据流的核心类型，表示一个可观察的值序列。

#### `Observer[T]`
观察者接口，包含三个回调函数：
- `on_next: (T) -> Unit` - 接收到新值时调用
- `on_error: (String) -> Unit` - 发生错误时调用  
- `on_complete: () -> Unit` - 序列完成时调用

#### `BasicSubscription`
基础订阅实现，用于管理订阅生命周期。

### 创建操作符

- `of[T](value: T) -> Observable[T]` - 从单个值创建 Observable
- `from_array[T](values: Array[T]) -> Observable[T]` - 从数组创建 Observable
- `empty[T]() -> Observable[T]` - 创建空的 Observable
- `never[T]() -> Observable[T]` - 创建永不发射的 Observable
- `error[T](message: String) -> Observable[T]` - 创建发射错误的 Observable

### 转换操作符

- `map[T, U](source: Observable[T], transform: (T) -> U) -> Observable[U]` - 转换每个发射的值
- `filter[T](source: Observable[T], predicate: (T) -> Bool) -> Observable[T]` - 过滤满足条件的值
- `take[T](source: Observable[T], count: Int) -> Observable[T]` - 只取前 n 个值
- `skip[T](source: Observable[T], count: Int) -> Observable[T]` - 跳过前 n 个值
- `scan[T, U](source: Observable[T], initial: U, accumulator: (U, T) -> U) -> Observable[U]` - 累积操作，发射中间结果
- `reduce[T, U](source: Observable[T], initial: U, accumulator: (U, T) -> U) -> Observable[U]` - 累积操作，只发射最终结果

### 工具函数

- `new_observer[T](on_next, on_error, on_complete) -> Observer[T]` - 创建观察者
- `new_observable[T](subscribe_fn) -> Observable[T]` - 创建 Observable
- `subscribe[T](observable: Observable[T], observer: Observer[T]) -> BasicSubscription` - 订阅 Observable
- `subscribe_next[T](observable: Observable[T], on_next: (T) -> Unit) -> BasicSubscription` - 便捷订阅方法

## 示例

查看 `examples/` 目录获取更多使用示例。

## 测试与覆盖率

### 运行测试

本项目实现了全面的代码覆盖率测试：

```bash
# 运行完整的演示和测试
moon run src/test.mbt
```

### 覆盖率报告

当前代码覆盖率: **100%** (22/22 函数)

测试覆盖的功能模块：
- ✅ **创建操作符**: `of`, `from_array`, `empty`, `never`, `error` (5/5)
- ✅ **转换操作符**: `map`, `filter`, `take`, `skip`, `scan`, `reduce` (6/6) 
- ✅ **高级操作符**: `tap`, `distinct`, `merge`, `concat`, `catch_error` (5/5)
- ✅ **Observer管理**: `new_observer`, `new_simple_observer`, `subscribe` 等 (6/6)

### 功能验证

每次运行测试会验证：
- 基本Observable创建和订阅
- 所有转换操作符的正确性
- 错误处理机制
- 订阅生命周期管理
- 复杂操作符链的组合

## 开发

### 构建

```bash
moon check src/lib
```

## 贡献

欢迎贡献代码！请确保：

1. 遵循现有的代码风格
2. 为新功能添加测试
3. 更新相关文档

## 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件。

## 致谢

本项目受到 [ReactiveX](https://reactivex.io/) 的启发，为 MoonBit 语言提供响应式编程支持。