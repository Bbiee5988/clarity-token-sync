;; Token Sync Contract
;; Manages synchronized token states

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-state (err u101))
(define-constant err-asset-exists (err u102))

;; Data structures
(define-map asset-states
  { asset-id: uint }
  {
    owner: principal,
    state: uint,
    last-update: uint,
    version: uint
  }
)

(define-map sync-requests
  { asset-id: uint, requestor: principal }
  {
    proposed-state: uint,
    timestamp: uint,
    status: (string-ascii 10)
  }
)

;; Asset registration
(define-public (register-asset (asset-id uint) (initial-state uint))
  (let
    (
      (asset (map-get? asset-states { asset-id: asset-id }))
    )
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-none asset) err-asset-exists)
    (ok (map-set asset-states
      { asset-id: asset-id }
      {
        owner: tx-sender,
        state: initial-state,
        last-update: block-height,
        version: u1
      }
    ))
  )
)

;; State update request
(define-public (request-sync (asset-id uint) (new-state uint))
  (let
    (
      (asset (unwrap! (map-get? asset-states { asset-id: asset-id }) err-invalid-state))
    )
    (ok (map-set sync-requests
      { asset-id: asset-id, requestor: tx-sender }
      {
        proposed-state: new-state,
        timestamp: block-height,
        status: "PENDING"
      }
    ))
  )
)

;; Approve sync request
(define-public (approve-sync (asset-id uint) (requestor principal))
  (let
    (
      (asset (unwrap! (map-get? asset-states { asset-id: asset-id }) err-invalid-state))
      (request (unwrap! (map-get? sync-requests { asset-id: asset-id, requestor: requestor }) err-invalid-state))
    )
    (asserts! (is-eq (get owner asset) tx-sender) err-unauthorized)
    (map-set asset-states
      { asset-id: asset-id }
      {
        owner: (get owner asset),
        state: (get proposed-state request),
        last-update: block-height,
        version: (+ (get version asset) u1)
      }
    )
    (ok (map-set sync-requests
      { asset-id: asset-id, requestor: requestor }
      {
        proposed-state: (get proposed-state request),
        timestamp: block-height,
        status: "APPROVED"
      }
    ))
  )
)

;; Read-only functions
(define-read-only (get-asset-state (asset-id uint))
  (ok (map-get? asset-states { asset-id: asset-id }))
)

(define-read-only (get-sync-request (asset-id uint) (requestor principal))
  (ok (map-get? sync-requests { asset-id: asset-id, requestor: requestor }))
)
