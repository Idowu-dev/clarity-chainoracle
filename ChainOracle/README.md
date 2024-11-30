# ChainOracle: Cross-Chain Price Aggregator

ChainOracle is a decentralized cross-chain price aggregator designed to provide reliable, real-time price feeds from multiple blockchain networks. It aggregates and verifies price data from authorized sources across different chains (such as Bitcoin, Ethereum, and Solana) and ensures data accuracy through a series of validation and security checks.

This contract can be used for applications requiring price data such as decentralized finance (DeFi) protocols, liquidity pools, and automated trading strategies. The contract includes built-in mechanisms for protecting against price manipulation and stale price feeds.

---

## Features

- **Cross-Chain Price Aggregation**: Collects price data from multiple blockchains including Bitcoin (BTC), Ethereum (ETH), and Solana (SOL).
- **Data Validation**: Ensures the accuracy and reliability of price data by verifying signatures, enforcing volatility checks, and ensuring sufficient volume.
- **Price Updates**: Allows price providers to submit updated prices, ensuring that only authorized providers can update the feed.
- **Weighting and Normalization**: Aggregated prices are weighted by the source’s historical accuracy and volume. Prices are then normalized to account for volatility.
- **Slippage Protection**: Ensures that price updates fall within an acceptable deviation range to prevent significant slippage in trades.
- **Security**: Implements a commit-reveal mechanism to protect against malicious price manipulation and supports cross-chain proofs to verify data across different blockchain networks.

---

## Key Components

### **Price Feed Data Structure**
The price feed data for each chain includes the following:

- `price`: The price in USD (6 decimals).
- `timestamp`: The last update time.
- `volume`: The 24-hour trading volume in USD.
- `weight`: The weight assigned to the price source (0-100).
- `verified`: Whether the price is cross-chain verified.

### **Price Feed Configuration**
The contract is configured with the following parameters:

- `price-validity-period`: The period (in seconds) during which price data is considered valid. Default: 900 seconds (15 minutes).
- `max-price-deviation`: The maximum allowed price deviation (in basis points). Default: 1000 basis points (10%).
- `min-required-sources`: The minimum number of sources required for a valid price feed. Default: 2 sources.
- `min-volume-threshold`: The minimum volume in USD for a price feed to be considered valid. Default: 10,000 USD.
- `slippage-tolerance`: The allowable slippage in price updates, in basis points. Default: 50 basis points (0.5%).

---

## Functions

### **Administrative Functions**

- **`set-authorized-provider(provider, authorized)`**  
  Sets whether a price provider is authorized. Only the contract owner can call this function.

- **`set-configuration(validity-period, max-deviation, required-sources, volume-threshold, slippage)`**  
  Allows the contract owner to configure the price feed settings such as validity period, max deviation, and slippage tolerance.

---

### **Price Submission Functions**

- **`submit-price(target-chain-id, price, volume, cross-chain-proof)`**  
  Submits a price update for a given chain (e.g., Bitcoin, Ethereum). Price data is validated based on volume, deviation, and cross-chain verification. Only authorized providers can submit prices.

---

### **Price Retrieval Functions**

- **`get-weighted-price(requested-chain-id)`**  
  Retrieves the weighted average price for a specific chain, factoring in the price, volume, and weight of sources.

- **`get-normalized-price(requested-chain-id)`**  
  Retrieves the normalized price, adjusting for volatility based on historical price data.

---

### **Helper Functions**

- **`is-valid-chain(target-chain-id)`**  
  Checks whether the given chain ID is a supported chain (e.g., BTC, ETH, SOL).

- **`is-valid-price-change(target-chain-id, new-price)`**  
  Ensures that the price change for a given chain does not exceed the maximum allowed deviation from the last reported price.

- **`verify-cross-chain-proof(target-chain-id, price, proof)`**  
  Verifies cross-chain proofs to ensure the submitted price is valid and has been cross-verified by another chain.

- **`update-price-history(target-chain-id, price, timestamp)`**  
  Updates the historical price data for a given chain, including volatility calculations.

- **`normalize-price(price, volatility)`**  
  Normalizes the price by adjusting for volatility based on historical data.

- **`check-slippage(price, expected-price)`**  
  Checks if the submitted price falls within the acceptable slippage range.

---

## Error Handling

The contract defines several error messages for handling invalid conditions:

- `ERR-NOT-AUTHORIZED`: The caller is not authorized to perform this action.
- `ERR-INVALID-CHAIN`: The provided chain ID is not supported.
- `ERR-INVALID-PRICE`: The submitted price is invalid.
- `ERR-INVALID-WEIGHT`: The source weight is invalid.
- `ERR-STALE-PRICE`: The price data is outdated.
- `ERR-HIGH-DEVIATION`: The price change exceeds the allowed deviation.
- `ERR-INSUFFICIENT-SOURCES`: There are not enough valid price sources to provide a reliable feed.
- `ERR-BELOW-MIN-VOLUME`: The trading volume for the price is below the minimum threshold.

---

## Use Cases

1. **DeFi Protocols**: Provide reliable price feeds for smart contract-based lending, borrowing, and yield farming protocols.
2. **Liquidity Pools**: Enable decentralized exchanges and liquidity pools to access real-time, cross-chain price data for asset valuation.
3. **Arbitrage Bots**: Ensure price accuracy and prevent manipulation in automated trading strategies across chains.
4. **Cross-Chain Bridges**: Enable price data sharing and verification across different blockchains for secure cross-chain transfers.

---

## Security Considerations

- **Price Feed Manipulation Protection**: The contract ensures that only authorized providers can submit prices, and price changes must fall within an acceptable deviation threshold.
- **Cross-Chain Verification**: Cross-chain proofs are used to validate the authenticity of price data, protecting against manipulation.
- **Slippage Protection**: Price updates are checked for slippage to ensure they fall within an acceptable range.

---

## Future Enhancements

- Support for additional blockchains and price providers.
- Dynamic source weight calculation based on historical accuracy and volume.
- Advanced price aggregation algorithms for higher accuracy.