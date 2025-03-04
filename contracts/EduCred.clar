
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



(define-public (revoke-credential (student principal) (credential-id uint))
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get university credential)) err-not-authorized)
        (ok (map-set credentials 
            {student: student, credential-id: credential-id}
            (merge credential {valid: false})
        ))
    )
)


(define-public (update-university-name (new-name (string-ascii 50)))
    (let (
        (university (unwrap! (get-university tx-sender) err-not-found))
    )
        (ok (map-set universities 
            tx-sender
            (merge university {name: new-name})
        ))
    )
)



(define-public (update-university-verification (verified bool))
    (let (
        (university (unwrap! (get-university tx-sender) err-not-found))
    )
        (ok (map-set universities 
            tx-sender
            (merge university {verified: verified})
        ))
    )
)


(define-public (update-credential (student principal) (credential-id uint) (course-name (string-ascii 100)))
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get university credential)) err-not-authorized)
        (ok (map-set credentials 
            {student: student, credential-id: credential-id}
            (merge credential {course: course-name})
        ))
    )
)


(define-map credential-metadata
    {credential-id: uint, student: principal}
    {
        grade: (string-ascii 2),
        description: (string-ascii 500),
        duration: uint
    }
)

(define-public (add-credential-metadata 
    (student principal) 
    (credential-id uint)
    (grade (string-ascii 2))
    (description (string-ascii 500))
    (duration uint)
)
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get university credential)) err-not-authorized)
        (ok (map-set credential-metadata
            {credential-id: credential-id, student: student}
            {grade: grade, description: description, duration: duration}
        ))
    )
)


(define-map student-profiles
    principal
    {
        name: (string-ascii 50),
        email: (string-ascii 100),
        registration-date: uint
    }
)

(define-public (register-student-profile 
    (name (string-ascii 50))
    (email (string-ascii 100))
)
    (ok (map-set student-profiles
        tx-sender
        {
            name: name,
            email: email,
            registration-date: stacks-block-height
        }
    ))
)




(define-private (issue-single-credential (student principal) (course-name (string-ascii 100)))
    (let (
        (next-id (default-to u0 (get-credential-count tx-sender)))
    )
        (map-set credentials
            {student: student, credential-id: (+ next-id u1)}
            {
                university: tx-sender,
                course: course-name,
                issue-date: stacks-block-height,
                valid: true
            }
        )
        (map-set credential-counter tx-sender (+ next-id u1))
        true
    ))
