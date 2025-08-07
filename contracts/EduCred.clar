
;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-not-found (err u102))


(define-constant err-insufficient-approvals (err u105))
(define-constant err-duplicate-approval (err u106))
(define-constant err-approval-not-found (err u107))
(define-constant err-invalid-threshold (err u108))

(define-map credential-approval-configs
    {university: principal, credential-type: (string-ascii 50)}
    {
        required-approvals: uint,
        authorized-signers: (list 10 principal),
        approval-window: uint,
        active: bool
    }
)

(define-map pending-credential-approvals
    {approval-id: uint, university: principal}
    {
        student: principal,
        course-name: (string-ascii 100),
        credential-type: (string-ascii 50),
        request-date: uint,
        expiry-date: uint,
        approvals-received: uint,
        approvals-required: uint,
        status: (string-ascii 20)
    }
)

(define-map credential-approvals
    {approval-id: uint, approver: principal}
    {
        approval-date: uint,
        comments: (string-ascii 200),
        signature-hash: (string-ascii 64)
    }
)

(define-map approval-id-counter principal uint)

(define-map skill-registry
    {skill-id: uint}
    {
        name: (string-ascii 50),
        category: (string-ascii 30),
        description: (string-ascii 200),
        created-by: principal,
        verification-required: bool
    }
)

(define-map student-skills
    {student: principal, skill-id: uint}
    {
        proficiency-level: uint,
        verified: bool,
        verified-by: principal,
        verification-date: uint,
        evidence-credential: (optional uint)
    }
)

(define-map skill-portfolios
    principal
    {
        public: bool,
        last-updated: uint,
        total-skills: uint,
        verified-skills: uint
    }
)

(define-map employer-profiles
    principal
    {
        company-name: (string-ascii 100),
        verified: bool,
        registration-date: uint
    }
)

(define-map skill-searches
    {search-id: uint, employer: principal}
    {
        required-skills: (list 5 uint),
        minimum-proficiency: uint,
        search-date: uint,
        active: bool
    }
)

(define-map skill-endorsements
    {student: principal, skill-id: uint, endorser: principal}
    {
        endorsement-date: uint,
        endorsement-type: (string-ascii 20),
        comments: (string-ascii 150)
    }
)

(define-data-var skill-id-counter uint u0)
(define-data-var search-id-counter uint u0)

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


(define-map credential-access-grants
    {credential-id: uint, granted-to: principal}
    {
        granted-by: principal,
        grant-date: uint,
        expiry-date: uint,
        access-type: (string-ascii 10)
    }
)

(define-public (grant-credential-access
    (credential-id uint)
    (viewer principal)
    (duration uint)
    (access-type (string-ascii 10))
)
    (let (
        (credential (unwrap! (get-credential tx-sender credential-id) err-not-found))
    )
        (ok (map-set credential-access-grants
            {credential-id: credential-id, granted-to: viewer}
            {
                granted-by: tx-sender,
                grant-date: stacks-block-height,
                expiry-date: (+ stacks-block-height duration),
                access-type: access-type
            }
        ))
    )
)

(define-read-only (check-credential-access 
    (credential-id uint)
    (viewer principal)
)
    (match (map-get? credential-access-grants {credential-id: credential-id, granted-to: viewer})
        access-grant (ok (< stacks-block-height (get expiry-date access-grant)))
        (err err-not-authorized)
    )
)


(define-map credential-templates
    {template-id: uint, university: principal}
    {
        name: (string-ascii 100),
        description: (string-ascii 500),
        required-fields: (list 10 (string-ascii 50)),
        validity-period: uint,
        renewable: bool
    }
)

(define-map template-counter principal uint)

(define-public (create-credential-template
    (template-name (string-ascii 100))
    (template-description (string-ascii 500))
    (fields (list 10 (string-ascii 50)))
    (validity uint)
    (is-renewable bool)
)
    (let (
        (university (unwrap! (get-university tx-sender) err-not-authorized))
        (template-id (default-to u0 (map-get? template-counter tx-sender)))
    )
        (asserts! (get verified university) err-not-authorized)
        (map-set template-counter tx-sender (+ template-id u1))
        (ok (map-set credential-templates
            {template-id: (+ template-id u1), university: tx-sender}
            {
                name: template-name,
                description: template-description,
                required-fields: fields,
                validity-period: validity,
                renewable: is-renewable
            }
        ))
    )
)

(define-read-only (get-credential-template 
    (template-id uint)
    (university principal)
)
    (map-get? credential-templates {template-id: template-id, university: university})
)

(define-public (register-skill
    (skill-name (string-ascii 50))
    (skill-category (string-ascii 30))
    (skill-description (string-ascii 200))
    (requires-verification bool)
)
    (let (
        (new-skill-id (+ (var-get skill-id-counter) u1))
    )
        (var-set skill-id-counter new-skill-id)
        (ok (map-set skill-registry
            {skill-id: new-skill-id}
            {
                name: skill-name,
                category: skill-category,
                description: skill-description,
                created-by: tx-sender,
                verification-required: requires-verification
            }
        ))
    )
)

(define-public (add-student-skill
    (skill-id uint)
    (proficiency uint)
    (credential-id (optional uint))
)
    (let (
        (skill (unwrap! (map-get? skill-registry {skill-id: skill-id}) err-not-found))
        (current-portfolio (default-to 
            {public: false, last-updated: u0, total-skills: u0, verified-skills: u0}
            (map-get? skill-portfolios tx-sender)
        ))
    )
        (asserts! (<= proficiency u5) (err u104))
        (map-set student-skills
            {student: tx-sender, skill-id: skill-id}
            {
                proficiency-level: proficiency,
                verified: false,
                verified-by: tx-sender,
                verification-date: stacks-block-height,
                evidence-credential: credential-id
            }
        )
        (ok (map-set skill-portfolios
            tx-sender
            (merge current-portfolio {
                last-updated: stacks-block-height,
                total-skills: (+ (get total-skills current-portfolio) u1)
            })
        ))
    )
)

(define-public (verify-student-skill
    (student principal)
    (skill-id uint)
    (verified-proficiency uint)
)
    (let (
        (student-skill (unwrap! (map-get? student-skills {student: student, skill-id: skill-id}) err-not-found))
        (skill (unwrap! (map-get? skill-registry {skill-id: skill-id}) err-not-found))
        (verifier-university (unwrap! (get-university tx-sender) err-not-authorized))
        (current-portfolio (default-to 
            {public: false, last-updated: u0, total-skills: u0, verified-skills: u0}
            (map-get? skill-portfolios student)
        ))
    )
        (asserts! (get verified verifier-university) err-not-authorized)
        (asserts! (<= verified-proficiency u5) (err u104))
        (map-set student-skills
            {student: student, skill-id: skill-id}
            (merge student-skill {
                proficiency-level: verified-proficiency,
                verified: true,
                verified-by: tx-sender,
                verification-date: stacks-block-height
            })
        )
        (ok (map-set skill-portfolios
            student
            (merge current-portfolio {
                last-updated: stacks-block-height,
                verified-skills: (+ (get verified-skills current-portfolio) u1)
            })
        ))
    )
)

(define-public (register-employer
    (company-name (string-ascii 100))
)
    (ok (map-set employer-profiles
        tx-sender
        {
            company-name: company-name,
            verified: false,
            registration-date: stacks-block-height
        }
    ))
)

(define-public (verify-employer
    (employer principal)
)
    (let (
        (employer-profile (unwrap! (map-get? employer-profiles employer) err-not-found))
    )
        (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
        (ok (map-set employer-profiles
            employer
            (merge employer-profile {verified: true})
        ))
    )
)

(define-public (create-skill-search
    (required-skills (list 5 uint))
    (min-proficiency uint)
)
    (let (
        (employer (unwrap! (map-get? employer-profiles tx-sender) err-not-authorized))
        (new-search-id (+ (var-get search-id-counter) u1))
    )
        (asserts! (get verified employer) err-not-authorized)
        (asserts! (<= min-proficiency u5) (err u104))
        (var-set search-id-counter new-search-id)
        (ok (map-set skill-searches
            {search-id: new-search-id, employer: tx-sender}
            {
                required-skills: required-skills,
                minimum-proficiency: min-proficiency,
                search-date: stacks-block-height,
                active: true
            }
        ))
    )
)


(define-public (configure-approval-requirements
    (credential-type (string-ascii 50))
    (required-approvals uint)
    (authorized-signers (list 10 principal))
    (approval-window uint)
)
    (let (
        (university (unwrap! (get-university tx-sender) err-not-authorized))
    )
        (asserts! (get verified university) err-not-authorized)
        (asserts! (and (>= required-approvals u1) (<= required-approvals u10)) err-invalid-threshold)
        (asserts! (>= approval-window u1) err-invalid-threshold)
        (ok (map-set credential-approval-configs
            {university: tx-sender, credential-type: credential-type}
            {
                required-approvals: required-approvals,
                authorized-signers: authorized-signers,
                approval-window: approval-window,
                active: true
            }
        ))
    )
)

(define-public (request-credential-approval
    (student principal)
    (course-name (string-ascii 100))
    (credential-type (string-ascii 50))
)
    (let (
        (university (unwrap! (get-university tx-sender) err-not-authorized))
        (config (unwrap! (map-get? credential-approval-configs {university: tx-sender, credential-type: credential-type}) err-not-found))
        (approval-id (+ (default-to u0 (map-get? approval-id-counter tx-sender)) u1))
        (expiry-date (+ stacks-block-height (get approval-window config)))
    )
        (asserts! (get verified university) err-not-authorized)
        (asserts! (get active config) err-not-authorized)
        (map-set approval-id-counter tx-sender approval-id)
        (ok (map-set pending-credential-approvals
            {approval-id: approval-id, university: tx-sender}
            {
                student: student,
                course-name: course-name,
                credential-type: credential-type,
                request-date: stacks-block-height,
                expiry-date: expiry-date,
                approvals-received: u0,
                approvals-required: (get required-approvals config),
                status: "pending"
            }
        ))
    )
)

(define-public (approve-credential-request
    (approval-id uint)
    (university principal)
    (approval-comments (string-ascii 200))
    (signature-hash (string-ascii 64))
)
    (let (
        (config (unwrap! (map-get? credential-approval-configs {university: university, credential-type: "default"}) err-not-found))
        (pending-approval (unwrap! (map-get? pending-credential-approvals {approval-id: approval-id, university: university}) err-not-found))
        (existing-approval (map-get? credential-approvals {approval-id: approval-id, approver: tx-sender}))
    )
        (asserts! (is-none existing-approval) err-duplicate-approval)
        (asserts! (is-some (index-of (get authorized-signers config) tx-sender)) err-not-authorized)
        (asserts! (< stacks-block-height (get expiry-date pending-approval)) err-not-found)
        (asserts! (is-eq (get status pending-approval) "pending") err-not-found)
        (map-set credential-approvals
            {approval-id: approval-id, approver: tx-sender}
            {
                approval-date: stacks-block-height,
                comments: approval-comments,
                signature-hash: signature-hash
            }
        )
        (let (
            (new-approval-count (+ (get approvals-received pending-approval) u1))
            (updated-pending (merge pending-approval {approvals-received: new-approval-count}))
        )
            (map-set pending-credential-approvals
                {approval-id: approval-id, university: university}
                updated-pending
            )
            (if (>= new-approval-count (get approvals-required pending-approval))
                (begin
                    (map-set pending-credential-approvals
                        {approval-id: approval-id, university: university}
                        (merge updated-pending {status: "approved"})
                    )
                    (ok {approved: true, ready-to-issue: true})
                )
                (ok {approved: true, ready-to-issue: false})
            )
        )
    )
)

(define-public (issue-approved-credential
    (approval-id uint)
)
    (let (
        (pending-approval (unwrap! (map-get? pending-credential-approvals {approval-id: approval-id, university: tx-sender}) err-not-found))
        (university (unwrap! (get-university tx-sender) err-not-authorized))
        (next-credential-id (default-to u0 (get-credential-count tx-sender)))
    )
        (asserts! (get verified university) err-not-authorized)
        (asserts! (is-eq (get status pending-approval) "approved") err-insufficient-approvals)
        (asserts! (>= (get approvals-received pending-approval) (get approvals-required pending-approval)) err-insufficient-approvals)
        (map-set credentials
            {student: (get student pending-approval), credential-id: (+ next-credential-id u1)}
            {
                university: tx-sender,
                course: (get course-name pending-approval),
                issue-date: stacks-block-height,
                valid: true
            }
        )
        (map-set credential-counter tx-sender (+ next-credential-id u1))
        (map-set pending-credential-approvals
            {approval-id: approval-id, university: tx-sender}
            (merge pending-approval {status: "issued"})
        )
        (ok {credential-id: (+ next-credential-id u1), issued: true})
    )
)

(define-public (reject-credential-request
    (approval-id uint)
    (university principal)
    (rejection-reason (string-ascii 200))
)
    (let (
        (config (unwrap! (map-get? credential-approval-configs {university: university, credential-type: "default"}) err-not-found))
        (pending-approval (unwrap! (map-get? pending-credential-approvals {approval-id: approval-id, university: university}) err-not-found))
    )
        (asserts! (is-some (index-of (get authorized-signers config) tx-sender)) err-not-authorized)
        (asserts! (is-eq (get status pending-approval) "pending") err-not-found)
        (ok (map-set pending-credential-approvals
            {approval-id: approval-id, university: university}
            (merge pending-approval {status: "rejected"})
        ))
    )
)

(define-read-only (get-approval-config
    (university principal)
    (credential-type (string-ascii 50))
)
    (map-get? credential-approval-configs {university: university, credential-type: credential-type})
)

(define-read-only (get-pending-approval
    (approval-id uint)
    (university principal)
)
    (map-get? pending-credential-approvals {approval-id: approval-id, university: university})
)

(define-read-only (get-approval-details
    (approval-id uint)
    (approver principal)
)
    (map-get? credential-approvals {approval-id: approval-id, approver: approver})
)

(define-read-only (check-approval-eligibility
    (approval-id uint)
    (university principal)
    (potential-approver principal)
)
    (match (map-get? credential-approval-configs {university: university, credential-type: "default"})
        config (ok (is-some (index-of (get authorized-signers config) potential-approver)))
        (err err-not-found)
    )
)

(define-read-only (get-approval-progress
    (approval-id uint)
    (university principal)
)
    (match (map-get? pending-credential-approvals {approval-id: approval-id, university: university})
        pending-approval (ok {
            approvals-received: (get approvals-received pending-approval),
            approvals-required: (get approvals-required pending-approval),
            status: (get status pending-approval),
            expires-at: (get expiry-date pending-approval)
        })
        (err err-not-found)
    )
)

(define-public (set-portfolio-visibility
    (is-public bool)
)
    (let (
        (current-portfolio (default-to 
            {public: false, last-updated: u0, total-skills: u0, verified-skills: u0}
            (map-get? skill-portfolios tx-sender)
        ))
    )
        (ok (map-set skill-portfolios
            tx-sender
            (merge current-portfolio {
                public: is-public,
                last-updated: stacks-block-height
            })
        ))
    )
)

(define-public (endorse-skill
    (student principal)
    (skill-id uint)
    (endorsement-type (string-ascii 20))
    (endorsement-comments (string-ascii 150))
)
    (let (
        (student-skill (unwrap! (map-get? student-skills {student: student, skill-id: skill-id}) err-not-found))
    )
        (ok (map-set skill-endorsements
            {student: student, skill-id: skill-id, endorser: tx-sender}
            {
                endorsement-date: stacks-block-height,
                endorsement-type: endorsement-type,
                comments: endorsement-comments
            }
        ))
    )
)

(define-read-only (get-skill-info
    (skill-id uint)
)
    (map-get? skill-registry {skill-id: skill-id})
)

(define-read-only (get-student-skill
    (student principal)
    (skill-id uint)
)
    (map-get? student-skills {student: student, skill-id: skill-id})
)

(define-read-only (get-student-portfolio
    (student principal)
)
    (map-get? skill-portfolios student)
)

(define-read-only (get-employer-profile
    (employer principal)
)
    (map-get? employer-profiles employer)
)

(define-read-only (get-skill-search
    (search-id uint)
    (employer principal)
)
    (map-get? skill-searches {search-id: search-id, employer: employer})
)

(define-read-only (get-skill-endorsement
    (student principal)
    (skill-id uint)
    (endorser principal)
)
    (map-get? skill-endorsements {student: student, skill-id: skill-id, endorser: endorser})
)

(define-read-only (check-portfolio-visibility
    (student principal)
)
    (match (map-get? skill-portfolios student)
        portfolio (ok (get public portfolio))
        (ok false)
    )
)

(define-read-only (get-current-skill-id)
    (ok (var-get skill-id-counter))
)

(define-read-only (get-current-search-id)
    (ok (var-get search-id-counter))
)