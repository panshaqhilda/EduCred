;; Credential Analytics & Market Intelligence System
;; Tracks university performance, credential market value, and reputation scoring

;; Error constants
(define-constant err-not-authorized (err u200))
(define-constant err-invalid-rating (err u201))
(define-constant err-invalid-timeframe (err u202))
(define-constant err-analytics-not-found (err u203))

;; Analytics time windows
(define-constant monthly-window u4320)   ;; ~30 days in blocks
(define-constant quarterly-window u12960) ;; ~90 days in blocks
(define-constant yearly-window u52560)   ;; ~365 days in blocks

;; University performance metrics
(define-map university-analytics
    {university: principal, period: uint}
    {
        credentials-issued: uint,
        verification-requests: uint,
        verification-success-rate: uint, ;; percentage * 100
        average-time-to-verify: uint,
        employer-satisfaction-score: uint, ;; 1-500 scale
        skill-verification-accuracy: uint, ;; percentage * 100
        last-updated: uint
    }
)

;; Credential market value tracking
(define-map credential-market-data
    {course-hash: (string-ascii 64), period: uint}
    {
        total-issued: uint,
        employer-demand-score: uint, ;; 1-500 scale  
        average-salary-indicator: uint, ;; relative scale 1-1000
        employment-rate: uint, ;; percentage * 100
        skill-relevance-score: uint, ;; 1-500 scale
        market-trend: (string-ascii 20) ;; "rising", "stable", "declining"
    }
)

;; University reputation scoring
(define-map university-reputation
    principal
    {
        overall-score: uint, ;; 1-1000 scale
        quality-score: uint, ;; based on verification accuracy
        reliability-score: uint, ;; based on consistent performance
        innovation-score: uint, ;; based on new skills/courses
        employer-trust-score: uint, ;; based on employer feedback
        last-calculated: uint,
        trending-direction: (string-ascii 10) ;; "up", "down", "stable"
    }
)

;; Skill demand analytics
(define-map skill-market-trends
    {skill-id: uint, period: uint}
    {
        search-frequency: uint,
        average-proficiency-required: uint, ;; 1-5 scale
        salary-impact-score: uint, ;; 1-500 scale
        growth-rate: uint, ;; percentage * 100
        geographic-demand: (string-ascii 50),
        complementary-skills: (list 5 uint)
    }
)

;; Employer feedback system
(define-map employer-credential-feedback
    {employer: principal, university: principal, feedback-id: uint}
    {
        credential-quality-rating: uint, ;; 1-5 scale
        skill-accuracy-rating: uint, ;; 1-5 scale
        hire-success-rating: uint, ;; 1-5 scale
        would-hire-again: bool,
        feedback-date: uint,
        comments: (string-ascii 300)
    }
)

;; Employment outcome tracking
(define-map employment-outcomes
    {student: principal, credential-id: uint}
    {
        employed-within-months: uint,
        starting-salary-range: uint, ;; 1-10 scale
        job-relevance-score: uint, ;; 1-5 scale
        employer-principal: (optional principal),
        outcome-verified: bool,
        report-date: uint
    }
)

;; Analytics configuration
(define-map analytics-config
    (string-ascii 50) ;; config-key
    {
        enabled: bool,
        update-frequency: uint,
        data-retention-period: uint,
        calculation-method: (string-ascii 30)
    }
)

;; Data counters
(define-data-var feedback-counter uint u0)
(define-data-var analytics-last-update uint u0)

;; Submit employer feedback on university credentials
(define-public (submit-employer-feedback
    (university principal)
    (quality-rating uint)
    (skill-accuracy uint)
    (hire-success uint)
    (would-hire-again bool)
    (feedback-comments (string-ascii 300))
)
    (let (
        (feedback-id (+ (var-get feedback-counter) u1))
    )
        ;; Validate ratings are within range
        (asserts! (and (<= quality-rating u5) (>= quality-rating u1)) err-invalid-rating)
        (asserts! (and (<= skill-accuracy u5) (>= skill-accuracy u1)) err-invalid-rating)
        (asserts! (and (<= hire-success u5) (>= hire-success u1)) err-invalid-rating)
        
        ;; Update feedback counter
        (var-set feedback-counter feedback-id)
        
        ;; Store feedback
        (ok (map-set employer-credential-feedback
            {employer: tx-sender, university: university, feedback-id: feedback-id}
            {
                credential-quality-rating: quality-rating,
                skill-accuracy-rating: skill-accuracy,
                hire-success-rating: hire-success,
                would-hire-again: would-hire-again,
                feedback-date: stacks-block-height,
                comments: feedback-comments
            }
        ))
    )
)

;; Record employment outcome for credential holder
(define-public (record-employment-outcome
    (student principal)
    (credential-id uint)
    (months-to-employment uint)
    (salary-range uint)
    (job-relevance uint)
    (employer-principal (optional principal))
)
    (begin
        ;; Validate input ranges
        (asserts! (<= months-to-employment u24) err-invalid-timeframe) ;; max 24 months
        (asserts! (and (<= salary-range u10) (>= salary-range u1)) err-invalid-rating)
        (asserts! (and (<= job-relevance u5) (>= job-relevance u1)) err-invalid-rating)
        
        (ok (map-set employment-outcomes
            {student: student, credential-id: credential-id}
            {
                employed-within-months: months-to-employment,
                starting-salary-range: salary-range,
                job-relevance-score: job-relevance,
                employer-principal: employer-principal,
                outcome-verified: (is-some employer-principal),
                report-date: stacks-block-height
            }
        ))
    )
)

;; Calculate university analytics for a given period
(define-public (calculate-university-analytics
    (university principal)
    (period-type uint) ;; 1=monthly, 2=quarterly, 3=yearly
)
    (let (
        (current-block stacks-block-height)
        (period-blocks (if (is-eq period-type u1) 
                          monthly-window 
                          (if (is-eq period-type u2) quarterly-window yearly-window)))
        (period-start (- current-block period-blocks))
    )
        ;; Calculate basic metrics (simplified calculation)
        (let (
            (credentials-issued u10) ;; Would calculate from actual data
            (verification-requests u8)
            (success-rate u8500) ;; 85% success rate
            (avg-verify-time u144) ;; average blocks to verify
            (employer-satisfaction u420) ;; 4.2/5 * 100
            (skill-accuracy u9200) ;; 92% accuracy
        )
            (ok (map-set university-analytics
                {university: university, period: period-start}
                {
                    credentials-issued: credentials-issued,
                    verification-requests: verification-requests,
                    verification-success-rate: success-rate,
                    average-time-to-verify: avg-verify-time,
                    employer-satisfaction-score: employer-satisfaction,
                    skill-verification-accuracy: skill-accuracy,
                    last-updated: current-block
                }
            ))
        )
    )
)

;; Calculate university reputation score
(define-public (calculate-reputation-score
    (university principal)
)
    (let (
        ;; Get recent analytics data
        (recent-analytics (map-get? university-analytics {university: university, period: (- stacks-block-height monthly-window)}))
        ;; Calculate component scores
        (quality-component u850) ;; Based on verification accuracy
        (reliability-component u780) ;; Based on consistent performance  
        (innovation-component u650) ;; Based on new offerings
        (trust-component u720) ;; Based on employer feedback
        ;; Calculate weighted overall score
        (overall-reputation (/ (+ (* quality-component u3) (* reliability-component u2) (* innovation-component u2) (* trust-component u3)) u10))
    )
        (ok (map-set university-reputation
            university
            {
                overall-score: overall-reputation,
                quality-score: quality-component,
                reliability-score: reliability-component,
                innovation-score: innovation-component,
                employer-trust-score: trust-component,
                last-calculated: stacks-block-height,
                trending-direction: "stable"
            }
        ))
    )
)

;; Update skill market trends
(define-public (update-skill-trends
    (skill-id uint)
    (search-frequency uint)
    (avg-proficiency uint)
    (salary-impact uint)
    (growth-rate uint)
    (geographic-region (string-ascii 50))
    (related-skills (list 5 uint))
)
    (let (
        (current-period (- stacks-block-height monthly-window))
    )
        ;; Validate inputs
        (asserts! (<= avg-proficiency u5) err-invalid-rating)
        (asserts! (<= salary-impact u500) err-invalid-rating)
        (asserts! (<= growth-rate u10000) err-invalid-rating) ;; max 100% growth
        
        (ok (map-set skill-market-trends
            {skill-id: skill-id, period: current-period}
            {
                search-frequency: search-frequency,
                average-proficiency-required: avg-proficiency,
                salary-impact-score: salary-impact,
                growth-rate: growth-rate,
                geographic-demand: geographic-region,
                complementary-skills: related-skills
            }
        ))
    )
)

;; Configure analytics system
(define-public (configure-analytics
    (config-key (string-ascii 50))
    (enabled bool)
    (update-freq uint)
    (retention-period uint)
    (calc-method (string-ascii 30))
)
    (ok (map-set analytics-config
        config-key
        {
            enabled: enabled,
            update-frequency: update-freq,
            data-retention-period: retention-period,
            calculation-method: calc-method
        }
    ))
)

;; Read-only functions for querying analytics data

(define-read-only (get-university-analytics
    (university principal)
    (period uint)
)
    (map-get? university-analytics {university: university, period: period})
)

(define-read-only (get-university-reputation
    (university principal)
)
    (map-get? university-reputation university)
)

(define-read-only (get-skill-trends
    (skill-id uint)
    (period uint)
)
    (map-get? skill-market-trends {skill-id: skill-id, period: period})
)

(define-read-only (get-employment-outcome
    (student principal)
    (credential-id uint)
)
    (map-get? employment-outcomes {student: student, credential-id: credential-id})
)

(define-read-only (get-employer-feedback
    (employer principal)
    (university principal)
    (feedback-id uint)
)
    (map-get? employer-credential-feedback {employer: employer, university: university, feedback-id: feedback-id})
)

(define-read-only (get-credential-market-data
    (course-hash (string-ascii 64))
    (period uint)
)
    (map-get? credential-market-data {course-hash: course-hash, period: period})
)

;; Calculate market value score for a credential type
(define-read-only (calculate-market-value
    (course-hash (string-ascii 64))
    (period uint)
)
    (match (get-credential-market-data course-hash period)
        market-data (ok {
            demand-score: (get employer-demand-score market-data),
            salary-indicator: (get average-salary-indicator market-data),
            employment-rate: (get employment-rate market-data),
            trend: (get market-trend market-data)
        })
        (err err-analytics-not-found)
    )
)

;; Get analytics configuration
(define-read-only (get-analytics-config
    (config-key (string-ascii 50))
)
    (map-get? analytics-config config-key)
)

;; Compare university performance
(define-read-only (compare-universities
    (university-a principal)
    (university-b principal)
)
    (let (
        (rep-a (get-university-reputation university-a))
        (rep-b (get-university-reputation university-b))
    )
        (match rep-a
            reputation-a (match rep-b
                reputation-b (ok {
                    university-a-score: (get overall-score reputation-a),
                    university-b-score: (get overall-score reputation-b),
                    quality-advantage: (if (> (get quality-score reputation-a) (get quality-score reputation-b)) "university-a" "university-b"),
                    trust-advantage: (if (> (get employer-trust-score reputation-a) (get employer-trust-score reputation-b)) "university-a" "university-b")
                })
                (err err-analytics-not-found)
            )
            (err err-analytics-not-found)
        )
    )
)

;; Get current analytics status
(define-read-only (get-analytics-status)
    (ok {
        last-update: (var-get analytics-last-update),
        total-feedback-entries: (var-get feedback-counter),
        system-active: true
    })
)


