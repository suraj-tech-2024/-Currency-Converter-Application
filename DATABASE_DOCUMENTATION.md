# Currency Converter - Database & System Architecture

## 📊 Database Schema Overview

### **Tables**

#### 1. **USERS** Table
Stores user registration and authentication data.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT (PK) | Unique user identifier |
| `username` | VARCHAR(255) UNIQUE | Login username |
| `email` | VARCHAR(255) UNIQUE | User email address |
| `password` | VARCHAR(255) | BCrypt hashed password |
| `created_at` | TIMESTAMP | Account creation time |
| `last_login` | TIMESTAMP | Last successful login |
| `is_active` | BOOLEAN | Account status |

#### 2. **CONVERSION_HISTORY** Table
Records all currency conversion transactions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT (PK) | Unique conversion ID |
| `user_id` | BIGINT (FK) | References users.id |
| `amount` | DECIMAL(38,2) | Original amount |
| `from_currency` | VARCHAR(10) | Source currency code |
| `to_currency` | VARCHAR(10) | Target currency code |
| `result` | DECIMAL(38,2) | Converted amount |
| `exchange_rate` | DECIMAL(20,10) | Exchange rate used |
| `timestamp` | TIMESTAMP | Conversion time |

---

## 🏗️ System Architecture

### **Backend Components**

```
com.currencyconverter/
├── config/
│   ├── AppConfig.java              # Application configuration & BCrypt
│   └── SecurityConfig.java         # Spring Security configuration
├── controller/
│   ├── AuthController.java         # /api/auth/** - Registration & Login
│   ├── ConversionController.java   # /api/convert/** - Currency conversion
│   ├── UserController.java         # /api/user/** - User profile
│   ├── DatabaseController.java     # /api/db/** - Database queries
│   └── HomeController.java         # Home page routing
├── model/
│   ├── User.java                   # User entity (JPA)
│   └── ConversionHistory.java      # Conversion history entity (JPA)
├── repository/
│   ├── UserRepository.java         # User CRUD operations
│   └── ConversionHistoryRepository.java  # Conversion CRUD operations
├── service/
│   ├── UserService.java            # User business logic
│   └── ConversionService.java      # Conversion business logic
└── CurrencyConverterApplication.java  # Main Spring Boot application
```

### **Frontend Components**

```
src/main/resources/static/
├── index.html          # Login/Registration page
└── dashboard.html      # Currency converter & history dashboard
```

---

## 🔄 Application Flow

### **1. User Registration**

```
Client (Browser)
    ↓
POST /api/auth/register
    ↓
AuthController.register()
    ↓
UserService.registerUser()
    ↓
BCrypt password encoding
    ↓
UserRepository.save()
    ↓
INSERT INTO users (username, email, password)
    ↓
Response: Success/Error
```

### **2. User Login**

```
Client (Browser)
    ↓
POST /api/auth/login
    ↓
AuthController.login()
    ↓
UserService.loadUserByUsername()
    ↓
SELECT * FROM users WHERE username = ?
    ↓
BCrypt password verification
    ↓
Spring Security authentication
    ↓
Session creation (JSESSIONID)
    ↓
Response: Success + Session Cookie
```

### **3. Currency Conversion**

```
Client (Browser)
    ↓
POST /api/convert {amount, from, to}
    ↓
ConversionController.convertCurrency()
    ↓
Check authentication (Session)
    ↓
ConversionService.convert()
    ↓
Calculate: result = amount × exchange_rate
    ↓
Create ConversionHistory object
    ↓
ConversionHistoryRepository.save()
    ↓
INSERT INTO conversion_history 
    (user_id, amount, from_currency, to_currency, result, timestamp)
    ↓
Response: {result, from, to}
```

### **4. View Conversion History**

```
Client (Browser)
    ↓
GET /api/convert/history
    ↓
ConversionController.getHistory()
    ↓
Get current user from session
    ↓
ConversionHistoryRepository.findByUserIdOrderByTimestampDesc()
    ↓
SELECT * FROM conversion_history 
WHERE user_id = ? 
ORDER BY timestamp DESC
    ↓
Response: List<ConversionHistory>
```

---

## 🗄️ Database Connection

### **Current Setup: H2 File-Based Database**

```properties
# application.properties
spring.datasource.url=jdbc:h2:file:./data/currency_converter_db
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true
```

**Database File Location:** `./data/currency_converter_db.mv.db`

**H2 Console Access:** `http://localhost:8080/h2-console`

---

## 🔐 Security Configuration

### **Permitted URLs (No Authentication Required)**
- `/` - Home page
- `/index.html` - Login/Registration page
- `/api/auth/**` - Authentication endpoints
- `/api/db/**` - Database query endpoints
- `/h2-console/**` - H2 database console

### **Protected URLs (Authentication Required)**
- `/dashboard.html` - User dashboard
- `/api/convert/**` - Currency conversion
- `/api/user/**` - User profile

### **Authentication Method**
- **Type:** Session-based (JSESSIONID cookie)
- **Password Encoding:** BCrypt
- **Session Policy:** ALWAYS create sessions

---

## 📝 API Endpoints

### **Authentication APIs**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | User registration |
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/logout` | User logout |

### **User APIs**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/user/profile` | Get current user profile |

### **Conversion APIs**

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/convert` | Perform currency conversion |
| GET | `/api/convert/history` | Get user conversion history |

### **Database Query APIs**

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/db/users` | Get all users |
| GET | `/api/db/conversions` | Get all conversions |
| GET | `/api/db/conversions-with-users` | Get conversions with user details |
| POST | `/api/db/query` | Execute custom SQL query |

---

## 🚀 Running the Application

### **Start the Application**

```bash
mvn spring-boot:run
```

**Application URL:** `http://localhost:8080`

### **Access H2 Console**

```
URL: http://localhost:8080/h2-console
JDBC URL: jdbc:h2:file:./data/currency_converter_db
Username: sa
Password: (leave blank)
```

---

## 💻 Database Query Commands

### **PowerShell Script**

```powershell
# View all users
.\query_db.ps1 users

# View all conversions
.\query_db.ps1 conversions

# View conversions with user details
.\query_db.ps1 all
```

### **Direct REST API**

```powershell
# Get all users
Invoke-RestMethod http://localhost:8080/api/db/users | ConvertTo-Json

# Get all conversions
Invoke-RestMethod http://localhost:8080/api/db/conversions | ConvertTo-Json

# Get conversions with user details
Invoke-RestMethod http://localhost:8080/api/db/conversions-with-users | ConvertTo-Json
```

### **H2 Console SQL Queries**

```sql
-- View all users
SELECT * FROM users;

-- View all conversions with user details
SELECT u.username, ch.amount, ch.from_currency, ch.to_currency, 
       ch.result, ch.timestamp
FROM conversion_history ch
JOIN users u ON ch.user_id = u.id
ORDER BY ch.timestamp DESC;

-- Count total users
SELECT COUNT(*) as total_users FROM users;

-- Count total conversions
SELECT COUNT(*) as total_conversions FROM conversion_history;

-- User conversion statistics
SELECT u.username, 
       COUNT(ch.id) as total_conversions,
       MIN(ch.timestamp) as first_conversion,
       MAX(ch.timestamp) as last_conversion
FROM users u
LEFT JOIN conversion_history ch ON u.id = ch.user_id
GROUP BY u.username;
```

---

## 🎨 Color Theme

The application uses a warm, harmonious color palette:

- **Orange (#ff7043)** - Primary actions
- **Amber (#ffab40)** - Secondary accents
- **Yellow (#ffd54f)** - Highlights
- **Lime Green (#cddc39)** - Success/Results
- **White (#ffffff)** - Text and backgrounds

---

## 📦 Technology Stack

- **Backend:** Spring Boot 3.2.0, Java 17+
- **Frontend:** HTML, CSS, Vanilla JavaScript
- **Database:** H2 (file-based, persistent)
- **Security:** Spring Security with BCrypt
- **ORM:** Spring Data JPA / Hibernate
- **Build Tool:** Maven

---

## 🔍 Key Features

✅ User Registration & Login  
✅ Secure password hashing (BCrypt)  
✅ Session-based authentication  
✅ Real-time currency conversion  
✅ Conversion history tracking  
✅ H2 database console access  
✅ REST API for database queries  
✅ Responsive UI with warm color theme  
✅ Persistent data storage  

---

**Created:** 2025-12-21  
**Version:** 1.0.0
