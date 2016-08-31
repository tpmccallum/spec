;; Test `call` operator

(module
  ;; Auxiliary definitions
  (func $const-i32 (result i32) (i32.const 0x132))
  (func $const-i64 (result i64) (i64.const 0x164))
  (func $const-f32 (result f32) (f32.const 0xf32))
  (func $const-f64 (result f64) (f64.const 0xf64))

  (func $id-i32 (param i32) (result i32) (get_local 0))
  (func $id-i64 (param i64) (result i64) (get_local 0))
  (func $id-f32 (param f32) (result f32) (get_local 0))
  (func $id-f64 (param f64) (result f64) (get_local 0))

  (func $f32-i32 (param f32 i32) (result i32) (get_local 1))
  (func $i32-i64 (param i32 i64) (result i64) (get_local 1))
  (func $f64-f32 (param f64 f32) (result f32) (get_local 1))
  (func $i64-f64 (param i64 f64) (result f64) (get_local 1))

  ;; Typing

  (export "type-i32" (func (result i32) (call $const-i32)))
  (export "type-i64" (func (result i64) (call $const-i64)))
  (export "type-f32" (func (result f32) (call $const-f32)))
  (export "type-f64" (func (result f64) (call $const-f64)))

  (export "type-first-i32" (func (result i32) (call $id-i32 (i32.const 32))))
  (export "type-first-i64" (func (result i64) (call $id-i64 (i64.const 64))))
  (export "type-first-f32" (func (result f32) (call $id-f32 (f32.const 1.32))))
  (export "type-first-f64" (func (result f64) (call $id-f64 (f64.const 1.64))))

  (export "type-second-i32" (func (result i32)
    (call $f32-i32 (f32.const 32.1) (i32.const 32))
  ))
  (export "type-second-i64" (func (result i64)
    (call $i32-i64 (i32.const 32) (i64.const 64))
  ))
  (export "type-second-f32" (func (result f32)
    (call $f64-f32 (f64.const 64) (f32.const 32))
  ))
  (export "type-second-f64" (func (result f64)
    (call $i64-f64 (i64.const 64) (f64.const 64.1))
  ))

  ;; Recursion

  (export "fac" (func $fac (param i64) (result i64)
    (if (i64.eqz (get_local 0))
      (i64.const 1)
      (i64.mul (get_local 0) (call $fac (i64.sub (get_local 0) (i64.const 1))))
    )
  ))

  (export "fac-acc" (func $fac-acc (param i64 i64) (result i64)
    (if (i64.eqz (get_local 0))
      (get_local 1)
      (call $fac-acc
        (i64.sub (get_local 0) (i64.const 1))
        (i64.mul (get_local 0) (get_local 1))
      )
    )
  ))

  (export "fib" (func $fib (param i64) (result i64)
    (if (i64.le_u (get_local 0) (i64.const 1))
      (i64.const 1)
      (i64.add
        (call $fib (i64.sub (get_local 0) (i64.const 2)))
        (call $fib (i64.sub (get_local 0) (i64.const 1)))
      )
    )
  ))

  (export "even" (func $even (param i64) (result i32)
    (if (i64.eqz (get_local 0))
      (i32.const 44)
      (call $odd (i64.sub (get_local 0) (i64.const 1)))
    )
  ))
  (export "odd" (func $odd (param i64) (result i32)
    (if (i64.eqz (get_local 0))
      (i32.const 99)
      (call $even (i64.sub (get_local 0) (i64.const 1)))
    )
  ))

  ;; Stack exhaustion

  ;; Implementations are required to have every call consume some abstract
  ;; resource towards exhausting some abstract finite limit, such that
  ;; infinitely recursive test cases reliably trap in finite time. This is
  ;; because otherwise applications could come to depend on it on those
  ;; implementations and be incompatible with implementations that don't do
  ;; it (or don't do it under the same circumstances).

  (export "runaway" (func $runaway (call $runaway)))

  (export "mutual-runaway" (func $mutual-runaway1 (call $mutual-runaway2)))
  (func $mutual-runaway2 (call $mutual-runaway1))
)

(assert_return (invoke "type-i32") (i32.const 0x132))
(assert_return (invoke "type-i64") (i64.const 0x164))
(assert_return (invoke "type-f32") (f32.const 0xf32))
(assert_return (invoke "type-f64") (f64.const 0xf64))

(assert_return (invoke "type-first-i32") (i32.const 32))
(assert_return (invoke "type-first-i64") (i64.const 64))
(assert_return (invoke "type-first-f32") (f32.const 1.32))
(assert_return (invoke "type-first-f64") (f64.const 1.64))

(assert_return (invoke "type-second-i32") (i32.const 32))
(assert_return (invoke "type-second-i64") (i64.const 64))
(assert_return (invoke "type-second-f32") (f32.const 32))
(assert_return (invoke "type-second-f64") (f64.const 64.1))

(assert_return (invoke "fac" (i64.const 0)) (i64.const 1))
(assert_return (invoke "fac" (i64.const 1)) (i64.const 1))
(assert_return (invoke "fac" (i64.const 5)) (i64.const 120))
(assert_return (invoke "fac" (i64.const 25)) (i64.const 7034535277573963776))
(assert_return (invoke "fac-acc" (i64.const 0) (i64.const 1)) (i64.const 1))
(assert_return (invoke "fac-acc" (i64.const 1) (i64.const 1)) (i64.const 1))
(assert_return (invoke "fac-acc" (i64.const 5) (i64.const 1)) (i64.const 120))
(assert_return
  (invoke "fac-acc" (i64.const 25) (i64.const 1))
  (i64.const 7034535277573963776)
)

(assert_return (invoke "fib" (i64.const 0)) (i64.const 1))
(assert_return (invoke "fib" (i64.const 1)) (i64.const 1))
(assert_return (invoke "fib" (i64.const 2)) (i64.const 2))
(assert_return (invoke "fib" (i64.const 5)) (i64.const 8))
(assert_return (invoke "fib" (i64.const 20)) (i64.const 10946))

(assert_return (invoke "even" (i64.const 0)) (i32.const 44))
(assert_return (invoke "even" (i64.const 1)) (i32.const 99))
(assert_return (invoke "even" (i64.const 100)) (i32.const 44))
(assert_return (invoke "even" (i64.const 77)) (i32.const 99))
(assert_return (invoke "odd" (i64.const 0)) (i32.const 99))
(assert_return (invoke "odd" (i64.const 1)) (i32.const 44))
(assert_return (invoke "odd" (i64.const 200)) (i32.const 99))
(assert_return (invoke "odd" (i64.const 77)) (i32.const 44))

(assert_trap (invoke "runaway") "call stack exhausted")
(assert_trap (invoke "mutual-runaway") "call stack exhausted")


;; Invalid typing

(assert_invalid
  (module
    (func $type-void-vs-num (i32.eqz (call 1)))
    (func)
  )
  "type mismatch"
)
(assert_invalid
  (module
    (func $type-num-vs-num (i32.eqz (call 1)))
    (func (result i64) (i64.const 1))
  )
  "type mismatch"
)

(assert_invalid
  (module
    (func $arity-0-vs-1 (call 1))
    (func (param i32))
  )
  "arity mismatch"
)
(assert_invalid
  (module
    (func $arity-0-vs-2 (call 1))
    (func (param f64 i32))
  )
  "arity mismatch"
)
(assert_invalid
  (module
    (func $arity-1-vs-0 (call 1 (i32.const 1)))
    (func)
  )
  "arity mismatch"
)
(assert_invalid
  (module
    (func $arity-2-vs-0 (call 1 (f64.const 2) (i32.const 1)))
    (func)
  )
  "arity mismatch"
)

(assert_invalid
  (module
    (func $arity-nop-first (call 1 (nop) (i32.const 1) (i32.const 2)))
    (func (param i32 i32))
  )
  "arity mismatch"
)
(assert_invalid
  (module
    (func $arity-nop-mid (call 1 (i32.const 1) (nop) (i32.const 2)))
    (func (param i32 i32))
  )
  "arity mismatch"
)
(assert_invalid
  (module
    (func $arity-nop-last (call 1 (i32.const 1) (i32.const 2) (nop)))
    (func (param i32 i32))
  )
  "arity mismatch"
)

(assert_invalid
  (module
    (func $type-first-void-vs-num (call 1 (nop) (i32.const 1)))
    (func (param i32 i32))
  )
  "type mismatch"
)
(assert_invalid
  (module
    (func $type-second-void-vs-num (call 1 (i32.const 1) (nop)))
    (func (param i32 i32))
  )
  "type mismatch"
)
(assert_invalid
  (module
    (func $type-first-num-vs-num (call 1 (f64.const 1) (i32.const 1)))
    (func (param i32 f64))
  )
  "type mismatch"
)
(assert_invalid
  (module
    (func $type-second-num-vs-num (call 1 (i32.const 1) (f64.const 1)))
    (func (param f64 i32))
  )
  "type mismatch"
)


;; Unbound function

(assert_invalid
  (module (func $unbound-func (call 1)))
  "unknown function"
)
(assert_invalid
  (module (func $large-func (call 10001232130000)))
  "unknown function"
)
