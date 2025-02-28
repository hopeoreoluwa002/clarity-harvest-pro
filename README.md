# HarvestPro
A blockchain system for tracking crop yields on the Stacks network.

## Features
- Register farm plots with unique identifiers
- Record crop yields and harvest data 
- Track historical harvest records per plot
- Get yield statistics and analytics
- Multi-farmer support with access controls

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify the contract
4. Run `clarinet test` to run the test suite

## Usage Examples
```clarity
;; Register a new farm plot
(contract-call? .harvest-pro register-plot "PLOT-001" "Corn Field North")

;; Record a harvest
(contract-call? .harvest-pro record-harvest "PLOT-001" u5000 "Corn" u1654012800)

;; Get harvest history for a plot
(contract-call? .harvest-pro get-plot-history "PLOT-001")
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
