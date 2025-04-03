
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


;; Add to data maps
(define-map certificate-expiration
    {credential-id: uint, student: principal}
    {
        expiry-date: uint,
        renewable: bool
    }
)

;; Add this public function
(define-public (set-credential-expiry
    (student principal)
    (credential-id uint) 
    (validity-period uint)
    (is-renewable bool)
)
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
        (expiry-block (+ stacks-block-height validity-period))
    )
        (asserts! (is-eq tx-sender (get university credential)) err-not-authorized)
        (ok (map-set certificate-expiration
            {credential-id: credential-id, student: student}
            {expiry-date: expiry-block, renewable: is-renewable}
        ))
    )
)


;; Add to data maps
(define-map university-accreditation
    principal
    {
        accredited: bool,
        accreditation-date: uint,
        accreditation-body: (string-ascii 100),
        valid-until: uint
    }
)

;; Add this public function
(define-public (update-university-accreditation
    (university principal)
    (accreditation-status bool)
    (accreditor (string-ascii 100))
    (validity-period uint)
)
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (ok (map-set university-accreditation
            university
            {
                accredited: accreditation-status,
                accreditation-date: stacks-block-height,
                accreditation-body: accreditor,
                valid-until: (+ stacks-block-height validity-period)
            }
        ))
    )
)
;; Add to data maps
(define-map transfer-history
    {credential-id: uint, transfer-id: uint}
    {
        from-university: principal,
        to-university: principal,
        transfer-date: uint,
        reason: (string-ascii 200)
    }
)

(define-map transfer-counter uint uint)

;; Add this public function
(define-public (transfer-credential
    (student principal)
    (credential-id uint)
    (new-university principal)
    (transfer-reason (string-ascii 200))
)
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
        (transfer-id (default-to u0 (map-get? transfer-counter u1)))
    )
        (asserts! (is-eq tx-sender (get university credential)) err-not-authorized)
        (map-set transfer-counter u1 (+ transfer-id u1))
        (ok (map-set transfer-history
            {credential-id: credential-id, transfer-id: (+ transfer-id u1)}
            {
                from-university: tx-sender,
                to-university: new-university,
                transfer-date: stacks-block-height,
                reason: transfer-reason
            }
        ))
    )
)

;; Add to data maps
(define-map achievement-badges
    {student: principal, badge-id: uint}
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        issued-by: principal,
        issue-date: uint
    }
)

(define-map student-badge-counter principal uint)

;; Add this public function
(define-public (issue-badge
    (student principal)
    (badge-name (string-ascii 50))
    (badge-description (string-ascii 200))
)
    (let (
        (badge-count (default-to u0 (map-get? student-badge-counter student)))
    )
        (map-set student-badge-counter student (+ badge-count u1))
        (ok (map-set achievement-badges
            {student: student, badge-id: (+ badge-count u1)}
            {
                name: badge-name,
                description: badge-description,
                issued-by: tx-sender,
                issue-date: stacks-block-height
            }
        ))
    )
)

;; Add to data maps
(define-map course-prerequisites
    (string-ascii 100)  ;; course name
    {
        required-courses: (list 10 (string-ascii 100)),
        minimum-grade: (string-ascii 2),
        required-credits: uint
    }
)

;; Add this public function
(define-public (set-course-prerequisites
    (course-name (string-ascii 100))
    (prerequisites (list 10 (string-ascii 100)))
    (min-grade (string-ascii 2))
    (credits uint)
)
    (begin
        (asserts! (is-some (get-university tx-sender)) err-not-authorized)
        (ok (map-set course-prerequisites
            course-name
            {
                required-courses: prerequisites,
                minimum-grade: min-grade,
                required-credits: credits
            }
        ))
    )
)


;; Add to data maps
(define-map credential-endorsements
    {credential-id: uint, endorser: principal}
    {
        endorsement-date: uint,
        comments: (string-ascii 200),
        rating: uint
    }
)

;; Add this public function
(define-public (endorse-credential
    (student principal)
    (credential-id uint)
    (endorsement-comment (string-ascii 200))
    (endorsement-rating uint)
)
    (let (
        (credential (unwrap! (get-credential student credential-id) err-not-found))
    )
        (asserts! (<= endorsement-rating u5) (err u103)) ;; Rating must be 1-5
        (ok (map-set credential-endorsements
            {credential-id: credential-id, endorser: tx-sender}
            {
                endorsement-date: stacks-block-height,
                comments: endorsement-comment,
                rating: endorsement-rating
            }
        ))
    )
)

;; Add to data maps
(define-map verification-requests
    {request-id: uint, requester: principal}
    {
        student: principal,
        credential-id: uint,
        request-date: uint,
        status: (string-ascii 20),
        response-date: (optional uint)
    }
)

(define-map request-counter uint uint)

;; Add this public function
(define-public (request-credential-verification
    (student principal)
    (credential-id uint)
)
    (let (
        (request-id (default-to u0 (map-get? request-counter u1)))
    )
        (map-set request-counter u1 (+ request-id u1))
        (ok (map-set verification-requests
            {request-id: (+ request-id u1), requester: tx-sender}
            {
                student: student,
                credential-id: credential-id,
                request-date: stacks-block-height,
                status: "pending",
                response-date: none
            }
        ))
    )
)