;; HarvestPro - Crop Yield Tracking System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-plot-exists (err u101))
(define-constant err-plot-not-found (err u102))
(define-constant err-invalid-yield (err u103))
(define-constant err-invalid-timestamp (err u104))
(define-constant err-contract-paused (err u105))
(define-constant max-yield-amount u1000000) ;; Maximum reasonable yield amount

;; Contract status
(define-data-var contract-paused bool false)

;; Data structures
(define-map plots
  { plot-id: (string-ascii 20) }
  {
    owner: principal,
    name: (string-ascii 50),
    registered-at: uint,
    status: (string-ascii 10),  ;; "active" or "inactive"
    total-yield: uint
  }
)

(define-map harvests
  { plot-id: (string-ascii 20), timestamp: uint }
  {
    crop-type: (string-ascii 20),
    yield-amount: uint
  }
)

;; Administrative functions
(define-public (set-contract-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-authorized)
    (ok (var-set contract-paused paused))
  )
)

;; Helper functions
(define-private (validate-timestamp (timestamp uint))
  (< timestamp block-height)
)

(define-private (validate-yield-amount (amount uint))
  (and (> amount u0) (<= amount max-yield-amount))
)

(define-private (update-total-yield (plot-id (string-ascii 20)) (yield-amount uint))
  (match (get-plot-data plot-id)
    plot-data (let ((current-total (default-to u0 (get total-yield plot-data))))
      (map-set plots
        { plot-id: plot-id }
        (merge plot-data { total-yield: (+ current-total yield-amount) })
      )
    )
    false
  )
)

;; Public functions
(define-public (register-plot (plot-id (string-ascii 20)) (name (string-ascii 50)))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (let ((existing-plot (get-plot-data plot-id)))
      (if (is-some existing-plot)
        err-plot-exists
        (begin
          (map-set plots
            { plot-id: plot-id }
            {
              owner: tx-sender,
              name: name,
              registered-at: block-height,
              status: "active",
              total-yield: u0
            }
          )
          (ok true)
        )
      )
    )
  )
)

(define-public (record-harvest (plot-id (string-ascii 20)) (yield-amount uint) (crop-type (string-ascii 20)) (timestamp uint))
  (begin
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (validate-yield-amount yield-amount) err-invalid-yield)
    (asserts! (validate-timestamp timestamp) err-invalid-timestamp)
    (let ((plot-data (get-plot-data plot-id)))
      (if (and
            (is-some plot-data)
            (is-eq (get owner (unwrap-panic plot-data)) tx-sender)
          )
        (begin
          (map-set harvests
            { plot-id: plot-id, timestamp: timestamp }
            {
              crop-type: crop-type,
              yield-amount: yield-amount
            }
          )
          (update-total-yield plot-id yield-amount)
          (ok true)
        )
        err-not-authorized
      )
    )
  )
)

(define-public (set-plot-status (plot-id (string-ascii 20)) (new-status (string-ascii 10)))
  (let ((plot-data (get-plot-data plot-id)))
    (if (and
          (is-some plot-data)
          (is-eq (get owner (unwrap-panic plot-data)) tx-sender)
        )
      (begin
        (map-set plots
          { plot-id: plot-id }
          (merge (unwrap-panic plot-data) { status: new-status })
        )
        (ok true)
      )
      err-not-authorized
    )
  )
)

;; Read only functions
(define-read-only (get-plot-data (plot-id (string-ascii 20)))
  (map-get? plots { plot-id: plot-id })
)

(define-read-only (get-harvest-data (plot-id (string-ascii 20)) (timestamp uint))
  (map-get? harvests { plot-id: plot-id, timestamp: timestamp })
)

(define-read-only (get-plot-owner (plot-id (string-ascii 20)))
  (let ((plot-data (get-plot-data plot-id)))
    (if (is-some plot-data)
      (ok (get owner (unwrap-panic plot-data)))
      err-plot-not-found
    )
  )
)

(define-read-only (get-total-yield (plot-id (string-ascii 20)))
  (match (get-plot-data plot-id)
    plot-data (ok (get total-yield plot-data))
    err-plot-not-found
  )
)
