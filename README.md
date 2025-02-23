# EduCred - Educational Credential Verification System

## Overview
EduCred is a decentralized educational credential verification system built on the Stacks blockchain using Clarity smart contracts. It enables universities to issue and manage digital credentials while allowing employers and third parties to verify academic achievements securely and transparently.

## Features
- University registration and verification
- Secure credential issuance
- Immutable credential records
- Real-time verification
- Timestamped certificates

## Smart Contract Architecture

### Data Structures
- `universities`: Mapping of university principals to their verification status
- `credentials`: Mapping of student credentials with course details
- `credential-counter`: Tracks credential IDs per university

### Key Functions

#### Administrative
- `register-university`: Registers authorized universities
  - Parameters: university principal, university name
  - Access: Contract owner only

#### Credential Management
- `issue-credential`: Issues new credentials to students
  - Parameters: student principal, course name
  - Access: Verified universities only

#### Verification
- `verify-credential`: Verifies credential authenticity
  - Parameters: student principal, credential ID
  - Returns: Validity status

#### Read-Only Functions
- `get-university`: Retrieves university information
- `get-credential`: Retrieves credential details
- `get-credential-count`: Gets total credentials issued by a university

## Error Codes
- `err-not-authorized (u100)`: Unauthorized access attempt
- `err-already-registered (u101)`: Duplicate registration attempt
- `err-not-found (u102)`: Requested data not found

## Security Features
- Role-based access control
- Immutable credential records
- Verified university status checks
- Blockchain-based timestamp verification

## Getting Started

### Prerequisites
- Clarinet
- Stacks wallet
- Node.js

### Deployment
1. Clone the repository
2. Install dependencies
3. Deploy using Clarinet

### Usage Example
```clarity
;; Register a university
(contract-call? .educred register-university university-principal "University Name")

;; Issue a credential
(contract-call? .educred issue-credential student-principal "Course Name")

;; Verify a credential
(contract-call? .educred verify-credential student-principal credential-id)
