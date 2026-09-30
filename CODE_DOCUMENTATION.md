# Currency Converter Application - Complete Code Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Backend Code Explanation](#backend-code-explanation)
3. [Frontend Code Explanation](#frontend-code-explanation)
4. [Configuration Files](#configuration-files)
5. [How Everything Works Together](#how-everything-works-together)

---

## Project Overview

### Technology Stack
- **Backend:** Spring Boot 3.2.0 (Java 17)
- **Frontend:** HTML, Tailwind CSS, Vanilla JavaScript
- **Database:** H2 (In-Memory)
- **Security:** Spring Security with Session-based Authentication
- **Build Tool:** Maven

### Application Features
1. User Registration and Login
2. Session-based Authentication
3. Currency Conversion (INR, USD, EUR)
4. Conversion History Tracking
5. User Profile Management

---

## Backend Code Explanation

### 1. Main Application Class

**File:** `CurrencyConverterApplication.java`

```java
package com.currencyconverter;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CurrencyConverterApplication {
    public static void main(String[] args) {
        SpringApplication.run(CurrencyConverterApplication.class, args);
    }
}
```

**Explanation:**
- `@SpringBootApplication`: This annotation combines three important annotations:
  - `@Configuration`: Indicates this is a configuration class
  - `@EnableAutoConfiguration`: Enables Spring Boot's auto-configuration
  - `@ComponentScan`: Scans for components in the package and sub-packages
- `SpringApplication.run()`: Launches the Spring Boot application
- This is the entry point of the application

---

### 2. Model Classes (Entities)

#### 2.1 User Entity

**File:** `model/User.java`

```java
package com.currencyconverter.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "users")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false)
    private String username;

    @com.fasterxml.jackson.annotation.JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    @Column(nullable = false)
    private String password;

    @Column(unique = true, nullable = false)
    private String email;
}
```

**Explanation:**
- `@Entity`: Marks this class as a JPA entity (database table)
- `@Table(name = "users")`: Specifies the table name in the database
- `@Data`: Lombok annotation that generates getters, setters, toString, equals, and hashCode
- `@NoArgsConstructor` / `@AllArgsConstructor`: Lombok annotations for constructors
- `@Id`: Marks the primary key
- `@GeneratedValue(strategy = GenerationType.IDENTITY)`: Auto-generates the ID
- `@Column(unique = true)`: Ensures username and email are unique
- `@JsonProperty(access = WRITE_ONLY)`: Password is write-only (not returned in JSON responses)

---

#### 2.2 ConversionHistory Entity

**File:** `model/ConversionHistory.java`

```java
package com.currencyconverter.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "conversion_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ConversionHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @com.fasterxml.jackson.annotation.JsonIgnore
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false)
    private String fromCurrency;

    @Column(nullable = false)
    private String toCurrency;

    @Column(nullable = false)
    private BigDecimal amount;

    @Column(nullable = false)
    private BigDecimal result;

    @CreationTimestamp
    private LocalDateTime timestamp;
}
```

**Explanation:**
- `@ManyToOne`: Many conversion records can belong to one user
- `@JoinColumn(name = "user_id")`: Foreign key column name
- `@JsonIgnore`: User object is not serialized to JSON (prevents circular references)
- `@CreationTimestamp`: Automatically sets timestamp when record is created
- `BigDecimal`: Used for precise decimal calculations (important for currency)
- `FetchType.LAZY`: User data is loaded only when explicitly accessed

---

### 3. Repository Layer

#### 3.1 UserRepository

**File:** `repository/UserRepository.java`

```java
package com.currencyconverter.repository;

import com.currencyconverter.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);
    boolean existsByUsername(String username);
}
```

**Explanation:**
- `JpaRepository<User, Long>`: Provides CRUD operations for User entity
  - `User`: Entity type
  - `Long`: Primary key type
- `findByUsername()`: Spring Data JPA automatically implements this query method
- `existsByUsername()`: Checks if username already exists
- `Optional<User>`: Prevents null pointer exceptions

---

#### 3.2 ConversionHistoryRepository

**File:** `repository/ConversionHistoryRepository.java`

```java
package com.currencyconverter.repository;

import com.currencyconverter.model.ConversionHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ConversionHistoryRepository extends JpaRepository<ConversionHistory, Long> {
    List<ConversionHistory> findByUserOrderByTimestampDesc(com.currencyconverter.model.User user);
}
```

**Explanation:**
- `findByUserOrderByTimestampDesc()`: Finds all conversions for a user, ordered by timestamp (newest first)
- Spring Data JPA method naming convention:
  - `findBy`: Query type
  - `User`: Field to filter by
  - `OrderBy`: Sort results
  - `TimestampDesc`: Sort by timestamp in descending order

---

### 4. Service Layer

#### 4.1 UserService

**File:** `service/UserService.java`

```java
package com.currencyconverter.service;

import com.currencyconverter.model.User;
import com.currencyconverter.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import java.util.ArrayList;

@Service
public class UserService implements UserDetailsService {
    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public User registerUser(User user) {
        if (userRepository.existsByUsername(user.getUsername())) {
            throw new RuntimeException("Username already exists");
        }
        user.setPassword(passwordEncoder.encode(user.getPassword()));
        return userRepository.save(user);
    }

    public User findByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + username));
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = findByUsername(username);
        return new org.springframework.security.core.userdetails.User(
            user.getUsername(), 
            user.getPassword(),
            new ArrayList<>()
        );
    }
}
```

**Explanation:**
- `UserDetailsService`: Spring Security interface for user authentication
- `registerUser()`:
  - Checks if username already exists
  - Encrypts password using BCrypt
  - Saves user to database
- `passwordEncoder.encode()`: Hashes password for security (BCrypt algorithm)
- `loadUserByUsername()`: Required by Spring Security for authentication
  - Returns `UserDetails` object with username, encrypted password, and authorities

---

#### 4.2 ConversionService

**File:** `service/ConversionService.java`

```java
package com.currencyconverter.service;

import com.currencyconverter.model.ConversionHistory;
import com.currencyconverter.model.User;
import com.currencyconverter.repository.ConversionHistoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class ConversionService {
    @Autowired
    private ConversionHistoryRepository historyRepository;

    private static final Map<String, BigDecimal> EXCHANGE_RATES = new HashMap<>();

    static {
        // Base currency: INR
        EXCHANGE_RATES.put("USD", new BigDecimal("0.012")); // 1 INR = 0.012 USD
        EXCHANGE_RATES.put("EUR", new BigDecimal("0.011")); // 1 INR = 0.011 EUR
        EXCHANGE_RATES.put("INR", BigDecimal.ONE);
    }

    public BigDecimal convert(String from, String to, BigDecimal amount) {
        if (!EXCHANGE_RATES.containsKey(from)) {
            throw new IllegalArgumentException("Unsupported currency: " + from);
        }
        if (!EXCHANGE_RATES.containsKey(to)) {
            throw new IllegalArgumentException("Unsupported currency: " + to);
        }

        BigDecimal fromRate = EXCHANGE_RATES.get(from);
        BigDecimal toRate = EXCHANGE_RATES.get(to);

        // Algorithm:
        // 1. Convert 'from' currency to base currency (INR)
        // AmountInInr = Amount / FromRate
        // 2. Convert base currency to 'to' currency
        // Result = AmountInINR * ToRate

        BigDecimal amountInInr = amount.divide(fromRate, 10, RoundingMode.HALF_UP);
        BigDecimal result = amountInInr.multiply(toRate);

        return result.setScale(2, RoundingMode.HALF_UP);
    }

    public ConversionHistory performConversion(User user, String from, String to, BigDecimal amount) {
        BigDecimal result = convert(from, to, amount);

        ConversionHistory history = new ConversionHistory();
        history.setUser(user);
        history.setFromCurrency(from);
        history.setToCurrency(to);
        history.setAmount(amount);
        history.setResult(result);

        return historyRepository.save(history);
    }

    public List<ConversionHistory> getUserHistory(User user) {
        return historyRepository.findByUserOrderByTimestampDesc(user);
    }
}
```

**Explanation:**
- **Exchange Rates:**
  - Static map storing conversion rates (based on INR)
  - Can be replaced with external API in future
- **Conversion Algorithm:**
  1. Convert source currency to base currency (INR)
  2. Convert base currency to target currency
  - Example: USD to EUR = (USD → INR) → (INR → EUR)
- `BigDecimal.divide()`: Used for precise division
- `RoundingMode.HALF_UP`: Standard rounding (0.5 rounds up)
- `setScale(2)`: Rounds result to 2 decimal places
- `performConversion()`: Converts currency and saves to history

---

### 5. Controller Layer

#### 5.1 AuthController

**File:** `controller/AuthController.java`

```java
package com.currencyconverter.controller;

import com.currencyconverter.model.User;
import com.currencyconverter.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired
    private UserService userService;

    @Autowired
    private AuthenticationManager authenticationManager;

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody User user) {
        try {
            User registeredUser = userService.registerUser(user);
            return ResponseEntity.ok(
                Map.of("message", "User registered successfully", "userId", registeredUser.getId())
            );
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> loginUser(@RequestBody Map<String, String> loginRequest,
            jakarta.servlet.http.HttpServletRequest request,
            jakarta.servlet.http.HttpServletResponse response) {
        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.get("username"),
                            loginRequest.get("password")));

            SecurityContextHolder.getContext().setAuthentication(authentication);

            // Manually save the security context to the session
            org.springframework.security.web.context.HttpSessionSecurityContextRepository repo = 
                new org.springframework.security.web.context.HttpSessionSecurityContextRepository();
            repo.saveContext(SecurityContextHolder.getContext(), request, response);

            return ResponseEntity.ok(
                Map.of("message", "Login successful", "username", loginRequest.get("username"))
            );
        } catch (Exception e) {
            return ResponseEntity.status(401).body(Map.of("error", "Invalid credentials"));
        }
    }
}
```

**Explanation:**
- `@RestController`: Combines `@Controller` and `@ResponseBody`
- `@RequestMapping("/api/auth")`: Base URL for all endpoints in this controller
- **Registration Endpoint:**
  - `@PostMapping("/register")`: POST request to `/api/auth/register`
  - `@RequestBody User user`: Automatically converts JSON to User object
  - Returns success message with user ID
- **Login Endpoint:**
  - `authenticationManager.authenticate()`: Verifies username and password
  - `UsernamePasswordAuthenticationToken`: Contains credentials
  - `SecurityContextHolder.getContext().setAuthentication()`: Sets the authenticated user
  - `HttpSessionSecurityContextRepository`: Saves authentication to HTTP session
  - **This is crucial:** Without saving to session, user gets logged out on next request
  - Returns 401 status code for invalid credentials

---

#### 5.2 UserController

**File:** `controller/UserController.java`

```java
package com.currencyconverter.controller;

import com.currencyconverter.model.User;
import com.currencyconverter.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
public class UserController {
    @Autowired
    private UserService userService;

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        User user = userService.findByUsername(username);
        return ResponseEntity.ok(Map.of(
                "username", user.getUsername(),
                "email", user.getEmail()));
    }
}
```

**Explanation:**
- `SecurityContextHolder.getContext().getAuthentication().getName()`: Gets the logged-in username
- Returns user profile without password (security)
- This endpoint requires authentication (configured in SecurityConfig)

---

#### 5.3 ConversionController

**File:** `controller/ConversionController.java`

```java
package com.currencyconverter.controller;

import com.currencyconverter.model.ConversionHistory;
import com.currencyconverter.model.User;
import com.currencyconverter.service.ConversionService;
import com.currencyconverter.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/convert")
public class ConversionController {
    @Autowired
    private ConversionService conversionService;

    @Autowired
    private UserService userService;

    private User getCurrentUser() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return userService.findByUsername(username);
    }

    @PostMapping
    public ResponseEntity<?> convertCurrency(@RequestBody Map<String, Object> request) {
        try {
            String from = (String) request.get("from");
            String to = (String) request.get("to");
            BigDecimal amount = new BigDecimal(request.get("amount").toString());

            User user = getCurrentUser();
            ConversionHistory history = conversionService.performConversion(user, from, to, amount);

            return ResponseEntity.ok(history);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/history")
    public ResponseEntity<List<ConversionHistory>> getHistory() {
        return ResponseEntity.ok(conversionService.getUserHistory(getCurrentUser()));
    }
}
```

**Explanation:**
- `getCurrentUser()`: Helper method to get the logged-in user
- **Convert Endpoint:**
  - Accepts JSON with `from`, `to`, and `amount`
  - Performs conversion
  - Saves to history
  - Returns complete conversion history object
- **History Endpoint:**
  - Returns all conversions for the current user
  - Sorted by timestamp (newest first)

---

#### 5.4 HomeController

**File:** `controller/HomeController.java`

```java
package com.currencyconverter.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {
    @GetMapping("/")
    public String home() {
        return "redirect:/index.html";
    }
}
```

**Explanation:**
- `@Controller`: (Not `@RestController`) allows returning view names
- Redirects root URL to index.html (login page)

---

### 6. Configuration Classes

#### 6.1 SecurityConfig

**File:** `config/SecurityConfig.java`

```java
package com.currencyconverter.config;

import com.currencyconverter.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Autowired
    private UserService userService;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable) // Disable CSRF for Fetch API
            .securityContext(context -> context
                .securityContextRepository(
                    new org.springframework.security.web.context.HttpSessionSecurityContextRepository()
                ))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/", "/index.html", "/dashboard.html", "/api/auth/**",
                        "/css/**", "/js/**", "/images/**", "/static/**", 
                        "/favicon.ico", "/h2-console/**")
                .permitAll()
                .anyRequest().authenticated())
            .formLogin(AbstractHttpConfigurer::disable)
            .httpBasic(AbstractHttpConfigurer::disable)
            .sessionManagement(session -> session
                .sessionCreationPolicy(
                    org.springframework.security.config.http.SessionCreationPolicy.ALWAYS))
            .logout(logout -> logout
                .logoutUrl("/api/auth/logout")
                .logoutSuccessHandler((request, response, authentication) -> {
                    response.setStatus(200);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"message\":\"Logout successful\"}");
                })
                .invalidateHttpSession(true)
                .deleteCookies("JSESSIONID")
                .permitAll());

        return http.build();
    }

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider();
        provider.setUserDetailsService(userService);
        provider.setPasswordEncoder(passwordEncoder);
        return provider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) 
            throws Exception {
        return config.getAuthenticationManager();
    }
}
```

**Explanation:**

**Security Configuration Breakdown:**

1. **CSRF Disabled:**
   - `csrf(AbstractHttpConfigurer::disable)`
   - Disabled because we're using fetch API with JSON (not form submissions)
   - In production, use CSRF tokens

2. **Security Context Repository:**
   - `HttpSessionSecurityContextRepository`: Stores authentication in HTTP session
   - **Critical:** Without this, users are logged out after each request

3. **Authorization Rules:**
   - `.permitAll()`: Public access to login, register, static files
   - `.anyRequest().authenticated()`: All other requests require authentication

4. **Form Login & HTTP Basic Disabled:**
   - We use custom API endpoints instead

5. **Session Management:**
   - `SessionCreationPolicy.ALWAYS`: Always create a session
   - Ensures session is available for authentication

6. **Logout Handler:**
   - Custom handler returns JSON response
   - Invalidates session and deletes cookies

7. **Authentication Provider:**
   - Uses `UserDetailsService` (UserService) to load user
   - Uses `PasswordEncoder` to verify passwords

---

#### 6.2 AppConfig

**File:** `config/AppConfig.java`

```java
package com.currencyconverter.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
public class AppConfig {
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

**Explanation:**
- `@Bean`: Creates a Spring-managed bean
- `BCryptPasswordEncoder`: Industry-standard password hashing algorithm
  - One-way encryption
  - Adds salt automatically
  - Generates different hashes for same password (secure)

---

## Frontend Code Explanation

### 1. Login/Register Page (index.html)

**File:** `src/main/resources/static/index.html`

**Key Sections:**

#### HTML Structure:
```html
<!-- Tabs for Login/Register -->
<div class="flex mb-6 bg-gray-700 rounded-lg p-1">
    <button id="tab-login" onclick="showForm('login')">Login</button>
    <button id="tab-register" onclick="showForm('register')">Register</button>
</div>

<!-- Login Form -->
<form id="login-form" onsubmit="handleLogin(event)">
    <input type="text" id="login-username" required>
    <input type="password" id="login-password" required>
    <button type="submit">Login</button>
</form>

<!-- Register Form -->
<form id="register-form" class="hidden" onsubmit="handleRegister(event)">
    <input type="text" id="reg-username" required>
    <input type="email" id="reg-email" required>
    <input type="password" id="reg-password" required>
    <button type="submit">Register</button>
</form>
```

#### JavaScript Functions:

**1. Tab Switching:**
```javascript
function showForm(form) {
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    
    if (form === 'login') {
        loginForm.classList.remove('hidden');
        registerForm.classList.add('hidden');
    } else {
        loginForm.classList.add('hidden');
        registerForm.classList.remove('hidden');
    }
}
```
**Explanation:**
- Shows/hides forms based on selected tab
- Uses CSS class manipulation

**2. Login Handler:**
```javascript
async function handleLogin(e) {
    e.preventDefault();
    const username = document.getElementById('login-username').value;
    const password = document.getElementById('login-password').value;

    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password }),
            credentials: 'include'  // IMPORTANT: Sends cookies
        });

        if (response.ok) {
            window.location.href = 'dashboard.html';
        } else {
            const data = await response.json();
            displayError(data.error || 'Login failed');
        }
    } catch (err) {
        displayError('An error occurred');
    }
}
```
**Explanation:**
- `e.preventDefault()`: Prevents default form submission
- `fetch()`: Makes HTTP request to backend
- `credentials: 'include'`: **Critical** - Sends/receives session cookies
- `response.ok`: Checks if status is 200-299
- Redirects to dashboard on success

**3. Register Handler:**
```javascript
async function handleRegister(e) {
    e.preventDefault();
    const username = document.getElementById('reg-username').value;
    const email = document.getElementById('reg-email').value;
    const password = document.getElementById('reg-password').value;

    try {
        const response = await fetch('/api/auth/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password }),
            credentials: 'include'
        });

        if (response.ok) {
            displaySuccess('Registration successful! Please login.');
            setTimeout(() => showForm('login'), 1500);
        } else {
            const data = await response.json();
            displayError(data.error || 'Registration failed');
        }
    } catch (err) {
        displayError('An error occurred');
    }
}
```
**Explanation:**
- Similar to login handler
- Shows success message
- Auto-switches to login tab after 1.5 seconds

---

### 2. Dashboard Page (dashboard.html)

**File:** `src/main/resources/static/dashboard.html`

**Key Sections:**

#### HTML Structure:
```html
<!-- Navbar -->
<nav>
    <span class="text-xl font-bold">CurrencyPro</span>
    <div>
        <span id="username-display">Loading...</span>
        <button onclick="logout()">Logout</button>
    </div>
</nav>

<!-- Converter Form -->
<form id="convert-form" onsubmit="handleConversion(event)">
    <input type="number" id="amount" step="0.01" required>
    <select id="from-currency">
        <option value="INR">INR (Indian Rupee)</option>
        <option value="USD">USD (US Dollar)</option>
        <option value="EUR">EUR (Euro)</option>
    </select>
    <select id="to-currency">
        <option value="USD">USD (US Dollar)</option>
        <option value="INR">INR (Indian Rupee)</option>
        <option value="EUR">EUR (Euro)</option>
    </select>
    <span id="result-display">--</span>
    <button type="submit">Convert Currency</button>
</form>

<!-- History Table -->
<table>
    <thead>
        <tr>
            <th>Date</th>
            <th>Conversion</th>
            <th>Result</th>
        </tr>
    </thead>
    <tbody id="history-body">
        <tr><td colspan="3">Loading history...</td></tr>
    </tbody>
</table>
```

#### JavaScript Functions:

**1. Page Load:**
```javascript
document.addEventListener('DOMContentLoaded', async () => {
    await loadProfile();
    await loadHistory();
});
```
**Explanation:**
- Runs when page loads
- Loads user profile and conversion history
- If user is not authenticated, redirects to login

**2. Load Profile:**
```javascript
async function loadProfile() {
    try {
        const response = await fetch('/api/user/profile', {
            credentials: 'include'
        });
        
        if (response.ok) {
            const user = await response.json();
            document.getElementById('username-display').textContent = user.username;
            document.getElementById('user-avatar').textContent = 
                user.username.charAt(0).toUpperCase();
        } else {
            window.location.href = 'index.html'; // Not logged in
        }
    } catch (e) {
        console.error(e);
    }
}
```
**Explanation:**
- Fetches current user profile
- If not authenticated (401), redirects to login
- Displays username in navbar

**3. Currency Conversion:**
```javascript
async function handleConversion(e) {
    e.preventDefault();
    const amount = document.getElementById('amount').value;
    const from = document.getElementById('from-currency').value;
    const to = document.getElementById('to-currency').value;

    try {
        const response = await fetch('/api/convert', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ amount, from, to }),
            credentials: 'include'
        });

        if (response.ok) {
            const data = await response.json();
            document.getElementById('result-display').textContent = 
                `${data.result} ${data.toCurrency}`;
            loadHistory(); // Refresh history table
        } else {
            alert('Conversion failed');
        }
    } catch (e) {
        console.error(e);
    }
}
```
**Explanation:**
- Sends conversion request to backend
- Displays result
- Refreshes history to show new conversion

**4. Load History:**
```javascript
async function loadHistory() {
    try {
        const response = await fetch('/api/convert/history', {
            credentials: 'include'
        });
        
        const tbody = document.getElementById('history-body');
        
        if (response.ok) {
            const history = await response.json();
            
            if (history.length === 0) {
                tbody.innerHTML = '<tr><td colspan="3">No conversions yet</td></tr>';
                return;
            }

            tbody.innerHTML = history.map(item => `
                <tr>
                    <td>${new Date(item.timestamp).toLocaleDateString()} 
                        ${new Date(item.timestamp).toLocaleTimeString()}</td>
                    <td>
                        <span>${item.amount} ${item.fromCurrency}</span>
                        <span> → </span>
                        <span>${item.toCurrency}</span>
                    </td>
                    <td>${item.result}</td>
                </tr>
            `).join('');
        }
    } catch (e) {
        console.error(e);
    }
}
```
**Explanation:**
- Fetches conversion history from backend
- Dynamically generates table rows
- Formats timestamps using JavaScript Date methods
- Uses array `map()` to transform data to HTML

**5. Logout:**
```javascript
async function logout() {
    await fetch('/api/auth/logout', { 
        method: 'POST', 
        credentials: 'include' 
    });
    window.location.href = 'index.html';
}
```
**Explanation:**
- Sends logout request
- Redirects to login page
- Backend invalidates session

---

## Configuration Files

### 1. pom.xml (Maven Configuration)

**Key Dependencies:**

```xml
<!-- Spring Boot Starter Web: REST API support -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>

<!-- Spring Boot Starter Data JPA: Database access -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-jpa</artifactId>
</dependency>

<!-- Spring Boot Starter Security: Authentication & Authorization -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- H2 Database: In-memory database -->
<dependency>
    <groupId>com.h2database</groupId>
    <artifactId>h2</artifactId>
    <scope>runtime</scope>
</dependency>

<!-- Lombok: Reduces boilerplate code -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>
```

**Explanation:**
- **starter-web**: Includes Tomcat, Spring MVC, Jackson for JSON
- **starter-data-jpa**: Hibernate ORM, Spring Data JPA
- **starter-security**: Spring Security framework
- **h2**: Lightweight in-memory database (development)
- **lombok**: Auto-generates getters, setters, constructors

---

### 2. application.properties

**File:** `src/main/resources/application.properties`

```properties
# Application Name
spring.application.name=currency-converter

# H2 Database Configuration
spring.datasource.url=jdbc:h2:mem:currency_converter_db;DB_CLOSE_DELAY=-1
spring.datasource.driver-class-name=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=
spring.h2.console.enabled=true

# JPA / Hibernate
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.H2Dialect

# Server Configuration
server.port=8080
```

**Explanation:**

**Database Configuration:**
- `jdbc:h2:mem:`: In-memory database (data lost on restart)
- `DB_CLOSE_DELAY=-1`: Keeps database alive while app is running
- `username=sa`, `password=`: Default H2 credentials
- `h2.console.enabled=true`: Enables H2 web console at `/h2-console`

**JPA Configuration:**
- `ddl-auto=update`: Auto-creates/updates database tables
- `show-sql=true`: Logs SQL queries to console (development)
- `hibernate.dialect`: Specifies SQL variant for H2

**Server Configuration:**
- `server.port=8080`: Application runs on port 8080

---

## How Everything Works Together

### 1. Application Startup Flow

```
1. Spring Boot starts (CurrencyConverterApplication.main())
2. Component scanning finds all @Component, @Service, @Repository, @Controller
3. Bean creation and dependency injection
4. Database initialization (Hibernate creates tables)
5. Security filters configured
6. Tomcat server starts on port 8080
7. Application ready to accept requests
```

---

### 2. User Registration Flow

```
Frontend (index.html)
    ↓ POST /api/auth/register
    ↓ JSON: { username, email, password }
AuthController.registerUser()
    ↓ calls
UserService.registerUser()
    ↓ checks if username exists
    ↓ encrypts password (BCrypt)
    ↓ saves to database
UserRepository.save()
    ↓ JPA/Hibernate inserts into users table
Database
    ↓ returns saved User
Response
    ↓ JSON: { message, userId }
Frontend displays success message
```

---

### 3. User Login Flow

```
Frontend (index.html)
    ↓ POST /api/auth/login
    ↓ JSON: { username, password }
    ↓ credentials: 'include'
AuthController.loginUser()
    ↓ calls
AuthenticationManager.authenticate()
    ↓ calls
UserService.loadUserByUsername()
    ↓ fetches user from database
    ↓ compares passwords (BCrypt)
    ✓ if valid:
SecurityContextHolder.getContext().setAuthentication()
    ↓ saves authentication
HttpSessionSecurityContextRepository.saveContext()
    ↓ stores in HTTP session
Response
    ↓ Sets JSESSIONID cookie
    ↓ JSON: { message, username }
Frontend
    ↓ receives cookie
    ↓ redirects to dashboard.html
```

---

### 4. Currency Conversion Flow

```
Frontend (dashboard.html)
    ↓ POST /api/convert
    ↓ JSON: { amount, from, to }
    ↓ credentials: 'include' (sends session cookie)
Spring Security Filter
    ↓ validates JSESSIONID
    ↓ loads authentication from session
    ✓ user is authenticated
ConversionController.convertCurrency()
    ↓ gets current user from SecurityContext
    ↓ calls
ConversionService.performConversion()
    ↓ calls convert() algorithm:
    ↓   1. Convert to base currency (INR)
    ↓   2. Convert to target currency
    ↓ creates ConversionHistory object
    ↓ saves to database
ConversionHistoryRepository.save()
    ↓ inserts into conversion_history table
Database
    ↓ returns saved ConversionHistory
Response
    ↓ JSON: { id, fromCurrency, toCurrency, amount, result, timestamp }
Frontend
    ↓ displays result
    ↓ reloads history table
```

---

### 5. Session Management

**Why Session Persistence is Important:**

```
Without HttpSessionSecurityContextRepository:
    Login → Authentication set in SecurityContext
    Next request → SecurityContext is empty (authentication lost)
    Result: User redirected to login page

With HttpSessionSecurityContextRepository:
    Login → Authentication set in SecurityContext
    →  Saved to HTTP Session
    Next request → Authentication loaded from session
    → SecurityContext populated
    Result: User stays logged in
```

**Key Points:**
1. `credentials: 'include'` in fetch: Sends cookies with every request
2. `JSESSIONID` cookie: Identifies the user's session
3. `HttpSessionSecurityContextRepository`: Links authentication to session
4. Spring Security filters: Automatically load authentication from session

---

### 6. Security Flow

```
Request to /api/convert
    ↓
Spring Security Filter Chain:
    ↓
1. DisableEncodeUrlFilter
2. ForceEagerSessionCreationFilter (creates session if needed)
3. SecurityContextHolderFilter (loads authentication from session)
4. HeaderWriterFilter
5. CorsFilter
6. LogoutFilter (checks if logout request)
7. AuthorizationFilter (checks if user is authenticated)
    ↓
    If NOT authenticated → 401 Unauthorized
    If authenticated → Continue to controller
    ↓
ConversionController.convertCurrency()
```

---

## Summary

### Architecture Overview

```
Frontend (HTML/CSS/JS)
    ↕ REST API (JSON)
Controllers (@RestController)
    ↕
Services (@Service)
    ↕
Repositories (@Repository)
    ↕
Database (H2)
```

### Key Technologies

1. **Spring Boot**: Framework that simplifies Java development
2. **Spring Data JPA**: Simplifies database operations
3. **Spring Security**: Handles authentication and authorization
4. **H2 Database**: In-memory database for development
5. **Lombok**: Reduces boilerplate code
6. **Tailwind CSS**: Utility-first CSS framework
7. **Fetch API**: Modern way to make HTTP requests from JavaScript

### Design Patterns Used

1. **MVC (Model-View-Controller)**
   - Model: User, ConversionHistory
   - View: HTML files
   - Controller: AuthController, UserController, ConversionController

2. **Dependency Injection**
   - `@Autowired` injects dependencies
   - Spring manages object lifecycle

3. **Repository Pattern**
   - Abstracts database operations
   - UserRepository, ConversionHistoryRepository

4. **Service Layer Pattern**
   - Business logic separated from controllers
   - UserService, ConversionService

5. **DTO (Data Transfer Object)**
   - Using Map<String, Object> for JSON communication
   - Could be improved with dedicated DTO classes

---

## Running the Application

```bash
# Navigate to project directory
cd "c:\Users\chinm\OneDrive\Desktop\Java Currency_converter"

# Run the application
mvn spring-boot:run

# Access the application
http://localhost:8080
```

---

## Future Enhancements

1. **Use External Currency API**
   - Replace static exchange rates with real-time data
   - Example: ExchangeRate-API, Fixer.io

2. **Add More Currencies**
   - Support for more international currencies

3. **Password Validation**
   - Enforce strong password rules
   - Minimum length, special characters, etc.

4. **Email Verification**
   - Send verification email on registration

5. **Remember Me**
   - Persistent login across browser sessions

6. **Export History**
   - Download conversion history as CSV/PDF

7. **User Roles**
   - Admin vs regular users
   - Different access levels

8. **Rate Limiting**
   - Prevent abuse of conversion API

9. **Frontend Framework**
   - Migrate to React, Vue, or Angular
   - Better state management

10. **Production Database**
    - Use PostgreSQL or MySQL instead of H2

---

## Troubleshooting

### Common Issues

**1. Port 8080 already in use:**
```bash
netstat -ano | findstr :8080
taskkill /F /PID <PID>
```

**2. Login redirects back to login page:**
- Check `credentials: 'include'` in fetch calls
- Verify `HttpSessionSecurityContextRepository` in SecurityConfig

**3. Password not matching:**
- Ensure `BCryptPasswordEncoder` is used
- Check if password is being encrypted during registration

**4. Database connection error:**
- Verify H2 dependency in pom.xml
- Check application.properties configuration

---

**End of Documentation**

*Created: December 20, 2025*
*Project: Currency Converter Application*
*Technologies: Spring Boot 3.2.0, Java 17, H2, Spring Security*
