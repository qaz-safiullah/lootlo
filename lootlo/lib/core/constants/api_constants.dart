class ApiConstants {
  // ----------------------------------------------------------------------
  // YOUR LAPTOP'S IP ADDRESS
  // ----------------------------------------------------------------------
  static const String baseUrl = 'http://192.168.0.107:3000/api'; 

  // Auth Endpoints
  static const String signupEndpoint = '$baseUrl/users/signup';
  static const String loginEndpoint = '$baseUrl/users/login';
  static const String profileEndpoint = '$baseUrl/users/me';
  static const String resetPasswordEndpoint = '$baseUrl/users/reset-password';
  
  // Items Endpoints
  static const String itemsEndpoint = '$baseUrl/items';
  static const String nearbyItemsEndpoint = '$baseUrl/items/nearby';
  static const String myListingsEndpoint = '$baseUrl/items/my-listings';
  static String itemDetailsEndpoint(int id) => '$baseUrl/items/$id';
  static String checkRequestStatusEndpoint(int itemId) => '$baseUrl/requests/$itemId/check'; // GET
  // --- NEW: Requests (The Golden Flow) ---
  static String requestItemEndpoint(int itemId) => '$baseUrl/requests/$itemId'; // POST
  static const String receivedRequestsEndpoint = '$baseUrl/requests/received';   // GET
  static const String myRequestsEndpoint = '$baseUrl/requests/my-requests';      // GET
  static String acceptRequestEndpoint(int requestId) => '$baseUrl/requests/$requestId/accept';     // PUT
  static String completeRequestEndpoint(int requestId) => '$baseUrl/requests/$requestId/complete'; // PUT
  static String cancelRequestEndpoint(int requestId) => '$baseUrl/requests/$requestId/cancel';     // PUT

  // --- NEW: Wishlist Endpoints ---
  static const String wishlistEndpoint = '$baseUrl/wishlist'; // GET all, POST to add
  static String checkWishlistEndpoint(int itemId) => '$baseUrl/wishlist/$itemId/check'; // GET
  static String toggleWishlistEndpoint(int itemId) => '$baseUrl/wishlist/$itemId/toggle'; // POST/PUT
  
}