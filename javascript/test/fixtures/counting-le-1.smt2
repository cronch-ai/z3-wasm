; Consecution: sat exactly where the invariant holds of a state and fails after one step.
; A model is a counterexample to induction for the kernel to check; unsat is not a verdict.
; Inputs left out, whose types have no sort: failed, ret.spawn.
(set-option :produce-models true)
(set-logic ALL)

; Records and variants.
; {n: Int}
(declare-datatype |record:d1a0623e| ((|record:d1a0623e| (|record:d1a0623e.n| Int))))
; A variant with the cases echo.say.
(declare-datatype |variant:fbd3cd3d| ((|variant:fbd3cd3d#echo.say| (|variant:fbd3cd3d#echo.say.call| Int) (|variant:fbd3cd3d#echo.say.value| String))))
; A variant with the cases refused, ret, start.
(declare-datatype |variant:9006e41b| ((|variant:9006e41b#refused| (|variant:9006e41b#refused.call| Int) (|variant:9006e41b#refused.op| String)) (|variant:9006e41b#ret| (|variant:9006e41b#ret.| |variant:fbd3cd3d|)) (|variant:9006e41b#start| (|variant:9006e41b#start.value| String))))
; {value: String}
(declare-datatype |record:9519f7bc| ((|record:9519f7bc| (|record:9519f7bc.value| String))))

; Definitions.
; The invariant, of a state.
(define-fun |def:invariant| ((|v:state| |record:d1a0623e|)) Bool (<= (|record:d1a0623e.n| |v:state|) 1))
; The state the step gives.
(define-fun |def:next| ((|v:state| |record:d1a0623e|) (|v:input| |variant:9006e41b|)) |record:d1a0623e| (let ((|c:1| |v:input|)) (ite ((_ is |variant:9006e41b#refused|) |c:1|) |v:state| (ite ((_ is |variant:9006e41b#ret|) |c:1|) (let ((|v:r| (|variant:9006e41b#ret.| |c:1|))) (|record:d1a0623e| (+ (|record:d1a0623e.n| |v:state|) 1))) (let ((|v:s| (|record:9519f7bc| (|variant:9006e41b#start.value| |c:1|)))) |v:state|)))))
; Where the kernel evaluates next without an error; elsewhere the function above is unconstrained.
(define-fun |defined:next| ((|v:state| |record:d1a0623e|) (|v:input| |variant:9006e41b|)) Bool (let ((|c:1| |v:input|)) (let ((|v:r| (|variant:9006e41b#ret.| |c:1|))) (=> ((_ is |variant:9006e41b#ret|) |c:1|) (and (<= (- 9007199254740991) (+ (|record:d1a0623e.n| |v:state|) 1)) (<= (+ (|record:d1a0623e.n| |v:state|) 1) 9007199254740991))))))

; A counterexample to induction.
(declare-const |q:state| |record:d1a0623e|)
(declare-const |q:input| |variant:9006e41b|)
(assert (|def:invariant| |q:state|))
(assert (|defined:next| |q:state| |q:input|))
(assert (not (|def:invariant| (|def:next| |q:state| |q:input|))))
(check-sat)
(get-value (|q:state| |q:input|))
