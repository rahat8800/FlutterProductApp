# Flutter Shop App

A comprehensive Flutter e-commerce application with user authentication, product listing, detailed product views, and user profile management.

## Features

### 1. User Authentication

- **User Registration**: Create new accounts with email, password, and name
- **User Login**: Secure login with email and password validation
- **Session Persistence**: Users remain logged in until explicit logout
- **Form Validation**: Comprehensive validation for all input fields

### 2. Product Listing Screen

- **Product Grid**: Displays products in an attractive grid layout
- **Product Cards**: Shows product image, name, price, and rating
- **Search Functionality**: Search products by name or category
- **API Integration**: Fetches products from FakeStoreAPI
- **Loading States**: Proper loading indicators and error handling

### 3. Product Detail Screen

- **Comprehensive Information**: Product image, title, price, category
- **Detailed Description**: Full product description and specifications
- **Customer Reviews**: Rating display and review count
- **Responsive Design**: Optimized for different screen sizes
- **Add to Cart**: Interactive cart functionality

### 4. User Profile Screen

- **Profile Picture Management**: Upload photos from gallery or camera
- **Editable Information**: Update name and email with form validation
- **Account Information**: View user ID and member since date
- **Edit Mode**: Toggle between view and edit modes
- **Logout Functionality**: Secure logout with session cleanup

## Architecture

The app follows a clean architecture pattern with proper separation of concerns:

```
lib/
├── constants/          # App-wide constants and API endpoints
├── models/            # Data models (Product, User)
├── providers/         # State management with Provider
├── screens/           # UI screens (Login, Register, Products, Details, Profile)
├── services/          # Business logic and API calls
├── utils/             # Utility functions and validators
├── widgets/           # Reusable UI components
└── main.dart          # App entry point
```

### Key Components

- **Models**: `Product` and `User` classes with JSON serialization
- **Services**: `ApiService` for HTTP requests, `AuthService` for authentication
- **Providers**: `AuthProvider` and `ProductProvider` for state management
- **Screens**: Login, Register, Products, Product Detail, and Profile screens
- **Widgets**: Reusable components like ProductCard, LoadingWidget, ErrorWidget

## Dependencies

- **http**: For API requests
- **provider**: State management
- **shared_preferences**: Local storage for authentication persistence
- **cached_network_image**: Image caching and loading
- **form_field_validator**: Form validation
- **image_picker**: Profile picture selection from camera/gallery

## Setup Instructions

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd flutter_application_1
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **iOS Setup (if running on iOS)**

   ```bash
   cd ios && pod install && cd ..
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## API Integration

The app uses the [FakeStoreAPI](https://fakestoreapi.com/) for product data:

- Product listing: `GET /products`
- Product details: `GET /products/{id}`
- Categories: `GET /products/categories`

## Authentication Flow

1. **Registration**: Users can create new accounts
2. **Login**: Registered users can log in
3. **Session Management**: Authentication state persists across app restarts
4. **Profile Management**: Users can update their profile information
5. **Logout**: Users can log out from the profile screen

## Features in Detail

### Product Listing

- Grid layout with 2 columns
- Product cards with images, titles, prices, and ratings
- Search functionality with real-time filtering
- Loading states and error handling
- Pull-to-refresh capability

### Product Details

- Large product image with caching
- Comprehensive product information
- Specifications table
- Customer reviews section
- Add to cart functionality

### User Profile

- Profile picture upload from camera or gallery
- Editable name and email fields
- Form validation for profile updates
- Account information display
- Secure logout functionality

### User Interface

- Material Design 3 theme
- Responsive layout
- Consistent styling across screens
- Error handling with retry options
- Loading indicators

## Testing

To test the app:

1. **Registration**: Create a new account with valid email and password
2. **Login**: Use the registered credentials to log in
3. **Browse Products**: View the product listing and search functionality
4. **Product Details**: Tap on any product to view detailed information
5. **Profile Management**: Access profile from the menu and update information
6. **Profile Picture**: Upload a photo from camera or gallery
7. **Logout**: Use the logout button in the profile screen

## Permissions

The app requires the following permissions:

- **Camera**: For taking profile pictures
- **Photo Library**: For selecting profile pictures from gallery

## Mock Authentication

Since FakeStoreAPI doesn't provide authentication, the app implements a mock authentication system:

- User data is stored in memory during the session
- Passwords are validated but not hashed (for demo purposes)
- Session persistence uses SharedPreferences

## Future Enhancements

- Real backend integration
- Shopping cart functionality
- Order history
- Payment integration
- Push notifications
- Offline support
- Social media login
- Password reset functionality
