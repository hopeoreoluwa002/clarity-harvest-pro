;; HarvestPro - Crop Yield Tracking System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-plot-exists (err u101))
(define-constant err-plot-not-found (err u102))
(define-constant err-invalid-yield (err u103))

;; Data structures
(define-map plots
  { plot-id: (string-ascii 20) }
  {
    owner: principal,
    name: (string-ascii 50),
    registered-at: uint
  }
)

(define-map harvests
  { plot-id: (string-ascii 20), timestamp: uint }
  {
    crop-type: (string-ascii 20),
    yield-amount: uint
  }
)

;; Public functions
(define-public (register-plot (plot-id (string-ascii 20)) (name (string-ascii 50)))
  (let ((existing-plot (get-plot-data plot-id)))
    (if (is-some existing-plot)
      err-plot-exists
      (begin
        (map-set plots
          { plot-id: plot-id }
          {
            owner: tx-sender,
            name: name,
            registered-at: block-height
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (record-harvest (plot-id (string-ascii 20)) (yield-amount uint) (crop-type (string-ascii 20)) (timestamp uint))
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
