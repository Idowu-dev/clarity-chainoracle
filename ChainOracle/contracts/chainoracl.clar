;; Cross-Chain Price Aggregator
;; Provides reliable price feeds from multiple chains with built-in security features

;; Constants for configuration
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-CHAIN (err u101))
(define-constant ERR-INVALID-PRICE (err u102))
(define-constant ERR-INVALID-WEIGHT (err u103))
(define-constant ERR-STALE-PRICE (err u104))
(define-constant ERR-HIGH-DEVIATION (err u105))
(define-constant ERR-INSUFFICIENT-SOURCES (err u106))
(define-constant ERR-BELOW-MIN-VOLUME (err u107))

;; Chain identifiers
(define-constant CHAIN-BTC u1)
(define-constant CHAIN-ETH u2)
(define-constant CHAIN-SOL u3)

;; Configuration variables
(define-data-var price-validity-period uint u900)  ;; 15 minutes
(define-data-var max-price-deviation uint u1000)   ;; 10% in basis points
(define-data-var min-required-sources uint u2)     ;; Minimum sources for valid price
(define-data-var min-volume-threshold uint u10000) ;; Minimum volume in USD
(define-data-var slippage-tolerance uint u50)      ;; 0.5% in basis points

;; Price feed data structure
(define-map price-feeds
    { chain-id: uint, source: principal }
    {
        price: uint,          ;; Price in USD (6 decimals)
        timestamp: uint,      ;; Last update timestamp
        volume: uint,         ;; 24h volume in USD
        weight: uint,         ;; Source weight (0-100)
        verified: bool        ;; Cross-chain verification status
    }
)

;; Track authorized price feed providers
(define-map authorized-providers principal bool)

;; Track historical prices for volatility checks
(define-map price-history
    { chain-id: uint }
    {
        last-price: uint,
        last-update: uint,
        volatility-index: uint
    }
)

;; Administrative Functions

(define-public (set-authorized-provider (provider principal) (authorized bool))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (ok (map-set authorized-providers provider authorized))
    )
)

(define-public (set-configuration
    (validity-period uint)
    (max-deviation uint)
    (required-sources uint)
    (volume-threshold uint)
    (slippage uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
        (var-set price-validity-period validity-period)
        (var-set max-price-deviation max-deviation)
        (var-set min-required-sources required-sources)
        (var-set min-volume-threshold volume-threshold)
        (var-set slippage-tolerance slippage)
        (ok true)
    )
)

;; Price Submission and Updates

(define-public (submit-price
    (chain-id uint)
    (price uint)
    (volume uint)
    (cross-chain-proof (optional (buff 64))))
    (let (
        (current-time (unwrap! (get-block-info? time (- block-height u1)) ERR-INVALID-PRICE))
        (provider-authorized (default-to false (map-get? authorized-providers tx-sender)))
    )
        (asserts! provider-authorized ERR-NOT-AUTHORIZED)
        (asserts! (is-valid-chain chain-id) ERR-INVALID-CHAIN)
        (asserts! (>= volume (var-get min-volume-threshold)) ERR-BELOW-MIN-VOLUME)
        (asserts! (is-valid-price-change chain-id price) ERR-HIGH-DEVIATION)
        
        (map-set price-feeds
            { chain-id: chain-id, source: tx-sender }
            {
                price: price,
                timestamp: current-time,
                volume: volume,
                weight: (get-source-weight tx-sender),
                verified: (verify-cross-chain-proof chain-id price cross-chain-proof)
            }
        )
        
        (update-price-history chain-id price current-time)
        (ok true)
    )
)

;; Price Retrieval Functions

(define-read-only (get-weighted-price (chain-id uint))
    (let (
        (valid-feeds (get-valid-price-feeds chain-id))
        (total-weight (fold + u0 (map get-feed-weight valid-feeds)))
    )
        (asserts! (>= (len valid-feeds) (var-get min-required-sources)) ERR-INSUFFICIENT-SOURCES)
        (ok (/ (fold + u0 (map calculate-weighted-price valid-feeds)) total-weight))
    )
)

(define-read-only (get-normalized-price (chain-id uint))
    (let (
        (weighted-price (unwrap! (get-weighted-price chain-id) ERR-INVALID-PRICE))
        (volatility (get-volatility-index chain-id))
    )
        (ok (normalize-price weighted-price volatility))
    )
)

;; Helper Functions

(define-private (is-valid-chain (chain-id uint))
    (or (is-eq chain-id CHAIN-BTC)
        (is-eq chain-id CHAIN-ETH)
        (is-eq chain-id CHAIN-SOL))
)

(define-private (is-valid-price-change (chain-id uint) (new-price uint))
    (let (
        (history (default-to { last-price: u0, last-update: u0, volatility-index: u0 }
            (map-get? price-history { chain-id: chain-id })))
        (price-change (if (is-eq (get last-price history) u0)
            u0
            (abs (- new-price (get last-price history)))))
        (max-allowed-change (* (get last-price history) (var-get max-price-deviation)))
    )
        (<= price-change max-allowed-change)
    )
)

(define-private (verify-cross-chain-proof (chain-id uint) (price uint) (proof (optional (buff 64))))
    (match proof
        proof-value (verify-signature chain-id price proof-value)
        true)
)

(define-private (verify-signature (chain-id uint) (price uint) (signature (buff 64)))
    ;; Implementation would verify cross-chain signatures
    ;; This is a placeholder that would need chain-specific implementation
    true
)

(define-private (get-source-weight (source principal))
    ;; Calculate weight based on source's historical accuracy and volume
    u50  ;; Default weight, would be dynamic in production
)

(define-private (get-valid-price-feeds (chain-id uint))
    (filter is-valid-feed
        (map-get? price-feeds { chain-id: chain-id, source: tx-sender }))
)

(define-private (is-valid-feed (feed (optional {
    price: uint,
    timestamp: uint,
    volume: uint,
    weight: uint,
    verified: bool
})))
    (match feed
        feed-data (and
            (>= (unwrap-panic (get-block-info? time (- block-height u1)))
                (- (get timestamp feed-data) (var-get price-validity-period)))
            (get verified feed-data)
            (>= (get volume feed-data) (var-get min-volume-threshold)))
        false)
)

(define-private (calculate-weighted-price (feed {
    price: uint,
    timestamp: uint,
    volume: uint,
    weight: uint,
    verified: bool
}))
    (* (get price feed) (get weight feed))
)

(define-private (get-feed-weight (feed {
    price: uint,
    timestamp: uint,
    volume: uint,
    weight: uint,
    verified: bool
}))
    (get weight feed)
)

(define-private (update-price-history (chain-id uint) (price uint) (timestamp uint))
    (let (
        (current-history (default-to
            { last-price: u0, last-update: u0, volatility-index: u0 }
            (map-get? price-history { chain-id: chain-id })))
    )
        (map-set price-history
            { chain-id: chain-id }
            {
                last-price: price,
                last-update: timestamp,
                volatility-index: (calculate-volatility
                    price
                    (get last-price current-history)
                    (get volatility-index current-history))
            }
        )
    )
)

(define-private (calculate-volatility (new-price uint) (old-price uint) (current-volatility uint))
    (if (is-eq old-price u0)
        u0
        (+ (* current-volatility u95) (* (abs (- new-price old-price)) u5))
    )
)

(define-private (normalize-price (price uint) (volatility uint))
    (let (
        (volatility-adjustment (/ (* price volatility) u10000))
    )
        (+ price volatility-adjustment)
    )
)

;; Slippage Protection

(define-private (check-slippage (price uint) (expected-price uint))
    (let (
        (deviation (* expected-price (var-get slippage-tolerance)))
        (max-price (+ expected-price deviation))
        (min-price (- expected-price deviation))
    )
        (and (>= price min-price) (<= price max-price))
    )
)