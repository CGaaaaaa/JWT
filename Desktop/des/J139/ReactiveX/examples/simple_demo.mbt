/// 简单演示 - 复制 working_example.mbt 的核心部分
/// 
/// 这个文件展示了 ReactiveX for MoonBit 的基本用法

// Observable 类型定义（简化版）
struct SimpleObservable[T] {
  emit_fn : ((T) -> Unit) -> Unit
}

fn[T] simple_of(value : T) -> SimpleObservable[T] {
  { emit_fn: fn(callback) { callback(value) } }
}

fn[T] simple_subscribe(obs : SimpleObservable[T], callback : (T) -> Unit) -> Unit {
  (obs.emit_fn)(callback)
}

fn main {
  println("=== 简单的 ReactiveX 演示 ===")
  
  let observable = simple_of(42)
  simple_subscribe(observable, fn(value) {
    println("接收到: \{value}")
  })
  
  println("=== 演示完成 ===")
}