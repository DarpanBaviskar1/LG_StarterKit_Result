# 🌐 API Integration Troubleshooting

## Common API Errors and Solutions

This guide covers errors related to HTTP API integrations (Nominatim, Open-Meteo, USGS, Gemini, etc.)

---

## Quick Reference Table

| Error | Likely Cause | Quick Fix |
|-------|--------------|-----------|
| TimeoutException | API slow/down | Increase timeout, check connection |
| 404 Not Found | Wrong URL | Verify endpoint in API docs |
| 401 Unauthorized | Missing/invalid API key | Check API key configuration |
| 429 Too Many Requests | Rate limit exceeded | Add throttling, use caching |
| 500 Internal Server Error | API server issue | Retry with exponential back off |
| FormatException | Invalid JSON | Check API response format |
| Type cast error | Wrong data type | Add type checking and null safety |
| SocketException | No internet | Check network connection |

---

## 1. Timeout Errors

### Error Message
```
TimeoutException after 0:00:15.000000: Future not completed
```

### Causes
1. **API server is slow/overloaded**
2. **No internet connection**
3. **Firewall blocking request**
4. **DNS resolution failure**
5. **Timeout duration too short**

### Solutions

**Solution 1: Increase timeout**
```dart
// Current (15 seconds)
final response = await http.get(uri)
    .timeout(const Duration(seconds: 15));

// Try (30 seconds)
final response = await http.get(uri)
    .timeout(const Duration(seconds: 30));
```

**Solution 2: Check internet connection first**
```dart
Future<bool> hasInternetConnection() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (e) {
    return false;
  }
}

// Use before API call
if (!await hasInternetConnection()) {
  throw Exception('No internet connection');
}
```

**Solution 3: Add retry logic**
```dart
Future<http.Response> fetchWithRetry(
  Uri uri, {
  int maxRetries = 3,
  Duration timeout = const Duration(seconds: 15),
}) async {
  int attempts = 0;
  
  while (attempts < maxRetries) {
    try {
      attempts++;
      debugPrint('🔄 Attempt $attempts/$maxRetries');
      
      final response = await http.get(uri).timeout(timeout);
      return response;
    } on TimeoutException {
      if (attempts >= maxRetries) {
        rethrow;
      }
      debugPrint('⏳ Timeout, retrying...');
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

**Solution 4: Test API manually**
```bash
# Windows PowerShell
Invoke-WebRequest -Uri "https://api.example.com/data" -TimeoutSec 30

# Check if API responds
```

---

## 2. HTTP Status Code Errors

### 400 Bad Request

**Error:**
```
Status Code: 400
Body: {"error": "Invalid parameter"}
```

**Causes:**
- Missing required parameters
- Invalid parameter format
- Wrong parameter values

**Solutions:**

**Check required parameters:**
```dart
// ❌ Wrong - missing required param
final url = 'https://api.example.com/search?q=test';

// ✅ Correct - all required params
final url = 'https://api.example.com/search?q=test&format=json&limit=10';
```

**Validate parameter format:**
```dart
// ❌ Wrong - coordinates not URL encoded
final lat = '37.7749';
final lon = '-122.4194';
final url = 'https://api.example.com?lat=$lat&lon=$lon';

// ✅ Correct - use Uri.encodeFull()
final params = {
  'lat': lat,
  'lon': lon,
};
final uri = Uri.https('api.example.com', '/endpoint', params);
```

**Check parameter types:**
```dart
// Example from API docs:
// limit: integer (1-100)
// format: string ("json" or "xml")

// ❌ Wrong
final url = '?limit=abc&format=true';

// ✅ Correct
final url = '?limit=50&format=json';
```

### 401 Unauthorized

**Error:**
```
Status Code: 401
Body: {"error": "Authentication required"}
```

**Causes:**
- Missing API key
- Invalid API key
- Expired API key
- API key not in correct header

**Solutions:**

**For Gemini API (requires key):**
```dart
// ❌ Wrong - no API key
final response = await http.post(
  Uri.parse('https://generativelanguage.googleapis.com/...'),
);

// ✅ Correct - API key in query param
final url = Uri.parse(
  'https://generativelanguage.googleapis.com/.../gemini-1.5-flash-002:generateContent?key=$apiKey'
);
```

**For header-based auth:**
```dart
final response = await http.get(
  uri,
  headers: {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
  },
);
```

**Check API key configuration:**
```dart
// Load from environment or config
final apiKey = Platform.environment['GOOGLE_API_KEY'];
if (apiKey == null || apiKey.isEmpty) {
  throw Exception('API key not configured');
}
```

### 404 Not Found

**Error:**
```
Status Code: 404
Body: {"error": "Endpoint not found"}
```

**Causes:**
- Wrong API endpoint URL
- API version changed
- Typo in URL
- Missing path parameters

**Solutions:**

**Verify endpoint:**
```dart
// ❌ Wrong - typo in endpoint
final url = 'https://nominatim.openstreetmap.org/serach?q=Berlin';
//                                                      ^^^^^^

// ✅ Correct - check spelling
final url = 'https://nominatim.openstreetmap.org/search?q=Berlin';
//                                                ^^^^^^
```

**Check API version:**
```dart
// ❌ Wrong - old API version
final url = 'https://api.example.com/v1/data';

// ✅ Correct - current version is v2
final url = 'https://api.example.com/v2/data';
```

**Verify base URL:**
```dart
// Print URL before calling
debugPrint('📡 Calling API: $url');

// Check against API documentation
```

### 429 Too Many Requests

**Error:**
```
Status Code: 429
Body: {"error": "Rate limit exceeded"}
Headers: Retry-After: 60
```

**Causes:**
- Too many requests in short time
- No rate limiting in code
- Multiple users sharing same IP

**Solutions:**

**Solution 1: Add request throttling**
```dart
class ThrottledService {
  DateTime? _lastRequestTime;
  final Duration _minInterval = const Duration(seconds: 1);
  
  Future<http.Response> get(Uri uri) async {
    // Wait if needed
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minInterval) {
        final waitTime = _minInterval - elapsed;
        debugPrint('⏳ Throttling: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    
    _lastRequestTime = DateTime.now();
    return await http.get(uri);
  }
}
```

**Solution 2: Implement caching**
```dart
class CachedService {
  final Map<String, CacheEntry> _cache = {};
  
  Future<String> fetchData(String query) async {
    // Check cache first
    if (_cache.containsKey(query)) {
      final entry = _cache[query]!;
      final age = DateTime.now().difference(entry.timestamp);
      
      // Cache valid for 1 hour
      if (age < const Duration(hours: 1)) {
        debugPrint('💾 Using cached data for: $query');
        return entry.data;
      }
    }
    
    // Fetch from API
    final response = await http.get(Uri.parse('$baseUrl?q=$query'));
    final data = response.body;
    
    // Store in cache
    _cache[query] = CacheEntry(data, DateTime.now());
    
    return data;
  }
}

class CacheEntry {
  final String data;
  final DateTime timestamp;
  
  CacheEntry(this.data, this.timestamp);
}
```

**Solution 3: Check Retry-After header**
```dart
try {
  final response = await http.get(uri);
  
  if (response.statusCode == 429) {
    final retryAfter = response.headers['retry-after'];
    if (retryAfter != null) {
      final waitSeconds = int.parse(retryAfter);
      debugPrint('⏳ Rate limited. Waiting $waitSeconds seconds...');
      await Future.delayed(Duration(seconds: waitSeconds));
      
      // Retry
      return await http.get(uri);
    }
  }
} catch (e) {
  debugPrint('❌ Error: $e');
}
```

### 500 Internal Server Error

**Error:**
```
Status Code: 500
Body: {"error": "Internal server error"}
```

**Causes:**
- API server bug
- Server overload
- Database issue on server side

**Solutions:**

**Solution 1: Retry with exponential backoff**
```dart
Future<http.Response> fetchWithBackoff(Uri uri) async {
  int attempt = 0;
  int maxAttempts = 3;
  int delaySeconds = 1;
  
  while (attempt < maxAttempts) {
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 500) {
        attempt++;
        if (attempt >= maxAttempts) {
          throw Exception('Server error persists after $maxAttempts attempts');
        }
        
        debugPrint('⏳ Server error, retrying in $delaySeconds seconds...');
        await Future.delayed(Duration(seconds: delaySeconds));
        
        // Exponential backoff: 1s, 2s, 4s, ...
        delaySeconds *= 2;
        continue;
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }
  
  throw Exception('Max retries exceeded');
}
```

**Solution 2: Show user-friendly error**
```dart
if (response.statusCode == 500) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Server is experiencing issues. Please try again later.'),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 5),
    ),
  );
  return;
}
```

### 503 Service Unavailable

**Error:**
```
Status Code: 503
Body: {"error": "Service temporarily unavailable"}
```

**Causes:**
- API server maintenance
- Server overload
- DDoS attack on API

**Solutions:**
- Retry after delay (similar to 500)
- Check API status page
- Use fallback API if available
- Show maintenance message to user

---

## 3. JSON Parsing Errors

### FormatException

**Error:**
```
FormatException: Unexpected character (at line 1, character 1)
```

**Causes:**
- API returned HTML instead of JSON
- API returned error message as plain text
- Empty response body

**Solutions:**

**Solution 1: Check content type**
```dart
if (response.statusCode == 200) {
  final contentType = response.headers['content-type'];
  
  if (contentType == null || !contentType.contains('application/json')) {
    debugPrint('⚠️ Response is not JSON: $contentType');
    debugPrint('Body: ${response.body}');
    throw Exception('API returned non-JSON response');
  }
  
  final data = jsonDecode(response.body);
  // ...
}
```

**Solution 2: Handle empty response**
```dart
if (response.body.isEmpty) {
  debugPrint('⚠️ Empty response body');
  return [];
}

try {
  final data = jsonDecode(response.body);
  // ...
} on FormatException catch (e) {
  debugPrint('❌ JSON parse error: $e');
  debugPrint('Response body: ${response.body}');
  throw Exception('Invalid JSON response');
}
```

### Type Cast Errors

**Error:**
```
type 'int' is not a subtype of type 'String' in type cast
```

**Causes:**
- API changed data type
- Assumed type incorrectly
- Null values in JSON

**Solutions:**

**Solution 1: Safe type casting**
```dart
// ❌ Wrong - assumes String
final name = json['name'] as String;
final tsunami = json['tsunami'] as String;

// ✅ Correct - handles multiple types
final name = json['name']?.toString() ?? 'Unknown';

// Handle int/string for tsunami field
final tsunamiRaw = json['tsunami'];
final tsunami = tsunamiRaw is int
    ? (tsunamiRaw == 1 ? 'true' : 'false')
    : tsunamiRaw?.toString() ?? 'false';
```

**Solution 2: Null safety**
```dart
// ❌ Wrong - crashes on null
final depth = coords[2] as double;

// ✅ Correct - handles missing data
final depth = coords.length > 2
    ? (coords[2] as num?)?.toDouble() ?? 0.0
    : 0.0;
```

**Solution 3: Print JSON structure**
```dart
debugPrint('📦 Raw JSON: ${response.body}');
final json = jsonDecode(response.body);
debugPrint('📦 Parsed JSON type: ${json.runtimeType}');

// Inspect structure
if (json is Map) {
  debugPrint('Keys: ${json.keys}');
  json.forEach((key, value) {
    debugPrint('  $key: ${value.runtimeType} = $value');
  });
}
```

---

## 4. Network Errors

### SocketException

**Error:**
```
SocketException: Failed host lookup: 'api.example.com'
```

**Causes:**
- No internet connection
- DNS resolution failure
- Domain doesn't exist
- Firewall blocking

**Solutions:**

**Solution 1: Check connectivity**
```dart
import 'dart:io';

Future<void> _loadData() async {
  try {
    // Test connectivity first
    await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
    
    // Proceed with API call
    final response = await http.get(uri);
    // ...
  } on SocketException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

**Solution 2: Verify domain**
```bash
# Test DNS resolution
nslookup api.example.com

# Test connection
curl https://api.example.com/data
```

### HandshakeException

**Error:**
```
HandshakeException: Handshake error in client
```

**Causes:**
- SSL certificate issues
- TLS version mismatch
- Man-in-the-middle attack

**Solutions:**

**Solution 1: Verify SSL certificate**
```bash
# Check certificate
openssl s_client -connect api.example.com:443 -servername api.example.com
```

**Solution 2: Use http instead (NOT RECOMMENDED for production)**
```dart
// Only for testing!
final url = 'http://api.example.com/data';  // Not https://
```

**Solution 3: Update dependencies**
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0  # Latest version
```

---

## 5. Specific API Issues

### Nominatim (OpenStreetMap)

**Issue: Empty results**
```dart
final response = await http.get(uri);
final data = jsonDecode(response.body) as List;
// data.isEmpty == true
```

**Causes:**
- Search query too specific
- Location doesn't exist
- Typo in query

**Solutions:**
```dart
// Try broader search
// Before: "123 Main Street, Springfield, IL"
// After: "Springfield, IL"

// Add format parameter
final uri = Uri.https(
  'nominatim.openstreetmap.org',
  '/search',
  {
    'q': query,
    'format': 'json',
    'addressdetails': '1',
    'limit': '10',  // Get more results
  },
);
```

**Issue: Rate limiting (429)**
**Solution:** Add User-Agent header (required by Nominatim)
```dart
final response = await http.get(
  uri,
  headers: {
    'User-Agent': 'LGController/1.0 (your@email.com)',
  },
);
```

### Open-Meteo (Weather)

**Issue: Coordinates out of range**
```
Status 400: latitude must be between -90 and 90
```

**Solution:**
```dart
// Validate coordinates
if (lat < -90 || lat > 90) {
  throw Exception('Invalid latitude: $lat');
}
if (lng < -180 || lng > 180) {
  throw Exception('Invalid longitude: $lng');
}

final uri = Uri.https(
  'api.open-meteo.com',
  '/v1/forecast',
  {
    'latitude': lat.toString(),
    'longitude': lng.toString(),
    // ...
  },
);
```

### USGS (Earthquakes)

**Issue: Too much data**
```dart
// Can return 1000s of earthquakes
final data = jsonDecode(response.body);
final features = data['features'] as List;
// features.length == 5000+
```

**Solutions:**

**Filter by magnitude:**
```dart
final uri = Uri.https(
  'earthquake.usgs.gov',
  '/earthquakes/feed/v1.0/summary/4.5_week.geojson',
  // 4.5+ magnitude only
);
```

**Limit results:**
```dart
final filteredEarthquakes = earthquakes
    .where((eq) => eq.magnitude >= 4.5)
    .take(50)  // Limit to 50
    .toList();
```

### Google Gemini

**Issue: 401 Unauthorized**
**Solution:** Check API key
```dart
final apiKey = Platform.environment['GOOGLE_API_KEY'];
if (apiKey == null) {
  throw Exception('GOOGLE_API_KEY not set in environment');
}
```

**Issue: 400 Bad Request**
**Cause:** Invalid prompt format

**Solution:**
```dart
// Correct Gemini API request format
final body = jsonEncode({
  'contents': [{
    'parts': [{
      'text': prompt,
    }],
  }],
  'generationConfig': {
    'temperature': 1.0,
    'maxOutputTokens': 1000,
  },
});
```

---

## General Debugging Strategy

### 1. Test API in Browser/Postman
Before coding, verify API works:
```
https://nominatim.openstreetmap.org/search?q=Berlin&format=json
```

### 2. Log Everything
```dart
debugPrint('📡 REQUEST: $uri');
debugPrint('📡 Headers: ${response.headers}');
debugPrint('📡 Status: ${response.statusCode}');
debugPrint('📦 Body: ${response.body}');
```

### 3. Use Try-Catch Blocks
```dart
try {
  final response = await http.get(uri).timeout(const Duration(seconds: 15));
  // ...
} on TimeoutException {
  debugPrint('❌ Timeout');
} on SocketException {
  debugPrint('❌ Network error');
} on FormatException {
  debugPrint('❌ JSON parse error');
} catch (e) {
  debugPrint('❌ Unknown error: $e');
}
```

### 4. Validate Responses
```dart
if (response.statusCode != 200) {
  debugPrint('❌ HTTP ${response.statusCode}: ${response.body}');
  throw Exception('API error: ${response.statusCode}');
}
```

---

## Prevention Checklist

Before deploying API integration:

- [ ] Added timeout to all HTTP calls (10-30 seconds)
- [ ] Wrapped all API calls in try-catch
- [ ] Validated all parameters before sending
- [ ] Added null safety to all JSON parsing
- [ ] Tested with empty/null/invalid responses
- [ ] Added rate limiting or caching
- [ ] Logged all errors with context
- [ ] Tested without internet connection
- [ ] Verified SSL certificates (for HTTPS)
- [ ] Documented API requirements and limits

---

**See also:**
- [2-patterns/service-layer.md](../2-patterns/service-layer.md) - Service patterns
- [7-workflows/debugging.md](../7-workflows/debugging.md) - Debugging process
- [QUICK_REFERENCE.md](../QUICK_REFERENCE.md) - Quick fixes

**Last Updated:** 2026-02-10
