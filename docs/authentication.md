## PenguinDB Authentication System

> **An authentication system for PenguinDB with user management, session handling, and role-based access control.** 

> **This module provides secure authentication mechanisms using password hashing, session tokens, and file-based storage.**

---

### Core Authentication Components:

```plaintext
User Management
├── Registration
├── Authentication
└── Password Management

Session Management
├── Token Generation
├── Validation
└── Expiration

Access Control
├── Role-based (User/Admin)
└── Permission Checks

Data Storage
├── Users File (tab-delimited)
└── Sessions File (tab-delimited)
```
---

### Records Formats:

- **User Record Format:**

```plaintext
username|password_hash|email|role|created_at|status
```

- **User Record Format:**

```plaintext
session_token|username|created_at|expires_at|status
```
---

### Security Implementation:

#### Password Security:

- **Algorithm:** SHA-256 hashing

- **Storage:** Hashed passwords only

- **Validation:** Minimum length configurable via `$MIN_PASSWORD_LENGTH` from `src/config.sh`.

#### Session Security:

- **Token Generation:** `timestamp_randomString` format.

- **Expiration:** 24-hour session lifetime.

- **Validation:** Checks expiration and active status.

#### Input Validation:
- **Usernames:** Alphanumeric + underscore only.

- **Emails:** Basic regex validation.

- **Passwords:** Minimum length enforcement.
---

### w

