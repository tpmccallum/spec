;; Test memory section structure
(module (memory 0 0))
(module (memory 0 1))
(module (memory 1 256))
(module (memory 0 65535))
(module (memory 0 0) (data (i32.const 0)))
(module (memory 0 0) (data (i32.const 0) ""))
(module (memory 1 1) (data (i32.const 0) "a"))
(module (memory 1 2) (data (i32.const 0) "a") (data (i32.const 65535) "b"))
(module (memory 1 2)
  (data (i32.const 0) "a") (data (i32.const 1) "b") (data (i32.const 2) "c")
)

(module (memory (data)) (export "memsize" (func (result i32) (current_memory))))
(assert_return (invoke "memsize") (i32.const 0))
(module (memory (data "")) (export "memsize" (func (result i32) (current_memory))))
(assert_return (invoke "memsize") (i32.const 0))
(module (memory (data "x")) (export "memsize" (func (result i32) (current_memory))))
(assert_return (invoke "memsize") (i32.const 1))

(assert_invalid (module (data (i32.const 0))) "unknown memory")
(assert_invalid (module (data (i32.const 0) "")) "unknown memory")
(assert_invalid (module (data (i32.const 0) "x")) "unknown memory")

(assert_invalid
  (module (memory 1) (data (i64.const 0)))
  "type mismatch"
)
(assert_invalid
  (module (memory 1) (data (i32.ctz (i32.const 0))))
  "constant expression required"
)
(assert_invalid
  (module (memory 1) (data (nop)))
  "constant expression required"
)

(assert_invalid
  (module (memory 1 0))
  "memory size minimum must not be greater than maximum"
)
(assert_invalid
  (module (memory 0 0) (data (i32.const 0) "a"))
  "data segment does not fit"
)
(assert_invalid
  (module (memory 1 2) (data (i32.const 0) "a") (data (i32.const 98304) "b"))
  "data segment does not fit"
)
(assert_invalid
  (module (memory 1 2) (data (i32.const 0) "abc") (data (i32.const 0) "def"))
  "data segment not disjoint and ordered"
)
(assert_invalid
  (module (memory 1 2) (data (i32.const 3) "ab") (data (i32.const 0) "de"))
  "data segment not disjoint and ordered"
)
(assert_invalid
  (module
    (memory 1 2)
    (data (i32.const 0) "a") (data (i32.const 2) "b") (data (i32.const 1) "c")
  )
  "data segment not disjoint and ordered"
)
(assert_invalid
  (module (memory 0 65536))
  "memory size must be less than 65536 pages (4GiB)"
)
(assert_invalid
  (module (memory 0 2147483648))
  "memory size must be less than 65536 pages (4GiB)"
)
(assert_invalid
  (module (memory 0 4294967295))
  "memory size must be less than 65536 pages (4GiB)"
)

;; Test alignment annotation rules
(module (memory 0) (func (drop (i32.load8_u align=2 (i32.const 0)))))
(module (memory 0) (func (drop (i32.load16_u align=4 (i32.const 0)))))
(module (memory 0) (func (drop (i32.load align=4 (i32.const 0)))))
(module (memory 0) (func (drop (f32.load align=4 (i32.const 0)))))

(assert_invalid
  (module (memory 0) (func (drop (i64.load align=0 (i32.const 0)))))
  "alignment must be a power of two"
)
(assert_invalid
  (module (memory 0) (func (drop (i64.load align=3 (i32.const 0)))))
  "alignment must be a power of two"
)
(assert_invalid
  (module (memory 0) (func (drop (i64.load align=5 (i32.const 0)))))
  "alignment must be a power of two"
)
(assert_invalid
  (module (memory 0) (func (drop (i64.load align=6 (i32.const 0)))))
  "alignment must be a power of two"
)
(assert_invalid
  (module (memory 0) (func (drop (i64.load align=7 (i32.const 0)))))
  "alignment must be a power of two"
)

(assert_invalid
  (module (memory 0) (func (i64.load align=16 (i32.const 0))))
  "alignment must not be larger than natural"
)
(assert_invalid
  (module (memory 0) (func (i64.load align=32 (i32.const 0))))
  "alignment must not be larger than natural"
)
(assert_invalid
  (module (memory 0) (func (i32.load align=8 (i32.const 0))))
  "alignment must not be larger than natural"
)

(module
  (memory 1)
  (data (i32.const 0) "ABC\a7D") (data (i32.const 20) "WASM")

  ;; Data section
  (export "data" (func (result i32)
    (i32.and
      (i32.and
        (i32.and
          (i32.eq (i32.load8_u (i32.const 0)) (i32.const 65))
          (i32.eq (i32.load8_u (i32.const 3)) (i32.const 167))
        )
        (i32.and
          (i32.eq (i32.load8_u (i32.const 6)) (i32.const 0))
          (i32.eq (i32.load8_u (i32.const 19)) (i32.const 0))
        )
      )
      (i32.and
        (i32.and
          (i32.eq (i32.load8_u (i32.const 20)) (i32.const 87))
          (i32.eq (i32.load8_u (i32.const 23)) (i32.const 77))
        )
        (i32.and
          (i32.eq (i32.load8_u (i32.const 24)) (i32.const 0))
          (i32.eq (i32.load8_u (i32.const 1023)) (i32.const 0))
        )
      )
    )
  ))

  ;; Aligned read/write
  (export "aligned" (func (result i32)
    (local i32 i32 i32)
    (set_local 0 (i32.const 10))
    (loop
      (if
        (i32.eq (get_local 0) (i32.const 0))
        (br 2)
      )
      (set_local 2 (i32.mul (get_local 0) (i32.const 4)))
      (i32.store (get_local 2) (get_local 0))
      (set_local 1 (i32.load (get_local 2)))
      (if
        (i32.ne (get_local 0) (get_local 1))
        (return (i32.const 0))
      )
      (set_local 0 (i32.sub (get_local 0) (i32.const 1)))
      (br 0)
    )
    (i32.const 1)
  ))

  ;; Unaligned read/write
  (export "unaligned" (func (result i32)
    (local i32 f64 f64)
    (set_local 0 (i32.const 10))
    (loop
      (if
        (i32.eq (get_local 0) (i32.const 0))
        (br 2)
      )
      (set_local 2 (f64.convert_s/i32 (get_local 0)))
      (f64.store align=1 (get_local 0) (get_local 2))
      (set_local 1 (f64.load align=1 (get_local 0)))
      (if
        (f64.ne (get_local 2) (get_local 1))
        (return (i32.const 0))
      )
      (set_local 0 (i32.sub (get_local 0) (i32.const 1)))
      (br 0)
    )
    (i32.const 1)
  ))

  ;; Memory cast
  (export "cast" (func (result f64)
    (i64.store (i32.const 8) (i64.const -12345))
    (if
      (f64.eq
        (f64.load (i32.const 8))
        (f64.reinterpret/i64 (i64.const -12345))
      )
      (return (f64.const 0))
    )
    (i64.store align=1 (i32.const 9) (i64.const 0))
    (i32.store16 align=1 (i32.const 15) (i32.const 16453))
    (f64.load align=1 (i32.const 9))
  ))

  ;; Sign and zero extending memory loads
  (export "i32_load8_s" (func (param $i i32) (result i32)
	(i32.store8 (i32.const 8) (get_local $i))
	(i32.load8_s (i32.const 8))
  ))
  (export "i32_load8_u" (func (param $i i32) (result i32)
	(i32.store8 (i32.const 8) (get_local $i))
	(i32.load8_u (i32.const 8))
  ))
  (export "i32_load16_s" (func (param $i i32) (result i32)
	(i32.store16 (i32.const 8) (get_local $i))
	(i32.load16_s (i32.const 8))
  ))
  (export "i32_load16_u" (func (param $i i32) (result i32)
	(i32.store16 (i32.const 8) (get_local $i))
	(i32.load16_u (i32.const 8))
  ))
  (export "i64_load8_s" (func (param $i i64) (result i64)
	(i64.store8 (i32.const 8) (get_local $i))
	(i64.load8_s (i32.const 8))
  ))
  (export "i64_load8_u" (func (param $i i64) (result i64)
	(i64.store8 (i32.const 8) (get_local $i))
	(i64.load8_u (i32.const 8))
  ))
  (export "i64_load16_s" (func (param $i i64) (result i64)
	(i64.store16 (i32.const 8) (get_local $i))
	(i64.load16_s (i32.const 8))
  ))
  (export "i64_load16_u" (func (param $i i64) (result i64)
	(i64.store16 (i32.const 8) (get_local $i))
	(i64.load16_u (i32.const 8))
  ))
  (export "i64_load32_s" (func (param $i i64) (result i64)
	(i64.store32 (i32.const 8) (get_local $i))
	(i64.load32_s (i32.const 8))
  ))
  (export "i64_load32_u" (func (param $i i64) (result i64)
	(i64.store32 (i32.const 8) (get_local $i))
	(i64.load32_u (i32.const 8))
  ))
)

(assert_return (invoke "data") (i32.const 1))
(assert_return (invoke "aligned") (i32.const 1))
(assert_return (invoke "unaligned") (i32.const 1))
(assert_return (invoke "cast") (f64.const 42.0))

(assert_return (invoke "i32_load8_s" (i32.const -1)) (i32.const -1))
(assert_return (invoke "i32_load8_u" (i32.const -1)) (i32.const 255))
(assert_return (invoke "i32_load16_s" (i32.const -1)) (i32.const -1))
(assert_return (invoke "i32_load16_u" (i32.const -1)) (i32.const 65535))

(assert_return (invoke "i32_load8_s" (i32.const 100)) (i32.const 100))
(assert_return (invoke "i32_load8_u" (i32.const 200)) (i32.const 200))
(assert_return (invoke "i32_load16_s" (i32.const 20000)) (i32.const 20000))
(assert_return (invoke "i32_load16_u" (i32.const 40000)) (i32.const 40000))

(assert_return (invoke "i64_load8_s" (i64.const -1)) (i64.const -1))
(assert_return (invoke "i64_load8_u" (i64.const -1)) (i64.const 255))
(assert_return (invoke "i64_load16_s" (i64.const -1)) (i64.const -1))
(assert_return (invoke "i64_load16_u" (i64.const -1)) (i64.const 65535))
(assert_return (invoke "i64_load32_s" (i64.const -1)) (i64.const -1))
(assert_return (invoke "i64_load32_u" (i64.const -1)) (i64.const 4294967295))

(assert_return (invoke "i64_load8_s" (i64.const 100)) (i64.const 100))
(assert_return (invoke "i64_load8_u" (i64.const 200)) (i64.const 200))
(assert_return (invoke "i64_load16_s" (i64.const 20000)) (i64.const 20000))
(assert_return (invoke "i64_load16_u" (i64.const 40000)) (i64.const 40000))
(assert_return (invoke "i64_load32_s" (i64.const 20000)) (i64.const 20000))
(assert_return (invoke "i64_load32_u" (i64.const 40000)) (i64.const 40000))
