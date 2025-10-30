# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Name:** III Encuentro Anual - esPublico (Congress App)
**Type:** Single-Page Application (SPA) for conference management
**Stack:** Vanilla HTML/CSS/JavaScript + Supabase (PostgreSQL + Storage)
**Status:** Active Development (v1.1.0-beta)

## Architecture

### Core Technology Stack
- **Frontend:** Single HTML file (`index.html`) with embedded CSS/JS (~5000+ lines)
- **Backend:** Supabase PostgreSQL with REST API
- **Database:** 27+ interconnected tables with Row Level Security (RLS)
- **Storage:** Supabase Storage for images + localStorage fallback
- **Auth:** Supabase Auth (prepared but not fully implemented)

### Critical Files
```
index.html                    # Main SPA - all UI, CSS, and JS in one file
congress_app_schema.sql       # Complete database schema
poster_voting_schema.sql      # Poster voting system schema
security_fixes.sql            # RLS policies and security hardening
verify_security.sql           # Security audit script
```

### Database Configuration
- **Supabase credentials** are hardcoded in `index.html:3317-3318`
- **Not using `.env`** - credentials are directly in the HTML file
- RLS is enabled on all 20 public tables with 40+ granular policies
- 6 security-hardened functions with fixed `search_path`
- 3 views with `security_invoker = true`

## Development Commands

### Running Locally
```bash
# Python (recommended)
python -m http.server 8000

# Node.js
npx serve .

# PHP
php -S localhost:8000
```

Then open `http://localhost:8000` in your browser.

### Database Deployment
```bash
# Apply schema to Supabase (via SQL Editor or psql)
# 1. Run congress_app_schema.sql first (base schema)
# 2. Run poster_voting_schema.sql (poster voting feature)
# 3. Run security_fixes.sql (RLS hardening)
# 4. Run verify_security.sql (audit check)
```

### Git Workflow (Semi-Automated)
The project uses Claude Code hooks configured in `.claude/settings.local.json`:

- **On session start:** `git pull` (auto-sync)
- **On session end:** `git add .` + `git status` (auto-stage)

**Manual steps required:**
```bash
git commit -m "descriptive message"
git push
```

## Key Features & Implementation

### 1. Agenda System
- 3-day conference schedule (5-7 November 2025)
- Individual day selector buttons (no "view all" option)
- Unified turquoise color scheme for all day headers and active buttons
- Day 1 visible by default, Days 2-3 hidden (`display: none`)
- Session types: keynote, talk, workshop, break, networking
- Title positioned outside `.section` container for consistency
- Function: `filterDay(day)` at `index.html:~4032`

### 2. Information of Interest (Locations)
- Interactive maps section with Google Maps embeds
- Two subsections:
  - **Training Spaces**: Aula Escenario, Aula 1, Aula 2
  - **Important Locations**: Congress venue, Gala dinner, esPublico HQ
- Each location card includes: title, address, embedded map, Google Maps link
- No navigation data collected (privacy-first)
- Redirects to user's default maps app

### 3. Attendee Registration
- Form in welcome screen with name + email
- Checkbox for legal notice acceptance (required)
- Dual storage: Supabase `attendees` table + localStorage fallback
- Function: `submitWelcome()` at `index.html:~3400`

### 4. Competitive Voting System (Ponencias)
- Card-based design with title, subtitle, author, organization
- Scoring: 5, 3, 2, 1 points (unique per vote)
- Multi-select interface with single submit
- Real-time results screen accessible via `?results` or `#results`
- Auto-refresh every 2 minutes (120 seconds) to prevent flicker
- Winner badge with animated gold styling
- Functions: `submitVotes()`, `loadVotingResults()` at `index.html:~3600-3800`

### 5. Poster Voting System
- Maximum 3 votes per user/device
- Device fingerprinting for anonymous voting prevention
- Gallery with thumbnail cards + full-image modal
- Winner badge positioned in top-right corner (floating, not inline)
- Results screen: `?poster-results` or `#poster-results`
- Auto-refresh every 2 minutes (120 seconds)
- State management: `posterVotingState` object at `index.html:~3936`
- Validation trigger: `validate_max_poster_votes` (database-level)

### 6. Tags/Ideas System
- Free-text input with visual display
- Hybrid storage (Supabase + localStorage)
- Real-time tag cloud visualization in separate files (`tagcloud.html`)

## Critical Implementation Details

### URL Routing (Hash-based SPA)
```javascript
// Screen switching via hash change
window.location.hash = '#screen-name';

// Public results screens (no auth required)
#results          → Voting results (talks)
#poster-results   → Poster voting results
```

### Supabase Client Initialization
Located at `index.html:3317-3319`:
```javascript
const supabaseUrl = 'https://dacpkbftkzwnpnhirgny.supabase.co';
const supabaseKey = 'eyJ...'; // Anonymous key
const supabaseClient = supabase.createClient(supabaseUrl, supabaseKey);
```

### State Management
Global objects for each feature:
- `posterVotingState` - Poster voting state (line ~3936)
- Form validation states in respective screen functions
- No framework - pure vanilla JS state management

### Security Model
- **Current:** Anonymous access with RLS policies (temporary)
- **Future:** Full Supabase Auth with authenticated users
- Device fingerprinting prevents duplicate anonymous votes
- Triggers validate vote limits at database level
- All functions use `SET search_path = public` to prevent schema poisoning
- All views use `security_invoker = true` to prevent privilege escalation

## Visual Design

### Color Palette (Corporate Teal/Turquoise)
```css
--color-primary: #00D9C0;        /* Turquoise (main accent) */
--color-primary-dark: #00B8A3;
--color-secondary: #006B7D;      /* Teal (dark) */
--color-secondary-dark: #005F73;
--color-teal: #0B7A8F;           /* Corporate teal */
--color-cyan-bright: #00F5E0;    /* Bright turquoise */
```

### Menu Icons
- 🗓️ Agenda (spiral notebook)
- 📍 Information of Interest (location pin)
- 📝 Register Attendance
- 🏷️ Tag/Label
- 🗣️ Vote Ponencias (speaking head - oral presentations)
- 📑 Vote Posters (stacked pages - written documents)

### Background
Complex gradient system with:
- Multiple radial gradients overlaid
- Fixed `::before` pseudo-element with gradient overlay
- Fixed `::after` pseudo-element with blur effect at bottom
- All content has `position: relative; z-index: 1;` to appear above background

### Responsive Design
- Mobile-first approach
- Touch-friendly buttons (min 44px)
- Viewport meta tag configured
- Cards adapt to screen width

## Common Tasks

### Updating Supabase Credentials
1. Edit `index.html:3317-3318`
2. Update both `supabaseUrl` and `supabaseKey`
3. Test connection by checking browser console for errors

### Adding a New Screen
1. Create HTML structure in `index.html` with class `screen` and unique ID
2. Add navigation button with `onclick="showScreen('new-screen-id')"`
3. Add screen-specific styles in `<style>` section
4. Implement screen logic in `<script>` section
5. Initialize data loading in screen's entry function

### Modifying Voting Rules
- Talk voting scores: Search for `const scores = [5, 3, 2, 1]` (line ~3600)
- Poster vote limit: Change `maxVotes: 3` in `posterVotingState` (line ~3936)
- Auto-refresh intervals: Currently set to 120000ms (2 minutes) for both voting systems

### Updating Location Maps
1. Locations are in `locations-screen` section
2. Two subsections: `.locations-section` (Training Spaces and Important Locations)
3. Each location card has: title, address, Google Maps embed, and direct link
4. Update coordinates in `href="https://maps.google.com/?q=..."` links
5. Update embedded iframe `src` with proper Google Maps embed URL

### Database Schema Changes
1. Write SQL migration script
2. Test in Supabase SQL Editor
3. Update RLS policies if adding new table
4. Run `verify_security.sql` to check for security issues
5. Update `congress_app_schema.sql` with changes for future deployments

## Testing Strategy

### Current Testing
- Manual testing on multiple devices
- Browser console error monitoring
- Supabase dashboard for data verification
- Security audit via Supabase Security Advisor

### Security Verification
```bash
# Run in Supabase SQL Editor
\i verify_security.sql
\i check_all_rls_status.sql
```

Expected: 0 errors, 0 warnings, 0 suggestions

## Known Issues & Limitations

1. **No automated tests** - Manual testing only
2. **Single HTML file** - ~5000 lines can be difficult to navigate
3. **Hardcoded credentials** - Supabase keys in HTML (should use environment variables in production)
4. **No offline mode** - Partial localStorage fallback but not full PWA
5. **Anonymous voting only** - Full auth system prepared but not integrated

## Future Enhancements (Documented but Not Implemented)

- Speaker profile pages
- Push notifications
- Venue maps and locations
- Networking connections between attendees
- Downloadable resources
- Feedback surveys
- PWA with service worker
- Complete offline mode with sync

## Important Context for AI Assistants

1. **Single-file architecture**: All CSS, HTML, and JS are in `index.html`. Don't suggest splitting unless explicitly requested.

2. **No build process**: Direct browser execution. No webpack, vite, or bundler. Minification is manual for production.

3. **RLS is critical**: Any database changes MUST include RLS policies. Run security verification after schema changes.

4. **Device fingerprinting**: Used for anonymous voting. Generated from browser characteristics and stored in localStorage.

5. **Dual storage pattern**: Most features save to Supabase first, fall back to localStorage on error. This is intentional.

6. **Hash-based routing**: Use `window.location.hash` for navigation. No SPA framework or router library.

7. **Screen management**: Single function `showScreen(screenId)` controls all view transitions. Maintains active state in `currentScreen` variable.

8. **Auto-refresh patterns**: Results screens use `setInterval` with state management to prevent flicker during updates. Always check existing data before re-rendering. Current interval: 120000ms (2 minutes).

9. **Session management**: Inline scripts check `localStorage` before showing welcome overlay. If session exists, overlay stays hidden and user greeting appears immediately. Function: `checkExistingSession()`.

10. **Legal notice**: Updated to include maps functionality with explicit "no tracking" guarantee. Maps redirect to user's default app without collecting navigation data.

11. **UI consistency**: Titles should be outside `.section` containers, aligned with other sections. Active button states use turquoise gradient (#00D9C0 → #00F5E0) consistently across all features.

## Last Updated

**Date:** 2025-10-27
**Version:** 1.1.0-beta
**Security Status:** Supabase Security Advisor - 100% Clean (0 errors, 0 warnings)
