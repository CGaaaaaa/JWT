/// ReactiveX for MoonBit 
/// 
/// 响应式编程库的完整实现

/// 错误类型定义
pub enum RxError {
  RuntimeError(String)
  OperatorError(String)
  SubscriptionError(String)
  TimeoutError(String)
}

/// Observer - 观察者
pub struct Observer[T] {
  on_next : (T) -> Unit
  on_error : (RxError) -> Unit  
  on_complete : () -> Unit
}

/// 基础订阅管理
pub struct BasicSubscription {
  mut subscribed : Bool
}

/// Observable - ReactiveX 的核心类型
pub struct Observable[T] {
  subscribe_fn : (Observer[T]) -> BasicSubscription
}

/// 创建 Observer
pub fn[T] new_observer(
  on_next : (T) -> Unit, 
  on_error : (RxError) -> Unit, 
  on_complete : () -> Unit
) -> Observer[T] {
  { on_next, on_error, on_complete }
}

/// 便捷的 Observer 创建函数 (字符串错误)
pub fn[T] new_simple_observer(
  on_next : (T) -> Unit, 
  on_error : (String) -> Unit, 
  on_complete : () -> Unit
) -> Observer[T] {
  { 
    on_next, 
    on_error: fn(err) { 
      match err {
        RuntimeError(msg) | OperatorError(msg) | SubscriptionError(msg) | TimeoutError(msg) => on_error(msg)
      }
    }, 
    on_complete 
  }
}

/// 创建 BasicSubscription
pub fn new_subscription() -> BasicSubscription {
  { subscribed: true }
}

/// 检查订阅状态
pub fn is_subscribed(self : BasicSubscription) -> Bool {
  self.subscribed
}

/// 取消订阅
pub fn unsubscribe(self : BasicSubscription) -> Unit {
  self.subscribed = false
}

/// 创建 Observable
pub fn[T] new_observable(subscribe_fn : (Observer[T]) -> BasicSubscription) -> Observable[T] {
  { subscribe_fn: subscribe_fn }
}

/// 订阅 Observable
pub fn[T] subscribe(self : Observable[T], observer : Observer[T]) -> BasicSubscription {
  (self.subscribe_fn)(observer)
}

/// 便捷订阅方法
pub fn[T] subscribe_next(self : Observable[T], on_next : (T) -> Unit) -> BasicSubscription {
  let observer = new_simple_observer(
    on_next,
    fn(error) { println("Error: " + error) },
    fn() { println("Completed") }
  )
  self.subscribe(observer)
}

// ===== 创建操作符 =====

/// 从单个值创建 Observable
pub fn[T] of(value : T) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_next)(value)
      (observer.on_complete)()
    }
    subscription
  })
}

/// 从多个值创建 Observable
pub fn[T] from_array(values : Array[T]) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    for i = 0; i < values.length() && subscription.is_subscribed(); i = i + 1 {
      (observer.on_next)(values[i])
    }
    if subscription.is_subscribed() {
      (observer.on_complete)()
    }
    subscription
  })
}

/// 创建空的 Observable
pub fn[T] empty() -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_complete)()
    }
    subscription
  })
}

/// 创建永不发射的 Observable
pub fn[T] never() -> Observable[T] {
  new_observable(fn(_observer) {
    new_subscription()
  })
}

/// 创建发射错误的 Observable
pub fn[T] error(error_message : String) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_error)(RuntimeError(error_message))
    }
    subscription
  })
}

/// 创建发射特定错误类型的 Observable
pub fn[T] error_with_type(rx_error : RxError) -> Observable[T] {
  new_observable(fn(observer) {
    let subscription = new_subscription()
    if subscription.is_subscribed() {
      (observer.on_error)(rx_error)
    }
    subscription
  })
}

// ===== 转换操作符 =====

/// map 操作符 - 转换每个发射的值
pub fn[T, U] map(source : Observable[T], transform : (T) -> U) -> Observable[U] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) { (observer.on_next)(transform(value)) },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// filter 操作符 - 过滤满足条件的值
pub fn[T] filter(source : Observable[T], predicate : (T) -> Bool) -> Observable[T] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) {
        if predicate(value) {
          (observer.on_next)(value)
        }
      },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// take 操作符 - 只取前 n 个值
pub fn[T] take(source : Observable[T], count : Int) -> Observable[T] {
  new_observable(fn(observer) {
    let mut taken = 0
    let original_observer = new_observer(
      fn(value) {
        if taken < count {
          (observer.on_next)(value)
          taken = taken + 1
          if taken == count {
            (observer.on_complete)()
          }
        }
      },
      observer.on_error,
      fn() {
        if taken < count {
          (observer.on_complete)()
        }
      }
    )
    source.subscribe(original_observer)
  })
}

/// skip 操作符 - 跳过前 n 个值
pub fn[T] skip(source : Observable[T], count : Int) -> Observable[T] {
  new_observable(fn(observer) {
    let mut skipped = 0
    let original_observer = new_observer(
      fn(value) {
        if skipped >= count {
          (observer.on_next)(value)
        } else {
          skipped = skipped + 1
        }
      },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// scan 操作符 - 累积操作，发射每个中间结果
pub fn[T, U] scan(source : Observable[T], initial : U, accumulator : (U, T) -> U) -> Observable[U] {
  new_observable(fn(observer) {
    let mut accumulated = initial
    (observer.on_next)(accumulated)  // 发射初始值
    
    let original_observer = new_observer(
      fn(value) {
        accumulated = accumulator(accumulated, value)
        (observer.on_next)(accumulated)
      },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// reduce 操作符 - 累积操作，只发射最终结果
pub fn[T, U] reduce(source : Observable[T], initial : U, accumulator : (U, T) -> U) -> Observable[U] {
  new_observable(fn(observer) {
    let mut accumulated = initial
    
    let original_observer = new_observer(
      fn(value) {
        accumulated = accumulator(accumulated, value)
      },
      observer.on_error,
      fn() {
        (observer.on_next)(accumulated)
        (observer.on_complete)()
      }
    )
    source.subscribe(original_observer)
  })
}

// ===== 高级操作符 =====

/// merge 操作符 - 合并多个 Observable
pub fn[T] merge(sources : Array[Observable[T]]) -> Observable[T] {
  new_observable(fn(observer) {
    let subscriptions : Array[BasicSubscription] = []
    let mut completed_count = 0
    
    for i = 0; i < sources.length(); i = i + 1 {
      let source = sources[i]
      let subscription = source.subscribe(new_observer(
        observer.on_next,
        observer.on_error,
        fn() {
          completed_count = completed_count + 1
          if completed_count == sources.length() {
            (observer.on_complete)()
          }
        }
      ))
      subscriptions.push(subscription)
    }
    
    // 返回第一个订阅作为代表
    if sources.length() > 0 { subscriptions[0] } else { new_subscription() }
  })
}

/// concat 操作符 - 顺序连接多个 Observable
pub fn[T] concat(sources : Array[Observable[T]]) -> Observable[T] {
  new_observable(fn(observer) {
    let mut current_index = 0
    let mut current_subscription = new_subscription()
    
    fn subscribe_next() -> Unit {
      if current_index < sources.length() {
        let source = sources[current_index]
        current_subscription = source.subscribe(new_observer(
          observer.on_next,
          observer.on_error,
          fn() {
            current_index = current_index + 1
            subscribe_next()
          }
        ))
      } else {
        (observer.on_complete)()
      }
    }
    
    subscribe_next()
    current_subscription
  })
}

/// tap 操作符 - 副作用操作，不改变数据流
pub fn[T] tap(source : Observable[T], side_effect : (T) -> Unit) -> Observable[T] {
  new_observable(fn(observer) {
    let original_observer = new_observer(
      fn(value) {
        side_effect(value)
        (observer.on_next)(value)
      },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// distinct 操作符 - 去重
pub fn[T : Eq] distinct(source : Observable[T]) -> Observable[T] {
  new_observable(fn(observer) {
    let seen_values : Array[T] = []
    
    let original_observer = new_observer(
      fn(value) {
        let mut already_seen = false
        for i = 0; i < seen_values.length(); i = i + 1 {
          if seen_values[i] == value {
            already_seen = true
            break
          }
        }
        if !already_seen {
          seen_values.push(value)
          (observer.on_next)(value)
        }
      },
      observer.on_error,
      observer.on_complete
    )
    source.subscribe(original_observer)
  })
}

/// catch_error 操作符 - 错误恢复
pub fn[T] catch_error(source : Observable[T], error_handler : (RxError) -> Observable[T]) -> Observable[T] {
  new_observable(fn(observer) {
    source.subscribe(new_observer(
      observer.on_next,
      fn(error) {
        let recovery_source = error_handler(error)
        let _ = recovery_source.subscribe(observer)
      },
      observer.on_complete
    ))
  })
}