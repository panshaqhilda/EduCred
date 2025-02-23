
;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))

;; Data Maps
(define-map universities 
    principal 
    {name: (string-ascii 50), verified: bool}
)

(define-map credentials 
    {student: principal, credential-id: uint}
    {
        university: principal,
        course: (string-ascii 100),
        issue-date: uint,
        valid: bool
    }
)

(define-map credential-counter principal uint)

;; Public Functions
(define-public (register-university (university-principal principal) (university-name (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (asserts! (is-none (get-university university-principal)) err-already-registered)
        (ok (map-set universities 
            university-principal
            {name: university-name, verified: true}
        ))
    )
)

(define-public (issue-credential 
    (student-principal principal)
    (course-name (string-ascii 100)))
    (let
        (
            (university (unwrap! (get-university tx-sender) err-not-authorized))
            (next-id (default-to u0 (get-credential-count tx-sender)))
        )
        (asserts! (get verified university) err-not-authorized)
        (map-set credentials
            {student: student-principal, credential-id: (+ next-id u1)}
            {
                university: tx-sender,
                course: course-name,
                issue-date: stacks-block-height,
                valid: true
            }
        )
        (map-set credential-counter tx-sender (+ next-id u1))
        (ok true)
    )
)

;; Read Only Functions
(define-read-only (get-university (university principal))
    (map-get? universities university)
)

(define-read-only (get-credential (student principal) (credential-id uint))
    (map-get? credentials {student: student, credential-id: credential-id})
)

(define-read-only (get-credential-count (university principal))
    (map-get? credential-counter university)
)

(define-read-only (verify-credential (student principal) (credential-id uint))
    (match (get-credential student credential-id)
        credential (ok (get valid credential))
        (err err-not-found)
    )
)
