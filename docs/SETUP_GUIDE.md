# Nexon ERP - Cloud Sync Setup Guide

## Overview
Nexon ERP now supports offline-first operation with cloud synchronization. This means:
- **Works offline**: All data is stored locally on your device
- **Auto-sync**: Changes are uploaded when internet is available
- **Multi-device**: Changes on one device appear on others within seconds
- **No data loss**: Local database ensures you never lose data

## Quick Setup

### Step 1: Create Supabase Account
1. Go to [supabase.com](https://supabase.com)
2. Sign up for a free account
3. Create a new project
4. Note your project URL and anon key

### Step 2: Run Database Schema
1. In Supabase Dashboard, go to SQL Editor
2. Copy the contents of `docs/supabase_schema.sql`
3. Run the SQL to create all tables

### Step 3: Configure App
Create a `.env` file in the project root:
```
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Step 4: Build and Deploy
```bash
flutter build web --release --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-key
```

Deploy the `build/web` folder to any static hosting (Netlify, Vercel, Firebase Hosting).

## How Sync Works

### Offline Mode
- App works without internet
- All changes saved to local SQLite database
- Sync queue tracks pending changes

### Online Mode
- Changes uploaded to Supabase every 30 seconds
- Changes from other devices downloaded automatically
- Real-time subscriptions for instant updates

### Conflict Resolution
- Last-write-wins (most recent change takes priority)
- Each record has `updated_at` timestamp for comparison

## Architecture

```
┌─────────────────────────────────────────────┐
│              Flutter PWA                     │
├─────────────────────────────────────────────┤
│  UI Layer (existing widgets)                │
├─────────────────────────────────────────────┤
│  Riverpod State Management                  │
├─────────────────────────────────────────────┤
│  Drift (Local SQLite Database)              │
│  ├── customers, products, suppliers         │
│  ├── invoices, inventory_transactions       │
│  └── sync_queue (pending changes)           │
├─────────────────────────────────────────────┤
│  Sync Engine                                │
│  ├── Upload pending changes                 │
│  ├── Download remote changes                │
│  └── Real-time subscriptions                │
├─────────────────────────────────────────────┤
│  Supabase (Cloud)                           │
│  ├── PostgreSQL database                    │
│  ├── Real-time subscriptions                │
│  └── Authentication                         │
└─────────────────────────────────────────────┘
```

## Service Worker
The included service worker (`web/sw.js`) caches all app assets for offline use:
- App shell cached on first load
- Network-first strategy for data
- Automatic cache updates

## Security
- Row Level Security (RLS) enabled on all tables
- Only authenticated users can access data
- Each company's data is isolated

## Troubleshooting
- **Not syncing**: Check internet connection
- **Data not appearing**: Pull down to refresh or wait 30 seconds
- **Offline indicator**: Yellow bar appears when offline
- **Sync indicator**: Green bar with spinner when syncing