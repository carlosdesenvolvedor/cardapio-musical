# MUSICG System - Complete Architecture Reference

> **Document Version**: 1.1 | **Last Updated**: 2026-02-07
> **Purpose**: Comprehensive context document for AI conversations when starting new sessions

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Infrastructure & Deployment](#infrastructure--deployment)
4. [Database Architecture](#database-architecture)
5. [Flutter Frontend Architecture](#flutter-frontend-architecture)
6. [Backend API Architecture](#backend-api-architecture)
7. [Feature Modules Deep Dive](#feature-modules-deep-dive)
8. [Entity Models Reference](#entity-models-reference)
9. [State Management (BLoC)](#state-management-bloc)
10. [Services & Integrations](#services--integrations)
11. [Authentication Flow](#authentication-flow)
12. [Data Flow & Dual-Write Pattern](#data-flow--dual-write-pattern)
13. [Known Issues & Patterns](#known-issues--patterns)
14. [File Structure Reference](#file-structure-reference)

---

## Project Overview

**MUSICG** is a music industry platform connecting musicians, bands, event organizers, and service providers. The system enables:

- **Musicians** to create profiles, share repertoire, receive song requests with tips, go live
- **Bands** to manage members, subscriptions, and professional profiles
- **Event Organizers** to plan events, hire services, manage budgets
- **Service Providers** to offer services (audio, catering, security, media)
- **Fans** to follow artists, view stories/posts, request songs via QR code

### Key User Flows

1. **Musician Flow**: Register → Complete Profile → Add Repertoire → Go Live → Receive Requests
2. **Client Menu Flow**: Scan QR Code → View Musician → Search Repertoire → Request Song (+ Tip via PIX)
3. **Social Flow**: Post Content → Stories (24h) → Follow/Unfollow → Feed → Chat

---

## Technology Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.x | Cross-platform UI (Web primary) |
| Dart | 3.x | Language |
| flutter_bloc | - | State management |
| get_it | - | Dependency injection |
| dartz | - | Functional programming (Either) |
| firebase_auth | - | Authentication |
| cloud_firestore | - | Real-time database |
| dio | - | HTTP client |
| google_sign_in | 6.2.1+ | Google Sign-In (GIS SDK for web) |
| google_sign_in_web | 0.12.0+ | Web-specific renderButton support |

### Backend
| Technology | Version | Purpose |
|------------|---------|---------|
| ASP.NET Core | 8.0 | REST API |
| Entity Framework Core | - | PostgreSQL ORM |
| SignalR | - | Real-time chat (ChatHub) |
| MinIO | - | S3-compatible object storage |
| MongoDB | - | Chat and Feed storage |
| PostgreSQL | 15 | User profiles, services, wallet |

### Infrastructure
| Service | Purpose |
|---------|---------|
| Firebase Auth | User authentication (Email/Google) |
| Firebase Firestore | Real-time data (posts, stories, songs, follows) |
| Firebase Hosting | Web app deployment |
| Cloudinary | Image/video CDN and transformations |
| LiveKit | WebRTC live streaming |
| Nginx | Reverse proxy, SSL termination |
| Oracle Cloud | Docker host server |

---

## Infrastructure & Deployment

### Docker Compose Services

```yaml
services:
  minio:         # Port 9000/9001 - Object storage
  postgres:      # Port 5432 - User profiles, services
  mongodb:       # Port 27017 - Chat, feed
  backend:       # Port 5000 - ASP.NET Core API
  mediamtx:      # Port 1935/8888/8889 - RTMP streaming
  livekit:       # Port 7880/7881/7882 - WebRTC
  nginx:         # Port 80/443 - Reverse proxy
```

### Server Details
- **Host**: Oracle Cloud (136.248.64.90.nip.io)
- **SSL**: Let's Encrypt via Certbot
- **Proxy Routes**:
  - `/api/*` → Backend API (with WebSocket upgrade for SignalR negotiate)
  - `/media/*` → MinIO (with Range headers for video streaming)
  - `/livekit/*` → LiveKit (WebSocket upgrade)
  - `/chathub` → SignalR WebSocket Hub
- **Global Headers**:
  - `Cross-Origin-Opener-Policy: same-origin-allow-popups` (Google Sign-In compatibility)

### Firebase Project
- **Project ID**: `music-system-421ee`
- **Hosting URL**: `https://music-system-421ee.web.app`

---

## Database Architecture

### Firebase Firestore Collections

```
📁 Firestore (music-system-421ee)
├── 📁 users/                    # User profiles (real-time sync)
│   └── {userId}/
│       ├── isLive: boolean
│       ├── photoUrl: string
│       ├── artisticName: string
│       └── ...profile fields
│
├── 📁 posts/                    # Social posts (indexed: authorId, createdAt)
│   └── {postId}/
│       ├── authorId: string
│       ├── mediaUrls: array
│       ├── postType: 'image'|'video'|'carousel'
│       ├── likes: array<userId>
│       └── createdAt: timestamp
│
├── 📁 stories/                  # Stories 24h (indexed: expiresAt, createdAt)
│   └── {storyId}/
│       ├── authorId: string
│       ├── mediaUrl: string
│       ├── mediaType: 'image'|'video'
│       ├── expiresAt: timestamp
│       └── viewers: array<userId>
│
├── 📁 songs/                    # Repertoire
│   └── {songId}/
│       ├── musicianId: string
│       ├── title: string
│       └── artist: string
│
├── 📁 requests/                 # Song requests
│   └── {requestId}/
│       ├── musicianId: string
│       ├── songName: string
│       ├── tipAmount: number
│       └── status: 'pending'|'accepted'|'completed'
│
├── 📁 chats/                    # Conversations (indexed: participants, lastMessageAt)
│   └── {chatId}/
│       ├── participants: array
│       └── messages/ (subcollection)
│
├── 📁 bands/                    # Bands
│   └── {bandId}/
│       ├── leaderId: string
│       ├── subscription: {planId, status, expiresAt}
│       └── members/ (subcollection)
│
├── 📁 events/                   # Events
│   └── {eventId}/
│       ├── ownerId: string
│       ├── questionnaire: {...}
│       └── hiredProviderIds: array
│
└── 📁 services/                 # Service providers
    └── {serviceId}/
        ├── providerId: string
        ├── category: 'artist'|'infrastructure'|'catering'|'security'|'media'
        └── technicalDetails: {...}
```

### PostgreSQL Tables (Backend)

```sql
-- user_profiles table
CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'client',
    subscription_plan VARCHAR(50) DEFAULT 'free',
    avatar_url TEXT,
    nickname VARCHAR(255),
    pix_key VARCHAR(255),
    bio TEXT,
    instagram_url TEXT,
    youtube_url TEXT,
    facebook_url TEXT,
    gallery_urls TEXT[],
    fcm_token TEXT,
    followers_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    is_live BOOLEAN DEFAULT FALSE,
    live_until TIMESTAMP,
    verification_level VARCHAR(50) DEFAULT 'none',
    professional_level VARCHAR(50),
    min_suggested_cache DECIMAL,
    max_suggested_cache DECIMAL,
    show_professional_badge BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

### MongoDB Collections (Backend)

```javascript
// chat_messages collection
{
  _id: ObjectId,
  chatId: string,
  senderId: string,
  content: string,
  timestamp: Date,
  isRead: boolean
}

// feed_posts collection (for API-based feed)
{
  _id: ObjectId,
  authorId: string,
  mediaUrls: [string],
  caption: string,
  likes: [string],
  createdAt: Date
}
```

---

## Flutter Frontend Architecture

### Clean Architecture Layers

```
lib/
├── core/                        # Shared infrastructure
│   ├── constants/               # App version, constants
│   ├── error/                   # Failure classes
│   ├── services/                # External services
│   └── utils/                   # Utilities (PIX, Cloudinary sanitizer)
│
├── features/                    # Feature modules
│   └── {feature}/
│       ├── data/                # Data layer
│       │   ├── datasources/     # Remote data sources (Firestore, API)
│       │   ├── models/          # Data models (JSON serialization)
│       │   └── repositories/    # Repository implementations
│       ├── domain/              # Business logic
│       │   ├── entities/        # Domain entities
│       │   ├── repositories/    # Repository interfaces
│       │   └── usecases/        # Use cases
│       └── presentation/        # UI layer
│           ├── bloc/            # BLoC state management
│           ├── pages/           # Screen widgets
│           └── widgets/         # Reusable widgets
│
├── injection_container.dart     # GetIt DI configuration
└── main.dart                    # App entry point
```

### Feature Modules (13 total)

| Module | Key Files | Purpose |
|--------|-----------|---------|
| `auth` | profile_page, login_page, registration_page | User auth & profiles |
| `bands` | band_entity, band_repository | Band management |
| `bookings` | booking_entity, budget_cart_bloc | Event bookings |
| `calendar` | - | Schedule management |
| `client_menu` | client_menu_page, song_card | QR code menu for clients |
| `community` | artist_network_page, chat_page, story_player | Social features |
| `events` | event_entity, questionnaire_bloc | Event planning |
| `live` | live_page | Live streaming |
| `musician_dashboard` | dashboard_page, manage_repertoire | Musician tools |
| `service_provider` | service_dashboard, service_registration | Service marketplace |
| `smart_lyrics` | lyrics_bloc | Lyrics integration |
| `song_requests` | song_request_bloc | Song request system |
| `wallet` | - | Financial transactions |

---

## Backend API Architecture

### Controllers (8 endpoints)

| Controller | Route | Purpose |
|------------|-------|---------|
| `ProfileController` | `/api/profile` | User profile CRUD + public profiles |
| `FeedController` | `/api/feed` | Posts and feed |
| `ChatController` | `/api/chat` | Chat messages |
| `StorageController` | `/api/storage` | File uploads (MinIO) |
| `ServiceController` | `/api/service` | Service provider CRUD |
| `WalletController` | `/api/wallet` | Financial transactions |
| `LiveController` | `/api/live` | LiveKit room tokens |
| `MigrationController` | `/api/migration` | Data migration utilities |

### Services Layer

| Service | Storage | Purpose |
|---------|---------|---------|
| `ProfileService` | PostgreSQL | User profile management |
| `MongoFeedService` | MongoDB | Posts and feed |
| `MongoChatService` | MongoDB | Chat messages |
| `MinioStorageService` | MinIO | File storage (S3-compatible) |
| `WalletService` | PostgreSQL | Transactions, balance |
| `ServiceProviderService` | PostgreSQL | Services marketplace |

### Profile API Endpoints

| Method | Route | Auth | Purpose |
|--------|-------|------|---------|
| `GET` | `/api/profile/me` | Required | Get own profile (full data) |
| `GET` | `/api/profile/{userId}` | Anonymous | Get public profile (limited fields) |
| `POST` | `/api/profile` | Required | Create or update profile |

**Public Profile Response** (excludes sensitive data):
```csharp
{ FirebaseUid, Name, AvatarUrl, Bio, IsLive, LiveUntil,
  Nickname, FollowersCount, FollowingCount, VerificationLevel,
  ProfessionalLevel, ShowProfessionalBadge,
  InstagramUrl, YoutubeUrl, FacebookUrl, GalleryUrls }
// Excluded: Email, PixKey, FcmToken, etc.
```

### Authentication
- Firebase JWT tokens validated via ASP.NET Core JWT Bearer
- Token issuer: `https://securetoken.google.com/music-system-421ee`

---

## Feature Modules Deep Dive

### Auth Module

**Purpose**: User authentication, profile management, verification

**Key Components**:
- `AuthBloc`: Handles login, logout, profile updates
- `ProfileViewBloc`: Tracks profile views
- `AuthRepositoryApiImpl`: API-based profile operations with Firestore dual-write
- `AuthRepositoryImpl`: Legacy Firestore-only operations (Google Sign-In with GIS SDK)

**Profile Fields** (35+ fields):
```dart
UserProfile {
  id, email, artisticName, nickname, searchName,
  pixKey, photoUrl, bio,
  instagramUrl, youtubeUrl, facebookUrl,
  galleryUrls, fcmToken,
  followersCount, followingCount, unreadMessagesCount, profileViewsCount,
  isLive, liveUntil, scheduledShows, lastActiveAt,
  birthDate, verificationLevel (none/basic/kycFull),
  isParentalConsentGranted, isDobVisible, isPixVisible,
  profileType, subType, artistScore, professionalLevel,
  minSuggestedCache, maxSuggestedCache, showProfessionalBadge
}
```

### Community Module

**Purpose**: Social network features - posts, stories, chat, following

**Entities**:
```dart
PostEntity {
  id, authorId, authorName, authorPhotoUrl,
  imageUrl, mediaUrls, postType ('image'|'video'|'carousel'),
  caption, likes, createdAt,
  taggedUserIds, collaboratorIds, musicData
}

StoryEntity {
  id, authorId, authorName, authorPhotoUrl,
  mediaUrl, mediaType ('image'|'video'),
  createdAt, expiresAt, viewers,
  effects (StoryEffects), caption
}

MessageEntity { id, senderId, content, timestamp, isRead }
ConversationEntity { id, participants, lastMessage, unreadCount }
```

**Key Pages**:
- `artist_network_page.dart` (56KB) - Main feed, stories, posts
- `chat_page.dart` (25KB) - Direct messaging
- `story_player_page.dart` (26KB) - Story viewing with effects
- `create_post_page.dart` / `create_story_page.dart` - Content creation

### Bands Module

**Purpose**: Band creation, member management, subscriptions

**Entities**:
```dart
BandEntity {
  id, name, slug, leaderId, createdAt,
  subscription: BandSubscriptionEntity {
    planId ('basic_monthly'|'pro_monthly'),
    status ('active'|'past_due'|'canceled'),
    expiresAt
  },
  profile: BandProfileEntity {
    description, genres, mediaLinks, techRiderUrl, biography
  },
  settings: BandSettingsEntity { isPromoted }
}

BandMemberEntity { id, name, role, joinedAt, status }
```

### Service Provider Module

**Purpose**: Marketplace for event services

**Categories** (5 types with specific technical details):
```dart
enum ServiceCategory { artist, infrastructure, catering, security, media }

ServiceEntity {
  id, providerId, name, description,
  category, basePrice, priceDescription,
  status ('pending'|'active'|'rejected'),
  technicalDetails: TechnicalDetails, // Polymorphic
  location, imageUrl, createdAt
}

// Category-specific details:
ArtistDetails { stageMapUrl, repertoireUrl, genre }
InfrastructureDetails { powerRequirements, kva, vehicleHeight, loadInTime }
CateringDetails { menuImageUrls, dietaryTags, needsKitchenOnSite, tastingAvailable }
SecurityDetails { certificationUrls, hasWeapon, uniformType, staffPerShift }
MediaDetails { portfolioUrls, equipmentList, deliveryTimeDays }
```

### Events Module

**Purpose**: Event planning with questionnaire and budget tracking

**Entities**:
```dart
EventEntity {
  id, ownerId, title, description,
  eventDate, status ('planning'|'confirmed'|'cancelled'|'completed'),
  questionnaire: EventQuestionnaire,
  hiredProviderIds, budgetLimit, currentExpenses, createdAt
}

EventQuestionnaire {
  // Objectives
  primaryObjective, targetAudience, eventSoul, monetizationStrategy,
  // Logistics
  technicalEquip, staff, catering,
  // Legal
  hasPermits, hasInsurance, hasContracts,
  // Marketing
  visualIdentity, ticketPlatform, marketingPlan
}
```

### Client Menu Module

**Purpose**: QR code scanning for song requests

**Flow**:
1. Client scans musician's QR code
2. Opens `ClientMenuPage` with musician's repertoire
3. Searches songs, selects one to request
4. Optionally adds tip (generates PIX QR code)
5. Submits `SongRequest`

**Entities**:
```dart
Song { id, musicianId, title, artist, albumCoverUrl }

SongRequest {
  id, songName, artistName, clientName,
  musicianId, tipAmount, isCustomRequest,
  status ('pending'|'accepted'|'declined'|'completed'),
  createdAt
}
```

### Bookings Module

**Purpose**: Hiring artists/services for events

**Entities**:
```dart
BookingEntity {
  id, targetId (bandId or musicianId),
  targetType ('band'|'musician'),
  contractorId, date,
  status ('pending_approval'|'confirmed'|'completed'|'cancelled'),
  price, notes
}

BudgetRequestEntity { eventId, serviceId, proposedPrice, message }
ServiceContractEntity { bookingId, terms, signedAt, status }
```

---

## Entity Models Reference

### Field Name Mappings (Flutter ↔ Backend API)

| Flutter Field | Backend C# Field | Notes |
|---------------|------------------|-------|
| `id` | `FirebaseUid` | Required for API calls |
| `artisticName` | `Name` | Display name |
| `photoUrl` | `AvatarUrl` | Profile photo |
| `isLive` | `IsLive` | Live status |

**Important**: `UserProfileModel` has two serialization methods:
- `toJson()` - Firestore format (camelCase)
- `toApiJson()` - Backend API format (proper field mapping)
- `fromJson()` - Accepts both `photoUrl` AND `avatarUrl`

---

## State Management (BLoC)

### Key BLoCs

| BLoC | States | Events |
|------|--------|--------|
| `AuthBloc` | `AuthInitial`, `AuthLoading`, `Authenticated`, `Unauthenticated`, `ProfileLoaded` | `LoginRequested`, `LogoutRequested`, `ProfileUpdateRequested` |
| `FeedBloc` | `FeedInitial`, `FeedLoading`, `FeedLoaded`, `FeedError` | `LoadFeed`, `RefreshFeed`, `LikePost` |
| `StoryBloc` | `StoriesLoading`, `StoriesLoaded` | `LoadStories`, `MarkAsViewed` |
| `ChatBloc` | `ChatsLoaded`, `MessagesLoaded` | `LoadChats`, `SendMessage`, `MarkAsRead` |
| `SongRequestBloc` | `RequestsLoaded`, `RequestSubmitted` | `LoadRequests`, `CreateSongRequest`, `UpdateRequestStatus` |
| `BandBloc` | `BandLoaded`, `BandCreated` | `LoadBand`, `CreateBand`, `InviteMember` |
| `EventBloc` | `EventsLoaded`, `EventCreated` | `LoadEvents`, `CreateEvent`, `UpdateQuestionnaire` |

---

## Services & Integrations

### Core Services (`lib/core/services/`)

| Service | File | Purpose |
|---------|------|---------|
| `BackendApiService` | `backend_api_service.dart` | REST API calls to C# backend |
| `BackendStorageService` | `backend_storage_service.dart` | File uploads via API |
| `CloudinaryService` | `cloudinary_service.dart` | Image/video transformations |
| `DeezerService` | `deezer_service.dart` | Music search for repertoire |
| `LiveKitService` | `livekit_service.dart` | WebRTC live streaming |
| `NotificationService` | `notification_service.dart` | FCM push notifications |
| `StorageService` | `storage_service.dart` | Abstract storage interface |

### Backend API Base URL
```dart
static const String baseApiUrl = 'https://136.248.64.90.nip.io/api';
```

---

## Authentication Flow

### Login Methods
1. **Email/Password**: Firebase Auth → Firestore profile → API profile sync
2. **Google Sign-In (Web)**: GIS SDK `renderButton()` → `signInSilently()` → Firebase credential
3. **Google Sign-In (Mobile)**: Traditional `signIn()` popup → Firebase credential

### Google Sign-In (GIS SDK Migration)

The web Google Sign-In was migrated from the deprecated `signIn()` popup to Google Identity Services:

**Web Flow**:
1. `LoginPage.initState()` initializes `GoogleSignInPlugin.initWithParams()`
2. `renderButton()` renders Google's native sign-in button in the UI
3. User clicks → GIS SDK handles auth → `onCurrentUserChanged` listener fires
4. `_handleGoogleSignInWeb()` converts to Firebase credential automatically
5. `signInSilently()` retrieves the account for BLoC processing

**Mobile Flow**: Traditional `GoogleSignIn.signIn()` popup (unchanged)

**Key Files**:
- `web/index.html`: `<meta name="google-signin-client_id">` tag
- `login_page.dart`: `renderButton()` + `_initializeGoogleSignIn()`
- `auth_repository_impl.dart`: `_googleSignIn` instance + `onCurrentUserChanged` listener

**Client ID**: `108435262492-m6as6h713s53k329be92bafmhm88an6g.apps.googleusercontent.com`

### Token Flow
```
Flutter App
    │
    ▼
Firebase Auth (login) ──► idToken
    │
    ▼
API Request with Bearer token ──► Backend validates JWT
    │
    ▼
Backend extracts userId from ClaimTypes.NameIdentifier
```

### Repository Pattern for Auth
```dart
// injection_container.dart
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryApiImpl(
    firebaseAuth: sl(),
    apiService: sl(),
    legacyRepository: AuthRepositoryImpl(  // For Google Sign-In
      firebaseAuth: sl(),
      firestore: sl(),
    ),
  ),
);
```

---

## Data Flow & Dual-Write Pattern

### Problem Solved
The app uses both Firestore (real-time) and Backend API (PostgreSQL). To keep data in sync:

### Dual-Write Pattern
When saving profile via API, also update critical fields in Firestore:

```dart
// In AuthRepositoryApiImpl.updateProfile()
await apiService.post('/profile', data: model.toApiJson());

// Dual-write to Firestore for real-time reads
await FirebaseFirestore.instance
    .collection('users')
    .doc(profile.id)
    .set({
  'isLive': profile.isLive,
  'liveUntil': profile.liveUntil,
  'lastActiveAt': FieldValue.serverTimestamp(),
  'photoUrl': profile.photoUrl,
  'artisticName': profile.artisticName,
  'nickname': profile.nickname,
  'bio': profile.bio,
}, SetOptions(merge: true));
```

### When to Use Each Data Source

| Data | Source | Reason |
|------|--------|--------|
| Profile (own) | API | Source of truth for full profile |
| Profile (isLive for visitors) | Firestore | Real-time updates via StreamBuilder |
| Posts, Stories | Firestore | Real-time feed updates |
| Chat messages | MongoDB via API | Persistent storage |
| File uploads | MinIO via API | S3-compatible storage |
| Songs, Requests | Firestore | Real-time for musicians |

---

## Known Issues & Patterns

### Common Pitfalls

1. **Field Name Mismatch**
   - `toJson()` uses Flutter field names
   - `toApiJson()` uses Backend field names
   - `fromJson()` should check BOTH (e.g., `json['photoUrl'] ?? json['avatarUrl']`)

2. **Timestamp Handling**
   - Firestore: `Timestamp` objects
   - API: ISO 8601 strings
   - Always convert appropriately in model methods

3. **Profile Save Flow**
   - `ProfileUpdateRequested` event → `AuthBloc` → `AuthRepository.updateProfile()`
   - API save + Firestore dual-write

4. **Google Sign-In**
   - Must use `legacyRepository` parameter in `AuthRepositoryApiImpl`
   - API implementation throws "not implemented" without it
   - Web uses GIS SDK (`renderButton` + `signInSilently`), mobile uses `signIn()`
   - `LoginPage` initializes plugin with `initWithParams()` before rendering button

5. **COOP Policy (Cross-Origin-Opener-Policy)**
   - Google Sign-In popup requires `same-origin-allow-popups` header
   - Set globally in `nginx.conf` HTTPS server block
   - Without this, `window.closed` calls are blocked by browser

6. **Flutter Web `!isDisposed` Assertion**
   - `EngineFlutterView` disposed assertion can crash Flutter Web
   - Global error guard in `main.dart` suppresses this via `FlutterError.onError`
   - Also handled at platform level via `PlatformDispatcher.instance.onError`

7. **SignalR WebSocket Connectivity**
   - `/chathub` location in nginx has WebSocket upgrade headers
   - `/api/` block also needs `Upgrade`/`Connection` headers for SignalR negotiate

### Important Files to Check When Debugging

| Issue | Check These Files |
|-------|-------------------|
| Profile not saving | `auth_repository_api_impl.dart`, `user_profile_model.dart` |
| Photo disappearing | `fromJson()` field names, dual-write fields |
| Live status not showing | Firestore dual-write, `client_menu_page.dart` StreamBuilder |
| Login issues | `injection_container.dart` (legacyRepository) |
| API 400 errors | `toApiJson()` field mappings |
| Google Sign-In broken (web) | `login_page.dart` init, `web/index.html` meta tag, `nginx.conf` COOP |
| WebSocket/SignalR failing | `nginx.conf` upgrade headers, `/chathub` and `/api/` blocks |
| Flutter Web crash on dispose | `main.dart` error guards (`FlutterError.onError`) |
| Public profile 404 | `ProfileController.cs` (GET `{userId}`), `auth_repository_api_impl.dart` |

---

## File Structure Reference

### Key Directories

```
c:\Users\user\geomar-proj\music_system\
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_version.dart          # Current: 1.1.0 build 136
│   │   ├── services/
│   │   │   ├── backend_api_service.dart  # API base URL
│   │   │   ├── cloudinary_service.dart
│   │   │   └── notification_service.dart
│   │   └── utils/
│   │       └── pix_utils.dart            # PIX QR code generation
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/user_profile_model.dart    # toJson, toApiJson, fromJson
│   │   │   │   └── repositories/
│   │   │   │       ├── auth_repository_api_impl.dart # API + dual-write
│   │   │   │       └── auth_repository_impl.dart     # Firestore only
│   │   │   ├── domain/entities/user_profile.dart     # 35+ fields
│   │   │   └── presentation/
│   │   │       ├── bloc/auth_bloc.dart
│   │   │       └── pages/profile_page.dart           # 66KB
│   │   │
│   │   ├── community/
│   │   │   ├── domain/entities/
│   │   │   │   ├── post_entity.dart
│   │   │   │   └── story_entity.dart
│   │   │   └── presentation/pages/
│   │   │       ├── artist_network_page.dart          # 56KB - Main feed
│   │   │       └── chat_page.dart                    # 25KB
│   │   │
│   │   ├── client_menu/
│   │   │   └── presentation/
│   │   │       ├── pages/client_menu_page.dart       # QR code menu
│   │   │       └── widgets/song_card.dart            # isMusicianLive check
│   │   │
│   │   ├── musician_dashboard/
│   │   │   └── presentation/pages/
│   │   │       ├── musician_dashboard_page.dart
│   │   │       └── manage_repertoire_page.dart
│   │   │
│   │   └── ... (10 more feature modules)
│   │
│   ├── injection_container.dart           # 427 lines - All DI config
│   └── main.dart                          # App entry, Firebase init, global error guards
│
├── backend/
│   ├── docker-compose.yml                 # 6 services
│   ├── nginx.conf                         # Proxy config (COOP + WebSocket upgrade)
│   └── MusicSystem.Backend/
│       ├── Program.cs                     # ASP.NET Core config
│       ├── Controllers/                   # 8 controllers
│       ├── Models/
│       │   └── UserProfile.cs             # Backend profile model
│       ├── Services/                      # 13 services
│       └── Hubs/ChatHub.cs                # SignalR
│
├── pubspec.yaml
├── firebase.json                          # Hosting config
└── firestore.rules                        # Security rules
```

### Version Control
- **Current Build**: 136
- **App Version**: 1.1.0
- **Version File**: `lib/core/constants/app_version.dart`

---

## Quick Reference Commands

### Build & Deploy Flutter Web
```powershell
# Build Flutter Web
flutter build web --release --no-tree-shake-icons

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy Firestore rules
firebase deploy --only firestore:rules
```

### Backend Deployment (Oracle Cloud Server)

**Server Info**:
- **IP**: `136.248.64.90`
- **User**: `ubuntu` (NOT root)
- **SSH Key**: `backend/ssh-key-2026-01-29.key`
- **Backend Directory**: `/home/ubuntu/cardapio-musical`

**SSH Connection (from project root)**:
```powershell
# Connect to server
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90
```

**Upload Updated Files (from Windows)**:
```powershell
# Example: Upload ProfileController.cs using pipe
type "backend\MusicSystem.Backend\Controllers\ProfileController.cs" | ssh -i "backend\ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "sudo tee /home/ubuntu/cardapio-musical/MusicSystem.Backend/Controllers/ProfileController.cs > /dev/null"
```

**Rebuild Backend Container**:
```powershell
# Build backend image only
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "cd /home/ubuntu/cardapio-musical && sudo docker compose build backend"

# Restart backend with force recreate (fixes name conflicts)
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "cd /home/ubuntu/cardapio-musical && sudo docker compose up -d backend --force-recreate"

# View logs
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "sudo docker logs -f music_system_api"
```

**Full Restart All Services** (use with caution):
```powershell
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "cd /home/ubuntu/cardapio-musical && sudo docker compose down --remove-orphans && sudo docker compose up -d"
```

**Check Container Status**:
```powershell
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
```

**Test API Endpoint from Server**:
```powershell
ssh -i "backend/ssh-key-2026-01-29.key" ubuntu@136.248.64.90 "curl -s http://localhost:5000/api/profile/test-id"
```

### Docker Compose Services
| Service | Container Name | Port |
|---------|----------------|------|
| postgres | music_system_postgres | 5432 |
| mongodb | music_system_db | 27017 |
| minio | music_system_minio | 9000, 9001 |
| backend | music_system_api | 5000→8080 |
| livekit | music_system_livekit | 7880 |
| nginx | music_system_nginx | 80, 443 |
| mediamtx | - | RTSP streams |

---

## Roadmap & Gap Analysis

> Source: `PLANEJAMENTO_SISTEMA.md`

### ✅ Completed Modules
| Module | Status | Notes |
|--------|--------|-------|
| Feed de Postagens | ✅ Done | `features/community` |
| Stories (24h) | ✅ Done | `story_upload_bloc.dart` |
| Criação de Banda | ✅ Done | `features/bands` |
| Repertório/Letras | ✅ Done | `features/smart_lyrics` |
| Peça sua Música | ✅ Done | `features/song_requests` |
| Chat | ✅ Done | SignalR + MongoDB |

### 🚧 In Progress / To Do
| Feature (Miro) | Code Location | Priority |
|----------------|---------------|----------|
| **Carteira & Cachê** | `wallet` (skeleton) | **CRITICAL** - Needed for monetization |
| **Live Remunerada** | `live` | High - Stable video + payment gate |
| **Dashboard IA** | `musician_dashboard` | Medium - Add real insights |

### Implementation Phases

**Phase 1: Financial Foundation (Wallet)**
1. Create entities: `Wallet`, `Transaction`
2. Implement price/service tables
3. Build balance screen (`features/wallet`)

**Phase 2: Business (Agenda & Bookings)**
1. Refine `Calendar` for date blocking
2. Create "Send Proposal" flow (contractor side)
3. Create "Accept Proposal" flow (artist side)

**Phase 3: Paid Live (VIP)**
1. Stabilize live streaming
2. Add payment verification check

---

## Legal Compliance (Lei Felca & LGPD)

> Source: `adequa.md`

### Age Verification Requirements

The system must implement:

1. **Age Gate**: Date of birth collection at registration
2. **Parental Consent**: For users under 16 years old
   - Email to parent/guardian
   - Click-to-approve link
   - Audit log of consent attempt
3. **KYC for Artists**: Full identity verification for monetization
   - Gov.br integration or document capture
   - "Identidade Verificada" badge

### Content Moderation (Duty of Care)

- **AI Integration**: Computer vision APIs for content scanning
- **Quarantine System**: Suspicious content held for review
- **User Appeal**: "Solicitar Revisão Humana" button
- **Audit Logs**: All moderation actions recorded with:
  - User ID, Action, Method (AI/Human/Gov.br), Proof token

### Privacy Strategy

- Allow users to **browse before verification** (engagement first)
- Only require heavy verification when user tries to interact
- Focus AI scanning on new accounts and low-reputation users

### Entities to Add
```dart
// Future: UserProfile additions
verificationLevel: VerificationLevel (none/basic/kycFull)
birthDate: DateTime
isParentalConsentGranted: bool
parentEmail: String?
kycDocumentId: String?
```

---

## Live Streaming Configuration

> Source: `contexto_v39.md`, `contexto_v40.md`

### Zego SDK Setup

**Package Versions** (Stable Downgrade Strategy):
```yaml
dependencies:
  zego_uikit_prebuilt_live_streaming: 3.10.0  # Stable
  zego_uikit_signaling_plugin: 2.6.0
  zego_express_engine: ^3.23.0
```

**Configuration Files**:
- `web/index.html`: Zego script tag
- `lib/core/secrets/zego_secrets.dart`: Credentials
  - AppID: `1166253932`
  - ServerUrl: `wss://webliveroom1166253932-api.coolzcloud.com/ws`

### Audio Configuration for Musicians

**Problem**: Default ANS/AGC distorts musical instruments.

**Solution**: Disable audio processing for music mode:
```dart
// TODO: Requires ZegoExpressEngine native access
// config.audioConfig = ZegoLiveStreamingAudioConfig(
//   enableANS: false,  // Acoustic Noise Suppression
//   enableAGC: false,  // Automatic Gain Control
//   enableAEC: true,   // Keep Echo Cancellation
// );
```

**Validation**: Look for log `"🎸 Zego Audio Config: MUSIC MODE ENABLED"`

---

## Recent Updates History

> Source: `TASKS_UPDATE.md`

### Version 136 (Current)
- ✅ Nginx COOP header (`same-origin-allow-popups`) for Google Sign-In
- ✅ Nginx WebSocket upgrade headers on `/api/` block for SignalR
- ✅ Global error guard in `main.dart` (suppresses `!isDisposed` assertion)
- ✅ Robust Google Sign-In initialization in `LoginPage` (async init + loading state)
- ✅ `AuthRepositoryImpl` uses `_googleSignIn` field + `onCurrentUserChanged` listener

### Version 134
- ✅ Google Sign-In migration to GIS SDK (`renderButton` for web)
- ✅ Public profile endpoint `/api/profile/{userId}` added (AllowAnonymous)
- ✅ Profile photo persistence fix (`fromJson` accepts both `photoUrl`/`avatarUrl`)
- ✅ Live status visible to visitors (Firestore dual-write sync)
- ✅ API field name mapping fixed (`toApiJson()` method)
- ✅ Expanded dual-write: photoUrl, artisticName, nickname, bio

### Version 21 Features
- **Infinite Scroll**: Smooth pagination in `ArtistNetworkPage`
- **Shimmer Effect**: Skeleton loading placeholders
- **Optimistic Like**: Instant UI reaction with 500ms debounce
- **"Tocando Agora"**: 
  - Toggle in profile
  - Golden pulsing ring + "TOCANDO" badge
- **Online Status**: Green dot if active in last 5 minutes

---

## Contacts & Resources

- **Firebase Console**: https://console.firebase.google.com/project/music-system-421ee
- **Hosting URL**: https://music-system-421ee.web.app
- **API Base**: https://136.248.64.90.nip.io/api
- **MinIO Console**: https://136.248.64.90.nip.io:9001

---

## Related Documentation Files

| File | Purpose |
|------|---------|
| `PLANEJAMENTO_SISTEMA.md` | Gap analysis and implementation roadmap |
| `PROJECT_STRUCTURE.md` | Directory structure overview |
| `TASKS_UPDATE.md` | Recent feature updates |
| `contexto_v39.md` / `contexto_v40.md` | Zego live streaming setup |
| `adequa.md` | Legal compliance (Lei Felca, LGPD) |

---

> **Note for AI Assistants**: When starting a new conversation about this project, reference this document to understand the system architecture. Pay special attention to the [Data Flow & Dual-Write Pattern](#data-flow--dual-write-pattern) section when debugging profile-related issues, and the [Field Name Mappings](#field-name-mappings-flutter--backend-api) when dealing with API calls.
