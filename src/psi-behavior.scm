;
; psi-behvaior.scm
(use-modules (ice-9 format))


(add-to-load-path "/usr/local/share/opencog/scm")
(use-modules (opencog))
(use-modules (opencog exec))
(use-modules (opencog openpsi))
(load "face-priority.scm")

;; ------------------------------------------------------------------
; Demand associated with faces
(define face-demand (psi-demand "face interaction" 1))
(define face-demand-satisfied (True))

; Demand associated with speech interaction
(define speech-demand (psi-demand "speech interaction" 1))
(define speech-demand-satisfied (True))

; Demand for tracking faces
; TODO: make generic for orchestration.
(define track-demand (psi-demand "track demand" 1))
(define track-demand-satisfied (True))

; Demand for contorl with web-ui
(define update-demand (psi-demand "update demand" 1))
(define update-demand-satisfied (True))

(State (ConceptNode "saliency-tracking") (NumberNode "0"))

(DefineLink
	(DefinedPredicate "tracking-salient?")
	(GreaterThan
		(Get (State (ConceptNode "saliency-tracking")(VariableNode "$x")))
		(NumberNode "0.5")))

(DefineLink
	(DefinedPredicate "salient-flag-off")
  (True
		(Put (State (ConceptNode "saliency-tracking")(Variable "$x")) (NumberNode "0")))
)

(DefineLink
	(DefinedPredicate "salient-flag-on")
  (True
		(Put (State (ConceptNode "saliency-tracking")(Variable "$x")) (NumberNode "1.0")))
)

(DefineLink
	(DefinedPredicate "Nothing happening?")
	(NotLink
		(SequentialOr
			(DefinedPredicate "Someone requests interaction?")
			(DefinedPredicate "Did someone arrive?")
			(DefinedPredicate "Did someone leave?")
			(DefinedPredicate "Someone visible?"))))

(DefineLink
	(DefinedPredicate "Nothing New?")
	(NotLink
		(SequentialOr
			(DefinedPredicate "Someone requests interaction?")
			(DefinedPredicate "Did someone arrive?")
			(DefinedPredicate "Did someone leave?")
			)))

(psi-rule (list (DefinedPredicate "Did Someone New Speak?"))
	(DefinedPredicate "Request interaction with person who spoke")
	face-demand-satisfied (stv 1 1) face-demand)


(psi-rule (list
		(SequentialAnd
		(NotLink (DefinedPredicate "tracking-salient?"))
		(DefinedPredicate "Someone requests interaction?"))
	)
	(DefinedPredicate "Interaction requested action")
	face-demand-satisfied (stv 1 1) face-demand)

(psi-rule (list (DefinedPredicate "Did someone arrive?"))
	(DefinedPredicate "New arrival sequence")
	face-demand-satisfied (stv 1 1) face-demand)

(psi-rule (list (DefinedPredicate "Did someone leave?"))
	(DefinedPredicate "Someone left action")
	face-demand-satisfied (stv 1 1) face-demand)

; This rule is the old multiple-face tracking rule
; TODO Remove after thoroughly testing behavior on robot.
(psi-rule (list (SequentialAnd (NotLink (DefinedPredicate "Skip Interaction?"))
		(NotLink (DefinedPredicate "tracking-salient?"))
		(DefinedPredicate "Someone visible?")))
	(DefinedPredicate "Interact with people")
	face-demand-satisfied (stv 1 1) face-demand)

; TODO: How should rules that could run concurrently be represented, when
; we have action compostion(aka Planning/Orchestration)?
(psi-rule (list (SequentialAnd (DefinedPredicate "Someone visible?")
	(NotLink (DefinedPredicate "tracking-salient?"))))
	(DefinedPredicate "Interact with face")
	track-demand-satisfied (stv .5 .5) track-demand)

(psi-rule (list (SequentialAnd
		; TODO: test the behabior when talking.
		; (Not (DefinedPredicate "chatbot is talking?"))
		(NotLink (DefinedPredicate "tracking-salient?"))
		(DefinedPredicate "Someone visible?")
		(DefinedPredicate "Time to change interaction")))
	(DefinedPredicate "Change interaction target by priority")
	face-demand-satisfied (stv 1 1) face-demand)

;(psi-rule (list (DefinedPredicate "Nothing happening?"))
;	(DefinedPredicate "Nothing is happening")
;	face-demand-satisfied (stv 1 1) face-demand)

(psi-rule (list (SequentialAnd
		(Not (DefinedPredicate "chatbot started talking?"))
		(Not (DefinedPredicate "Is interacting with someone?"))
		(DefinedPredicateNode "Did someone recognizable arrive?")))
	(DefinedPredicate "Interacting Sequence for recognized person")
	face-demand-satisfied (stv 1 1) face-demand)

(psi-rule (list (DefinedPredicate "chatbot started talking?"))
	(DefinedPredicate "Speech started")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "chatbot is talking?"))
	(DefinedPredicate "Speech ongoing")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "chatbot stopped talking?"))
	(DefinedPredicate "Speech ended")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "chatbot started listening?"))
	(DefinedPredicate "Listening started")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "chatbot is listening?"))
	(DefinedPredicate "Listening ongoing")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "chatbot stopped listening?"))
	(DefinedPredicate "Listening ended")
	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "ROS is running?"))
	(DefinedPredicate "Keep alive")
	speech-demand-satisfied (stv 1 1) speech-demand)

;heard loud voice not working
;(psi-rule (list (DefinedPredicate "Heard Loud Voice?"))
;	(DefinedPredicate "Say whoa!")
;	speech-demand-satisfied (stv 1 1) speech-demand)

(psi-rule (list (DefinedPredicate "Heard Loud Sound?"))
	(DefinedPredicate "Say whoa!")
	speech-demand-satisfied (stv 1 1) speech-demand)

;; saliency
(psi-set-controlled-rule
	(psi-rule (list (True))
			(DefinedPredicate "Salient:Curious")
			(True) (stv 0.9 0.9) face-demand "saliency-tracking")
)
;; stop tracking
(psi-set-controlled-rule
	(psi-rule (list (True))
			(DefinedPredicate "salient-flag-off")
			(True) (stv 0.9 0.9) face-demand "not-saliency-tracking")
)

(psi-rule (list (DefinedPredicate "Room bright?"))
	(DefinedPredicate "Bright:happy")
	face-demand-satisfied (stv 1 1) face-demand)

;below doesn't work
;(psi-rule (list (DefinedPredicate "Heard Something?"))
;	(DefinedPredicate "React to Sound")
;	speech-demand-satisfied (stv 1 1) speech-demand)

; Any changes to the weight for controlled-psi-rules are pushed to ros
; dynamic-parameters. Thus the web-ui mirrors the opencog wholeshow state.
(psi-rule (list (DefinedPredicate "ROS is running?"))
	(DefinedPredicate "update-web-ui")
		update-demand-satisfied (stv 1 1) update-demand)
