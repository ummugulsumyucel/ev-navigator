# Firestore Veritabanı Şeması

## Koleksiyonlar

### users
```json
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "photoUrl": "string?",
  "phone": "string?",
  "role": "user | admin",
  "emailVerified": "boolean",
  "profileCompleted": "boolean",
  "vehicleIds": ["string"],
  "stats": {
    "totalCharges": "number",
    "totalKm": "number",
    "totalSavingsTl": "number"
  },
  "fcmToken": "string?",
  "following": ["uid"],
  "followers": ["uid"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### vehicles
```json
{
  "id": "string",
  "ownerId": "string",
  "brand": "string",
  "model": "string",
  "year": "number",
  "batteryKwh": "number",
  "wltpRangeKm": "number",
  "vin": "string?",
  "plate": "string?",
  "isPrimary": "boolean",
  "createdAt": "timestamp"
}
```

### charging_stations
```json
{
  "id": "string",
  "name": "string",
  "network": "zes | esarj | trugo | wat | tesla | shell",
  "location": { "lat": "number", "lng": "number" },
  "geohash": "string",
  "address": "string",
  "city": "string",
  "sockets": [{
    "id": "string",
    "type": "ccs2 | chademo | ac_type2 | tesla",
    "powerKw": "number",
    "status": "available | occupied | faulted",
    "isReservable": "boolean"
  }],
  "pricePerKwh": "number?",
  "status": "available | busy | offline",
  "reliabilityScore": "number",
  "supportsReservation": "boolean",
  "photoUrls": ["string"],
  "availableCount": "number",
  "totalSockets": "number",
  "updatedAt": "timestamp"
}
```

### station_reviews
```json
{
  "id": "string",
  "stationId": "string",
  "userId": "string",
  "userName": "string",
  "rating": "number (1-5)",
  "comment": "string",
  "photoUrls": ["string"],
  "createdAt": "timestamp"
}
```

### favorites
```json
{
  "id": "string",
  "userId": "string",
  "stationId": "string",
  "createdAt": "timestamp"
}
```

### trips
```json
{
  "id": "string",
  "userId": "string",
  "vehicleId": "string",
  "origin": { "name": "string", "lat": "number", "lng": "number" },
  "destination": { "name": "string", "lat": "number", "lng": "number" },
  "strategy": "fastest | cheapest | balanced | safest",
  "startSoc": "number",
  "distanceKm": "number",
  "driveMinutes": "number",
  "chargeMinutes": "number",
  "totalCostTl": "number",
  "chargingStops": [{
    "stationId": "string",
    "stationName": "string",
    "chargeMinutes": "number",
    "costTl": "number"
  }],
  "createdAt": "timestamp"
}
```

### battery_reports
```json
{
  "id": "string",
  "userId": "string",
  "vehicleId": "string",
  "soh": "number",
  "soc": "number",
  "temperatureC": "number",
  "chargeCycles": "number",
  "realRangeKm": "number",
  "efficiencyKwhPer100km": "number",
  "recordedAt": "timestamp"
}
```

### community_posts
```json
{
  "id": "string",
  "authorId": "string",
  "authorName": "string",
  "authorPhoto": "string?",
  "brand": "string",
  "title": "string",
  "content": "string",
  "photoUrls": ["string"],
  "likeCount": "number",
  "commentCount": "number",
  "likedBy": ["uid"],
  "createdAt": "timestamp"
}
```

### comments
```json
{
  "id": "string",
  "postId": "string",
  "authorId": "string",
  "authorName": "string",
  "content": "string",
  "createdAt": "timestamp"
}
```

### notifications
```json
{
  "id": "string",
  "userId": "string",
  "type": "station_outage | charge_complete | new_comment | new_follower | news",
  "title": "string",
  "body": "string",
  "data": "map",
  "read": "boolean",
  "createdAt": "timestamp"
}
```

### services
```json
{
  "id": "string",
  "name": "string",
  "brand": "string",
  "type": "authorized | independent",
  "location": { "lat": "number", "lng": "number" },
  "address": "string",
  "phone": "string",
  "rating": "number",
  "reviewCount": "number",
  "serviceTypes": ["string"],
  "avgWaitDays": "number"
}
```

### appointments
```json
{
  "id": "string",
  "userId": "string",
  "serviceId": "string",
  "serviceName": "string",
  "serviceType": "string",
  "date": "timestamp",
  "status": "pending | confirmed | completed | cancelled",
  "createdAt": "timestamp"
}
```

### news
```json
{
  "id": "string",
  "title": "string",
  "summary": "string",
  "content": "string",
  "imageUrl": "string?",
  "category": "string",
  "publishedAt": "timestamp",
  "authorId": "string"
}
```

## İndeksler (firestore.indexes.json)

- `charging_stations`: geohash ASC, network ASC
- `community_posts`: createdAt DESC
- `station_reviews`: stationId ASC, createdAt DESC
- `trips`: userId ASC, createdAt DESC
- `notifications`: userId ASC, createdAt DESC
