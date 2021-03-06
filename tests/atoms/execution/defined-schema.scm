
(use-modules (opencog) (opencog exec))

; A simple DAG w/ InheritanceLinks
;
;     A
;     |
;     B
;    / \
;   C   F
;   |
;   D
;
(Inheritance    (Concept "A")    (Concept "B"))
(Inheritance    (Concept "B")    (Concept "C"))
(Inheritance    (Concept "B")    (Concept "F"))
(Inheritance    (Concept "C")    (Concept "D"))

; --------------------------------------------------------------

; The re-written DAG edges will look like this:
(define into-form
	(Evaluation (Predicate "yikes")
		(ListLink (Variable "$head") (Variable "$tail"))))

; A defined Lambda, in atomese.
(DefineLink
	(DefinedSchemaNode "make-an-edge")
	(Lambda
		(VariableList (Variable "$h") (Variable "$t"))
		(PutLink
			(VariableList (Variable "$head") (Variable "$tail"))
			into-form
			(List (Variable "$h") (Variable "$t")))))

; Lets try it out. Does it work? Yes.
; (cog-execute!
(define mk-edge
 	(ExecutionOutput
 		(DefinedSchemaNode "make-an-edge")
 		(List (Concept "X") (Concept "Y"))))

; --------------------------------------------------------------

; The input DAG edges that we search for
(define get-form
	(Inheritance (Variable "$head") (Variable "$tail")))

; Wrap it up in a function
(DefineLink
	(DefinedSchemaNode "get-the-tail")
	(Lambda
		(Variable "$head")
		(GetLink
			(Variable "$tail")
			get-form)))

; Does it work as expected? Yes.
;(cog-execute!
(define get-tl
	(ExecutionOutput
		(DefinedSchemaNode "get-the-tail")
		(List (Concept "A"))))

; --------------------------------------------------------------

; Can we chain them together? Yes we can.
(DefineLink
	(DefinedSchemaNode "rewrite-one")
	(Lambda
		(Variable "$hd")
		(ExecutionOutput
			(DefinedSchemaNode "make-an-edge")
			(List
				(Variable "$hd")
				(ExecutionOutput
					(DefinedSchemaNode "get-the-tail")
					(List (Variable "$hd")))))))

; Does it work? Yes it does.
; (cog-execute!
(define rw-one
	(ExecutionOutput
		(DefinedSchemaNode "rewrite-one")
		(List (Concept "A"))))

; --------------------------------------------------------------

; Do nothing.
(DefineLink
	(DefinedSchemaNode "no-op")
	(Lambda
		(VariableList (Variable "$hd") (Variable "$out"))
		(List (Variable "$hd") (Variable "$out"))))

; A complicated test.
(DefineLink
	(DefinedSchemaNode "test-rewrite")
	(Lambda
		(VariableList (Variable "$hd") (Variable "$out"))
		(ExecutionOutput
			(DefinedSchemaNode "no-op")
			(List
				(ExecutionOutputLink
					(DefinedSchema "get-the-tail")
					(List
						(Variable "$hd")))
				(ExecutionOutput
					(DefinedSchemaNode "make-an-edge")
					(List
						(Variable "$hd")
						(Variable "$out")))))))


; Does it work?
; (cog-execute!
(define nest
	(ExecutionOutput
		(DefinedSchema "test-rewrite")
		(List (Concept "A") (Concept "null"))))

; --------------------------------------------------------------

; Define a recursive tree-walker. It not only recurses, it reverses,
; tracing a path from each leaf, back up to the root. The return is
; a set-link, each element a path from leaf to root.
(DefineLink
	(DefinedSchemaNode "reversive-rewrite")
	(Lambda
		(VariableList (Variable "$hd") (Variable "$out"))
		(Cond
			(Equal (Variable "$hd") (Set))
			(Variable "$out")
			(ExecutionOutput
				(DefinedSchemaNode "reversive-rewrite")
					(List
						(ExecutionOutputLink
							(DefinedSchema "get-the-tail")
							(List
								(Variable "$hd")))
						(ExecutionOutput
							(DefinedSchemaNode "make-an-edge")
							(List
								(Variable "$hd")
								(Variable "$out"))))))))


; (cog-execute!
(define reversive
	(ExecutionOutput
		(DefinedSchema "reversive-rewrite")
		(List (Concept "A") (Concept "root"))))

; What the above generates, when executed.
(define reversive-result
	(SetLink
		(EvaluationLink (PredicateNode "yikes") (ListLink
			(ConceptNode "F")
			(EvaluationLink (PredicateNode "yikes") (ListLink
				(ConceptNode "B")
				(EvaluationLink (PredicateNode "yikes") (ListLink
					(ConceptNode "A")
					(ConceptNode "root")))))))
		(EvaluationLink (PredicateNode "yikes") (ListLink
			(ConceptNode "D")
			(EvaluationLink (PredicateNode "yikes") (ListLink
				(ConceptNode "C")
				(EvaluationLink (PredicateNode "yikes") (ListLink
					(ConceptNode "B")
					(EvaluationLink (PredicateNode "yikes") (ListLink
						(ConceptNode "A")
						(ConceptNode "root"))))))))))
)

*unspecified*
