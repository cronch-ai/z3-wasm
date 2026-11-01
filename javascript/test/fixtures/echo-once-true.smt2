; Consecution: sat exactly where the invariant holds of a state and fails after one step.
; A model is a counterexample to induction for the kernel to check; unsat is not a verdict.
; Inputs left out, whose types have no sort: failed, ret.spawn.
(set-option :produce-models true)
(set-logic ALL)

; Records and variants.
; {}
(declare-datatype |record:49d8b93e| ((|record:49d8b93e|)))
; A variant with the cases echo.say.
(declare-datatype |variant:fbd3cd3d| ((|variant:fbd3cd3d#echo.say| (|variant:fbd3cd3d#echo.say.call| Int) (|variant:fbd3cd3d#echo.say.value| String))))
; A variant with the cases refused, ret, start.
(declare-datatype |variant:9006e41b| ((|variant:9006e41b#refused| (|variant:9006e41b#refused.call| Int) (|variant:9006e41b#refused.op| String)) (|variant:9006e41b#ret| (|variant:9006e41b#ret.| |variant:fbd3cd3d|)) (|variant:9006e41b#start| (|variant:9006e41b#start.value| String))))
; {value: String}
(declare-datatype |record:9519f7bc| ((|record:9519f7bc| (|record:9519f7bc.value| String))))

; Definitions.
; The invariant, of a state.
(define-fun |def:invariant| ((|v:state| |record:49d8b93e|)) Bool true)
; The state the step gives.
(define-fun |def:next| ((|v:state| |record:49d8b93e|) (|v:input| |variant:9006e41b|)) |record:49d8b93e| (let ((|c:1| |v:input|)) (ite ((_ is |variant:9006e41b#refused|) |c:1|) |v:state| (ite ((_ is |variant:9006e41b#ret|) |c:1|) (let ((|v:r| (|variant:9006e41b#ret.| |c:1|))) |v:state|) (let ((|v:s| (|record:9519f7bc| (|variant:9006e41b#start.value| |c:1|)))) |v:state|)))))

; A counterexample to induction.
(declare-const |q:state| |record:49d8b93e|)
(declare-const |q:input| |variant:9006e41b|)
(assert (|def:invariant| |q:state|))
(assert (not (|def:invariant| (|def:next| |q:state| |q:input|))))
(check-sat)
(get-value (|q:state| |q:input|))
