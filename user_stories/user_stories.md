# Oxford Medical Platform - User Stories

This document contains comprehensive user stories for all roles in the Oxford Medical Platform system. Each story is written as an end-to-end testing scenario, following the real user flows from the mobile app (Flutter) and admin dashboard (Flutter Web).

---

## Table of Contents

1. [Doctor (Customer) User Stories](#1-doctor-customer-user-stories)
2. [Admin User Stories](#2-admin-user-stories)

---

## 1. Doctor (Customer) User Stories

### 1.1 Doctor Registration with License Upload

**Story ID:** DOC-REG-001  
**Priority:** High  
**As a** new doctor registering on the platform  
**I want to** create an account with my medical license  
**So that** I can access the platform's medical product catalog

#### Flow:

```
1. Launch the Oxford Medical app
2. Tap "Register" button on the landing screen
3. Enter email address (e.g., "dr.smith@clinic.com")
4. Enter password (e.g., "SecurePass123!")
5. Confirm password by re-entering "SecurePass123!"
6. Enter full name (e.g., "Dr. John Smith")
7. Enter phone number (e.g., "+201234567890")
8. Enter clinic name (e.g., "Smith Family Clinic")
9. Tap "Upload License" button
10. Select "Camera" option from the image picker
11. Take a photo of the medical license
12. Confirm the captured image
13. Review the uploaded license thumbnail
14. Read and accept the Terms & Conditions checkbox
15. Tap "Create Account" button
16. Wait for OTP verification screen
17. Enter the 6-digit OTP sent to email
18. Tap "Verify" button
19. Verify successful registration toast message appears
20. Navigate to home screen automatically
21. Confirm my profile shows "Dr. John Smith" with "Pending Verification" badge
```

**Acceptance Criteria:**
- [ ] All form fields validate correctly (email format, password strength, phone format)
- [ ] License image uploads successfully and displays thumbnail
- [ ] OTP is sent to registered email
- [ ] Account is created with "Pending Verification" status
- [ ] User is redirected to home screen after verification

---

### 1.2 Doctor Login with JWT Tokens

**Story ID:** DOC-LOGIN-001  
**Priority:** High  
**As a** registered doctor  
**I want to** log in to the platform  
**So that** I can access my account and make purchases

#### Flow:

```
1. Launch the Oxford Medical app
2. Ensure I am on the login screen (not registered)
3. Enter email address (e.g., "dr.smith@clinic.com")
4. Enter password (e.g., "SecurePass123!")
5. Tap "Login" button
6. Wait for loading indicator
7. Verify successful login - home screen appears
8. Check that access token is stored in secure storage
9. Check that refresh token is stored in secure storage
10. Verify bottom navigation bar shows: Home, Categories, Cart, Profile
11. Tap Profile tab
12. Verify my name "Dr. John Smith" is displayed
13. Verify my email is displayed
14. Check logout option is available
```

**Acceptance Criteria:**
- [ ] Valid credentials result in successful login
- [ ] Access token is stored securely (FlutterSecureStorage)
- [ ] Refresh token is stored securely
- [ ] User is navigated to home screen
- [ ] Bottom navigation is visible with all tabs
- [ ] Profile displays user information correctly

---

### 1.3 Password Reset via OTP

**Story ID:** DOC-PWRESET-001  
**Priority:** High  
**As a** doctor who forgot my password  
**I want to** reset my password using OTP  
**So that** I can regain access to my account

#### Flow:

```
1. Launch the Oxford Medical app
2. Tap "Forgot Password?" link on login screen
3. Enter registered email (e.g., "dr.smith@clinic.com")
4. Tap "Send OTP" button
5. Wait for success message "OTP sent to your email"
6. Check email inbox for OTP (6-digit code)
7. Enter the OTP in the verification field
8. Tap "Verify OTP" button
9. Enter new password (e.g., "NewSecure456!")
10. Confirm new password by re-entering "NewSecure456!"
11. Tap "Reset Password" button
12. Verify success message "Password reset successfully"
13. Navigate back to login screen automatically
14. Log in with new password to confirm reset works
```

**Acceptance Criteria:**
- [ ] OTP is sent to registered email
- [ ] OTP verification accepts valid code
- [ ] Password is successfully updated in database
- [ ] User can log in with new password
- [ ] Old password no longer works

---

### 1.4 Browse Products by Category

**Story ID:** DOC-CAT-001  
**Priority:** High  
**As a** doctor looking for medical supplies  
**I want to** browse products by category  
**So that** I can find what I need quickly

#### Flow:

```
1. Log in as a registered doctor
2. On home screen, scroll horizontally through category chips
3. Tap "Surgical Instruments" category chip
4. Wait for products to load in grid view
5. Verify products belong to "Surgical Instruments"
6. Tap "Categories" tab in bottom navigation
7. View all categories in list format
8. Tap "Medications" category
9. View subcategories (Pain Relief, Antibiotics, etc.)
10. Tap "Pain Relief" subcategory
11. Verify product list shows pain relief medications
12. Check that category name appears in header
13. Scroll down to load more products
14. Verify pagination works (20 items per page)
```

**Acceptance Criteria:**
- [ ] Categories display on home screen horizontally
- [ ] Tapping category shows filtered products
- [ ] Category hierarchy works (parent → subcategory)
- [ ] Products load with images, names, prices
- [ ] Pagination works correctly

---

### 1.5 Search Products with Debounce

**Story ID:** DOC-SEARCH-001  
**Priority:** High  
**As a** doctor looking for a specific product  
**I want to** search for products by name  
**So that** I can find exact items quickly

#### Flow:

```
1. Log in as a registered doctor
2. Tap search icon in app bar
3. Enter search query "surgical gloves"
4. Wait 500ms (debounce) without pressing search
5. Verify search results appear automatically
6. Check results contain "surgical gloves" in name
7. Tap "X" to clear search
8. Enter new query "stethoscope"
9. Wait for debounce
10. Verify stethoscope products appear
11. Tap a product from results
12. Verify navigate to product detail page
13. Check product name matches search term
```

**Acceptance Criteria:**
- [ ] Search has 500ms debounce
- [ ] Results filter as user types
- [ ] Search is case-insensitive
- [ ] Results show matching products
- [ ] Tapping result navigates to detail page

---

### 1.6 Apply Product Filters

**Story ID:** DOC-FILTER-001  
**Priority:** High  
**As a** doctor with budget constraints  
**I want to** filter products by price and availability  
**So that** I can find affordable in-stock items

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Categories tab
3. Tap "Surgical Instruments" category
4. Tap filter icon in app bar
5. Filter sheet slides up from bottom
6. Set price range: $10 - $50
7. Toggle "In Stock Only" switch ON
8. Tap "Apply Filters" button
9. Verify all displayed products are in stock
10. Verify all prices are between $10-$50
11. Tap filter icon again
12. Tap "Clear All" button
13. Verify all filters reset
14. Verify all products (including out of stock) show
```

**Acceptance Criteria:**
- [ ] Filter sheet displays all filter options
- [ ] Price range filter works correctly
- [ ] In-stock toggle filters correctly
- [ ] Clear all resets all filters
- [ ] Filters persist during session

---

### 1.7 Add Product to Cart

**Story ID:** DOC-CART-ADD-001  
**Priority:** High  
**As a** doctor ready to purchase  
**I want to** add products to my cart  
**So that** I can checkout with multiple items

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Categories tab
3. Tap "Medications" category
4. Tap on a product card (e.g., "Panadol 500mg")
5. View product detail page
6. Check product name, price, description, stock status
7. Tap "Add to Cart" button
8. Verify cart badge shows "1"
9. Verify toast message "Added to cart"
10. Tap back button
11. Add another product
12. Check cart badge shows "2"
13. Navigate to Cart tab
14. Verify both products listed
15. Check quantities are correct
16. Check subtotal is calculated correctly
```

**Acceptance Criteria:**
- [ ] Product detail shows all information
- [ ] Add to cart updates badge count
- [ ] Success toast appears
- [ ] Cart shows all added items
- [ ] Quantities and prices calculate correctly

---

### 1.8 Update Cart Quantity

**Story ID:** DOC-CART-QTY-001  
**Priority:** High  
**As a** doctor managing my cart  
**I want to** change product quantities  
**So that** I can adjust order amounts

#### Flow:

```
1. Log in as a registered doctor
2. Add product to cart (quantity: 1)
3. Navigate to Cart tab
4. Tap "+" button on product
5. Verify quantity changes to 2
6. Verify total price updates
7. Tap "-" button
8. Verify quantity changes back to 1
9. Tap on quantity input field
10. Enter new quantity "5"
11. Tap outside to confirm
12. Verify quantity updates to 5
13. Verify total price reflects quantity change
14. Try entering quantity "0"
15. Verify product is removed from cart
```

**Acceptance Criteria:**
- [ ] Plus button increments quantity
- [ ] Minus button decrements quantity
- [ ] Manual input accepts valid numbers
- [ ] Zero quantity removes item
- [ ] Total price updates in real-time

---

### 1.9 Remove Product from Cart

**Story ID:** DOC-CART-REM-001  
**Priority:** Medium  
**As a** doctor changing my mind  
**I want to** remove items from cart  
**So that** I can finalize my order

#### Flow:

```
1. Log in as a registered doctor
2. Add 3 different products to cart
3. Navigate to Cart tab
4. Verify 3 products listed
5. Swipe left on first product
6. Tap "Delete" button
7. Verify product removed from list
8. Verify 2 products remain
9. Tap trash icon on second product
10. Verify confirmation dialog appears
11. Tap "Confirm" button
12. Verify product removed
13. Verify only 1 product remains
14. Verify cart badge updates to 1
```

**Acceptance Criteria:**
- [ ] Swipe to delete works
- [ ] Trash icon delete works
- [ ] Confirmation dialog appears for trash icon
- [ ] Cart badge updates after removal
- [ ] Product removed from database cart

---

### 1.10 Create Order with Cash on Delivery

**Story ID:** DOC-ORDER-001  
**Priority:** High  
**As a** doctor ready to purchase  
**I want to** checkout with Cash on Delivery  
**So that** I can receive products and pay in person

#### Flow:

```
1. Log in as a registered doctor
2. Add products to cart (total: $150)
3. Navigate to Cart tab
4. Tap "Checkout" button
5. Select saved address or add new address
6. Tap "Add New Address" button
7. Enter: Street "123 Medical St"
8. Enter: City "Cairo"
9. Enter: District "Maadi"
10. Enter: Building "Building A, Floor 3"
11. Enter: Phone "+201234567890"
12. Tap "Save Address" button
13. Select payment method "Cash on Delivery"
14. Review order summary
15. Apply promo code if available
16. Tap "Place Order" button
17. Verify success screen with order number
18. Note order number for tracking
19. Verify order appears in Orders tab
20. Verify order status is "Pending"
```

**Acceptance Criteria:**
- [ ] Address form validates correctly
- [ ] Payment method selection works
- [ ] Order summary shows all details
- [ ] Order is created in database
- [ ] Order appears in order history
- [ ] Status is "Pending" initially

---

### 1.11 View Order History

**Story ID:** DOC-ORDER-HIST-001  
**Priority:** High  
**As a** doctor tracking my purchases  
**I want to** view my order history  
**So that** I can see past orders and their status

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Orders tab in bottom navigation
3. View list of past orders
4. Verify orders sorted by date (newest first)
5. Check each order shows: order number, date, status, total
6. Tap on first order
7. View order detail page
8. Check timeline showing order progression
9. Verify products listed with quantities and prices
10. Verify shipping address displayed
11. Verify payment method displayed
12. Tap back button
13. Use filter to show "Delivered" orders only
14. Verify only delivered orders shown
15. Clear filter to show all
```

**Acceptance Criteria:**
- [ ] Orders display in list format
- [ ] Orders sorted by date correctly
- [ ] Order detail shows all information
- [ ] Timeline shows order status progression
- [ ] Filter by status works

---

### 1.12 Track Order in Real-Time

**Story ID:** DOC-ORDER-TRACK-001  
**Priority:** High  
**As a** doctor waiting for my order  
**I want to** track order status in real-time  
**So that** I know when to expect delivery

#### Flow:

```
1. Log in as a registered doctor
2. Place an order (status: Pending)
3. Navigate to Orders tab
4. Tap on the order
5. View order detail with status timeline
6. Wait for status to change (simulate by admin)
7. Receive in-app notification "Order Confirmed"
8. Check timeline updates to "Confirmed"
9. Wait for status change to "Processing"
10. Verify timeline updates
11. Wait for status change to "Shipped"
12. Verify timeline shows "Shipped" with timestamp
13. Wait for status change to "Delivered"
14. Verify order shows "Delivered" status
15. Receive notification "Order Delivered"
```

**Acceptance Criteria:**
- [ ] Real-time status updates via WebSocket
- [ ] Notifications appear for status changes
- [ ] Timeline updates correctly
- [ ] All status transitions tracked

---

### 1.13 Reorder from Order Detail

**Story ID:** DOC-ORDER-REORDER-001  
**Priority:** Medium  
**As a** doctor who needs to restock  
**I want to** reorder from a previous order  
**So that** I can quickly repurchase items

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Orders tab
3. Tap on a previous "Delivered" order
4. View order detail
5. Tap "Reorder" button
6. Verify navigate to cart with same items
7. Check quantities match previous order
8. Modify quantity of one item
9. Tap "Checkout" button
10. Verify address pre-filled from previous order
11. Complete checkout
12. Verify new order created
13. Verify success message shown
```

**Acceptance Criteria:**
- [ ] Reorder button visible on delivered orders
- [ ] Items added to cart with same quantities
- [ ] User can modify quantities before checkout
- [ ] New order created successfully

---

### 1.14 Add to Wishlist

**Story ID:** DOC-WISHLIST-001  
**Priority:** Medium  
**As a** doctor researching products  
**I want to** save products to wishlist  
**So that** I can purchase later

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Categories tab
3. Tap "Surgical Instruments" category
4. Tap on a product
5. View product detail page
6. Tap heart/shield icon to add to wishlist
7. Verify icon fills to indicate "saved"
8. Verify toast "Added to wishlist"
9. Navigate to Profile tab
10. Tap "Wishlist" option
11. Verify product appears in wishlist
12. Tap heart icon on product
13. Verify product removed from wishlist
14. Verify toast "Removed from wishlist"
```

**Acceptance Criteria:**
- [ ] Heart icon toggles wishlist status
- [ ] Wishlist persists in database
- [ ] Wishlist accessible from profile
- [ ] Items can be removed from wishlist

---

### 1.15 Apply Promo Code

**Story ID:** DOC-PROMO-001  
**Priority:** Medium  
**As a** doctor with a promo code  
**I want to** apply discount codes  
**So that** I can save money on orders

#### Flow:

```
1. Log in as a registered doctor
2. Add products to cart (total: $100)
3. Navigate to Cart tab
4. Tap "Have a promo code?" link
5. Enter promo code "SAVE10"
6. Tap "Apply" button
7. Verify discount applied (10% = $10)
8. Verify new total ($90)
9. Proceed to checkout
10. Verify discount reflected in order summary
11. Complete order
12. Verify order shows discount applied
```

**Acceptance Criteria:**
- [ ] Promo code input accepts valid codes
- [ ] Percentage discount calculates correctly
- [ ] Fixed discount calculates correctly
- [ ] Invalid code shows error message
- [ ] Discount persists through checkout

---

### 1.16 Submit Product Review

**Story ID:** DOC-REVIEW-001  
**Priority:** Medium  
**As a** doctor who received my order  
**I want to** rate and review products  
**So that** I can help other doctors

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Orders tab
3. Tap on delivered order
4. View order detail
5. Tap "Write Review" on first product
6. Tap 5 stars
7. Enter review text "Excellent quality, fast delivery!"
8. Tap "Submit Review" button
9. Verify success message
10. Navigate to product detail page
11. Verify review appears in reviews section
12. Verify rating shows 5 stars
```

**Acceptance Criteria:**
- [ ] Stars are tappable (1-5)
- [ ] Text review can be entered
- [ ] Review saves to database
- [ ] Review appears on product detail
- [ ] Average rating updates

---

### 1.17 Update Profile Information

**Story ID:** DOC-PROFILE-001  
**Priority:** High  
**As a** doctor with updated information  
**I want to** edit my profile  
**So that** my account reflects current details

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Profile tab
3. Tap "Edit Profile" button
4. Change name to "Dr. Jane Smith"
5. Change phone to "+201987654321"
6. Change clinic to "Smith Medical Center"
7. Change city to "Alexandria"
8. Tap "Save Changes" button
9. Verify success message "Profile updated"
10. Navigate back to Profile
11. Verify changes reflected
12. Verify changes persisted after app restart
```

**Acceptance Criteria:**
- [ ] All profile fields editable
- [ ] Validation works (phone format, required fields)
- [ ] Changes save to database
- [ ] Changes display in profile
- [ ] Changes persist across sessions

---

### 1.18 View Notifications

**Story ID:** DOC-NOTIF-001  
**Priority:** High  
**As a** doctor wanting to stay informed  
**I want to** view my notifications  
**So that** I know about order updates

#### Flow:

```
1. Log in as a registered doctor
2. Badge on bell icon shows unread count
3. Tap bell icon in app bar
4. View notifications list
5. Verify newest notifications first
6. Tap on order notification
7. Navigate to order detail
8. Go back to notifications
9. Swipe left on notification
10. Tap delete icon
11. Verify notification removed
12. Tap "Mark all as read" button
13. Verify badge clears
14. Verify all notifications marked as read
```

**Acceptance Criteria:**
- [ ] Unread badge displays correctly
- [ ] Notifications list loads
- [ ] Tapping notification navigates appropriately
- [ ] Swipe to delete works
- [ ] Mark all as read works
- [ ] Notifications persist

---

### 1.19 Toggle Language to Arabic (RTL)

**Story ID:** DOC-LOCALE-001  
**Priority:** High  
**As a** Arabic-speaking doctor  
**I want to** use the app in Arabic  
**So that** I can read in my native language

#### Flow:

```
1. Log in as a registered doctor
2. Navigate to Profile tab
3. Tap "Language" option
4. Select "العربية" (Arabic)
5. Verify app reloads
6. Verify text direction is RTL
7. Verify all UI text in Arabic
8. Verify navigation drawer opens from right
9. Verify back button on right side
10. Verify input fields aligned to right
11. Tap "English" to switch back
12. Verify LTR layout restored
```

**Acceptance Criteria:**
- [ ] Language selection persists
- [ ] RTL layout applies correctly
- [ ] All text translates to Arabic
- [ ] UI elements mirror correctly

---

### 1.20 Offline Mode - Cached Data

**Story ID:** DOC-OFFLINE-001  
**Priority:** Medium  
**As a** doctor with poor connectivity  
**I want to** view cached data offline  
**So that** I can continue browsing

#### Flow:

```
1. Log in as a registered doctor while online
2. Browse products in "Surgical Instruments"
3. View product details
4. Turn off internet connection
5. Navigate to Categories tab
6. Verify previously viewed products still display
7. Navigate to Profile tab
8. Verify profile information still shows
9. Try to add product to cart
10. Verify error message "No internet connection"
11. Turn on internet connection
12. Retry adding to cart
13. Verify success
```

**Acceptance Criteria:**
- [ ] Previously loaded data caches
- [ ] Cached data displays offline
- [ ] Network requests fail gracefully offline
- [ ] Cached data has TTL (Time to Live)

---

## 2. Admin User Stories

### 2.1 Admin Login

**Story ID:** ADMIN-LOGIN-001  
**Priority:** High  
**As an** admin managing the platform  
**I want to** log in to the admin dashboard  
**So that** I can manage the system

#### Flow:

```
1. Navigate to admin dashboard URL
2. View login page
3. Enter admin email (e.g., "admin@oxfordmedical.com")
4. Enter admin password
5. Click "Login" button
6. Verify successful login
7. Verify dashboard page loads
8. Verify sidebar shows menu items
9. Check user name displayed in header
10. Check logout option available
```

**Acceptance Criteria:**
- [ ] Valid credentials log in successfully
- [ ] Invalid credentials show error
- [ ] Dashboard loads after login
- [ ] Sidebar navigation visible
- [ ] User info displayed in header

---

### 2.2 View Dashboard Overview

**Story ID:** ADMIN-DASH-001  
**Priority:** High  
**As an** admin wanting overview  
**I want to** see key metrics  
**So that** I can monitor the platform

#### Flow:

```
1. Log in as admin
2. View dashboard page
3. Check total doctors count
4. Check total orders count
5. Check total revenue amount
6. Check pending orders count
7. View recent orders table
8. Verify orders show order ID, doctor, status, total
9. Check revenue chart displays
10. Check orders by status pie chart
11. Refresh page to update data
```

**Acceptance Criteria:**
- [ ] Dashboard shows key metrics
- [ ] Metrics update correctly
- [ ] Charts render properly
- [ ] Recent orders display

---

### 2.3 Manage Products (Create)

**Story ID:** ADMIN-PROD-CREATE-001  
**Priority:** High  
**As an** admin adding inventory  
**I want to** create new products  
**So that** they appear in the mobile app

#### Flow:

```
1. Log in as admin
2. Click "Products" in sidebar
3. Click "Add Product" button
4. Enter product name "Surgical Scalpel Premium"
5. Enter SKU "SURG-SCAL-001"
6. Enter description "High-quality surgical scalpel"
7. Enter price 25.99
8. Enter stock quantity 100
9. Select category "Surgical Instruments"
10. Select brand "MedTech"
11. Upload product images
12. Toggle "In Stock" ON
13. Toggle "Active" ON
14. Click "Save Product" button
15. Verify success message
16. Verify product appears in products list
```

**Acceptance Criteria:**
- [ ] All fields validate correctly
- [ ] Product saves to database
- [ ] Product appears in list
- [ ] Product visible in mobile app

---

### 2.4 Manage Products (Edit)

**Story ID:** ADMIN-PROD-EDIT-001  
**Priority:** High  
**As an** admin updating inventory  
**I want to** edit product details  
**So that** information stays accurate

#### Flow:

```
1. Log in as admin
2. Navigate to Products page
3. Find product "Surgical Scalpel Premium"
4. Click edit icon on product row
5. Change price to 29.99
6. Change stock to 150
7. Click "Update Product" button
8. Verify success message
9. Verify changes in products list
10. Verify changes reflect in mobile app
```

**Acceptance Criteria:**
- [ ] Edit form pre-fills with current data
- [ ] Changes save correctly
- [ ] Changes display in list
- [ ] Changes reflect in mobile app

---

### 2.5 Manage Products (Delete)

**Story ID:** ADMIN-PROD-DELETE-001  
**Priority:** Medium  
**As an** admin removing discontinued items  
**I want to** delete products  
**So that** they no longer appear

#### Flow:

```
1. Log in as admin
2. Navigate to Products page
3. Find product to delete
4. Click delete icon
5. Confirm deletion in dialog
6. Verify product removed from list
7. Verify product hidden from mobile app
```

**Acceptance Criteria:**
- [ ] Confirmation dialog appears
- [ ] Product removed from database
- [ ] Product hidden from mobile app
- [ ] Soft delete (not permanent removal)

---

### 2.6 Manage Categories

**Story ID:** ADMIN-CAT-001  
**Priority:** High  
**As an** admin organizing catalog  
**I want to** create and manage categories  
**So that** products are organized

#### Flow:

```
1. Log in as admin
2. Click "Products" → "Categories" in sidebar
3. Click "Add Category" button
4. Enter category name "Dental Supplies"
5. Select parent category (or none for root)
6. Upload category icon/image
7. Click "Save Category" button
8. Verify category appears in tree
9. Edit category to add subcategory
10. Delete old category
```

**Acceptance Criteria:**
- [ ] Categories can be created
- [ ] Hierarchy (parent/child) works
- [ ] Categories display in mobile app
- [ ] Edit and delete work correctly

---

### 2.7 Manage Brands

**Story ID:** ADMIN-BRAND-001  
**Priority:** Medium  
**As an** admin organizing products  
**I want to** create brands  
**So that** products can be filtered by brand

#### Flow:

```
1. Log in as admin
2. Navigate to Products → Brands
3. Click "Add Brand" button
4. Enter brand name "3M Health"
5. Upload brand logo
6. Enter brand description
7. Click "Save Brand" button
8. Verify brand in list
9. Assign brand to products
```

**Acceptance Criteria:**
- [ ] Brands can be created
- [ ] Brands appear in product filters
- [ ] Brand assignment works

---

### 2.8 View All Orders

**Story ID:** ADMIN-ORDERS-001  
**Priority:** High  
**As an** admin monitoring orders  
**I want to** view all orders  
**So that** I can track platform activity

#### Flow:

```
1. Log in as admin
2. Click "Orders" in sidebar
3. View orders table with columns: ID, Doctor, Status, Total, Date
4. Verify orders sorted by date (newest first)
5. Filter by status "Pending"
6. Verify only pending orders show
7. Filter by status "Delivered"
8. Search by order ID
9. Click on order to view detail
10. Verify full order details displayed
```

**Acceptance Criteria:**
- [ ] All orders display in table
- [ ] Filters work correctly
- [ ] Search works
- [ ] Order detail shows all info

---

### 2.9 Update Order Status

**Story ID:** ADMIN-ORDERS-UPDATE-001  
**Priority:** High  
**As an** admin processing orders  
**I want to** update order status  
**So that** doctors know their order progress

#### Flow:

```
1. Log in as admin
2. Navigate to Orders page
3. Find order with status "Pending"
4. Click on order to view detail
5. Change status to "Confirmed"
6. Add note "Order confirmed, preparing for shipment"
7. Click "Update Status" button
8. Verify success message
9. Verify status updated in table
10. Doctor receives notification
11. Update status to "Processing"
12. Update status to "Shipped"
13. Update status to "Delivered"
14. Verify full lifecycle tracked
```

**Acceptance Criteria:**
- [ ] Status can be changed
- [ ] Status updates in database
- [ ] Doctor receives notification
- [ ] Timeline shows full history
- [ ] Status progression correct

---

### 2.10 Manage Doctors (Approve Registration)

**Story ID:** ADMIN-DOCTOR-001  
**Priority:** High  
**As an** admin verifying doctors  
**I want to** approve doctor registrations  
**So that** verified doctors can use the platform

#### Flow:

```
1. Log in as admin
2. Click "Doctors" in sidebar
3. View list of registered doctors
4. Filter by status "Pending Verification"
5. Find new doctor registration
6. Click to view doctor details
7. View uploaded license
8. Click "Approve" button
9. Add note "License verified, account active"
10. Verify doctor status changes to "Active"
11. Doctor receives approval email
12. Doctor can now log in and order
```

**Acceptance Criteria:**
- [ ] Pending doctors display correctly
- [ ] License can be viewed
- [ ] Approval changes status
- [ ] Email notification sent
- [ ] Doctor can log in after approval

---

### 2.11 Reject Doctor Registration

**Story ID:** ADMIN-DOCTOR-REJECT-001  
**Priority:** High  
**As an** admin rejecting invalid registration  
**I want to** reject doctor registrations  
**So that** only valid doctors access the platform

#### Flow:

```
1. Log in as admin
2. Navigate to Doctors page
3. Find pending doctor
4. View doctor details
5. Click "Reject" button
6. Select rejection reason "Invalid license"
7. Add additional note "License number unclear"
8. Click "Confirm Rejection" button
9. Verify doctor status "Rejected"
10. Doctor receives rejection email
11. Doctor cannot log in
```

**Acceptance Criteria:**
- [ ] Rejection form works
- [ ] Status updates to Rejected
- [ ] Email notification sent
- [ ] Doctor cannot access platform

---

### 2.12 Manage Banners

**Story ID:** ADMIN-BANNER-001  
**Priority:** Medium  
**As an** admin promoting content  
**I want to** manage promotional banners  
**So that** they appear on mobile home screen

#### Flow:

```
1. Log in as admin
2. Click "Banners" in sidebar
3. View current banners list
4. Click "Add Banner" button
5. Upload banner image (1080x400)
6. Enter title "Summer Sale"
7. Enter subtitle "Up to 50% off"
8. Select link type "Category"
9. Select category "Medications"
10. Set display order 1
11. Set start date and end date
12. Toggle "Active" ON
13. Click "Save Banner" button
14. Verify banner appears in list
15. Verify banner shows in mobile app
```

**Acceptance Criteria:**
- [ ] Banner uploads correctly
- [ ] Banner displays in mobile app
- [ ] Banner links work
- [ ] Scheduling works (start/end dates)

---

### 2.13 Manage Discounts/Promos

**Story ID:** ADMIN-DISCOUNT-001  
**Priority:** High  
**As an** admin creating promotions  
**I want to** create discount codes  
**So that** doctors can save on orders

#### Flow:

```
1. Log in as admin
2. Click "Discounts" in sidebar
3. Click "Add Discount" button
4. Enter promo code "WELCOME20"
5. Select type "Percentage"
6. Enter value 20
7. Set minimum order amount $50
8. Set usage limit 100
9. Set start date and end date
10. Toggle "Active" ON
11. Click "Save Discount" button
12. Verify discount in list
13. Doctor applies code in mobile app
14. Verify discount applies correctly
15. Check usage counter increments
```

**Acceptance Criteria:**
- [ ] Discounts can be created
- [ ] Percentage and fixed types work
- [ ] Usage limits enforced
- [ ] Expiry dates work
- [ ] Discount applies in mobile app

---

### 2.14 Manage Flash Sales

**Story ID:** ADMIN-FLASHSALE-001  
**Priority:** High  
**As an** admin creating urgency  
**I want to** create flash sales  
**So that** doctors get time-limited deals

#### Flow:

```
1. Log in as admin
2. Navigate to Discounts → Flash Sales
3. Click "Add Flash Sale" button
4. Select product "Panadol Extra"
5. Enter original price $10
6. Enter flash price $7.50
7. Set quantity limit per order 2
8. Set start time (now)
9. Set end time (2 hours from now)
10. Toggle "Active" ON
11. Click "Save Flash Sale" button
12. Verify flash sale in list
13. Verify countdown shows in mobile app
14. Verify special price applies during sale
15. Verify sale ends after time expires
```

**Acceptance Criteria:**
- [ ] Flash sales create correctly
- [ ] Countdown timer works
- [ ] Special pricing applies
- [ ] Sale ends automatically

---

### 2.15 View Reports and Analytics

**Story ID:** ADMIN-REPORT-001  
**Priority:** Medium  
**As an** admin analyzing performance  
**I want to** view reports  
**So that** I can make data-driven decisions

#### Flow:

```
1. Log in as admin
2. Click "Dashboard" in sidebar
3. View default overview
4. Filter by date range "Last 30 days"
5. Check revenue chart
6. Check orders by category chart
7. Click "Reports" in sidebar
8. View sales report
9. Export to CSV
10. View top selling products
11. View top doctors by orders
```

**Acceptance Criteria:**
- [ ] Dashboard shows analytics
- [ ] Date filters work
- [ ] Charts render correctly
- [ ] Export functionality works

---

### 2.16 Manage Addresses

**Story ID:** ADMIN-ADDRESS-001  
**Priority:** Medium  
**As an** admin managing delivery zones  
**I want to** view and manage delivery areas  
**So that** delivery works correctly

#### Flow:

```
1. Log in as admin
2. Navigate to Settings or Orders
3. View delivery addresses
4. Search for specific address
5. View order deliveries by area
6. Export address list for delivery team
```

**Acceptance Criteria:**
- [ ] Addresses display correctly
- [ ] Search and filter work
- [ ] Export functions properly

---

### 2.17 Logout

**Story ID:** ADMIN-LOGOUT-001  
**Priority:** Medium  
**As an** admin finishing session  
**I want to** log out securely  
**So that** my account is protected

#### Flow:

```
1. Log in as admin
2. Click user avatar in header
3. Click "Logout" button
4. Verify redirect to login page
5. Verify session cleared
6. Try to access dashboard URL
7. Verify redirect to login (not authenticated)
```

**Acceptance Criteria:**
- [ ] Logout button visible
- [ ] Session ends successfully
- [ ] Redirects to login
- [ ] Cannot access protected routes

---

### 2.18 Admin Profile Management

**Story ID:** ADMIN-PROFILE-001  
**Priority:** Medium  
**As an** admin updating my settings  
**I want to** edit my profile  
**So that** my information is current

#### Flow:

```
1. Log in as admin
2. Click user avatar in header
3. Click "Profile" option
4. View current profile
5. Change phone number
6. Change password
7. Click "Save Changes"
8. Verify success message
9. Verify changes reflected
```

**Acceptance Criteria:**
- [ ] Profile editable
- [ ] Password change works
- [ ] Changes persist

---

### 2.19 System Settings

**Story ID:** ADMIN-SETTINGS-001  
**Priority:** Low  
**As an** admin configuring platform  
**I want to** manage system settings  
**So that** the platform works as needed

#### Flow:

```
1. Log in as admin
2. Click "Settings" in sidebar
3. View platform settings
4. Toggle maintenance mode
5. Configure email settings
6. Configure SMS settings
7. Set tax rates
8. Set minimum order amount
9. Save settings
10. Verify settings applied
```

**Acceptance Criteria:**
- [ ] Settings save correctly
- [ ] Settings affect platform behavior
- [ ] Settings persist

---

### 2.20 View Notification Logs

**Story ID:** ADMIN-NOTIF-001  
**Priority:** Low  
**As an** admin monitoring communications  
**I want to** see notification logs  
**So that** I can debug issues

#### Flow:

```
1. Log in as admin
2. Navigate to Notifications
3. View sent notifications list
4. Filter by type (Email, SMS, Push)
5. Filter by status (Sent, Failed)
6. View notification details
7. Resend failed notification
```

**Acceptance Criteria:**
- [ ] Notification logs display
- [ ] Filters work correctly
- [ ] Resend functionality works

---

## Summary

This document contains **40 comprehensive user stories** covering:

### Doctor (Customer) Stories (20)
1. Doctor Registration with License Upload
2. Doctor Login with JWT Tokens
3. Password Reset via OTP
4. Browse Products by Category
5. Search Products with Debounce
6. Apply Product Filters
7. Add Product to Cart
8. Update Cart Quantity
9. Remove Product from Cart
10. Create Order with Cash on Delivery
11. View Order History
12. Track Order in Real-Time
13. Reorder from Order Detail
14. Add to Wishlist
15. Apply Promo Code
16. Submit Product Review
17. Update Profile Information
18. View Notifications
19. Toggle Language to Arabic (RTL)
20. Offline Mode - Cached Data

### Admin Stories (20)
1. Admin Login
2. View Dashboard Overview
3. Manage Products (Create)
4. Manage Products (Edit)
5. Manage Products (Delete)
6. Manage Categories
7. Manage Brands
8. View All Orders
9. Update Order Status
10. Manage Doctors (Approve Registration)
11. Reject Doctor Registration
12. Manage Banners
13. Manage Discounts/Promos
14. Manage Flash Sales
15. View Reports and Analytics
16. Manage Addresses
17. Logout
18. Admin Profile Management
19. System Settings
20. View Notification Logs

Each story includes detailed step-by-step flows simulating real user interactions, written in the style of end-to-end tests to ensure comprehensive coverage of all system functionality.
