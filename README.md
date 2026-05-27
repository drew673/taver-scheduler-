# Taver Group Scheduling Tool

A standalone web app for scheduling jobs, shifts and crew across a full 104-week calendar, with staff directory, digital dockets, SMS/WhatsApp messaging and Supabase cloud sync.

---

## Deploying to Cloudflare Pages (FREE — recommended)

### First deploy
1. Go to **pages.cloudflare.com** and sign up free (no credit card)
2. Click **Create a project → Upload assets**
3. Give your project a name e.g. `taver-scheduler`
4. Drag the entire unzipped `taver-scheduler` folder onto the upload zone
5. Click **Deploy site**
6. Your app is live at `taver-scheduler.pages.dev` (or a custom domain if you have one)

### Updating the app (when new changes come through)
1. Go to your Cloudflare Pages dashboard → your project
2. Click **Create new deployment**
3. Drag the new unzipped folder onto the upload zone
4. Click **Save and Deploy** — live in ~15 seconds, same URL

---

## Files in this package
| File | Purpose |
|------|---------|
| `index.html` | The full app — all logic, styles, forms, PDF export |
| `sw.js` | Service worker — enables offline use once installed |
| `manifest.json` | PWA manifest — allows install to home screen |
| `supabase_setup.sql` | Run once in Supabase SQL Editor to create database tables |
| `README.md` | This file |

---

## Supabase database setup (one-time)

1. Go to your Supabase project → **SQL Editor → New query**
2. Open `supabase_setup.sql`, copy everything, paste and click **Run**
3. You should see a table listing confirming 4 tables were created

### Additional SQL for client contact fields (if not already run)
```sql
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS client_contact TEXT DEFAULT '';
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS client_phone TEXT DEFAULT '';
```

### Supabase Storage buckets (create these manually)
1. Supabase dashboard → **Storage → New bucket**
   - Name: `shifts` → **Public** → Create
2. **New bucket** again
   - Name: `dockets` → **Public** → Create

---

## Install as a mobile app

**iPhone / iPad:**
Open the app URL in Safari → tap the **Share** button → **Add to Home Screen** → Add

**Android:**
Open in Chrome → tap **⋮ menu** → **Add to Home Screen** or **Install app**

Once installed it works fully offline — data syncs when connection is restored.

---

## How data is stored

| Type | Where |
|------|-------|
| Jobs, shifts, personnel | Supabase database (cloud) |
| Staff directory | Supabase database (cloud) |
| Calendar (.ics) files | Supabase Storage — `shifts` bucket |
| Dockets | Supabase Storage — `dockets` bucket |
| Local backup | Browser localStorage (automatic) |

Data syncs across all devices automatically. If offline, the app uses the local backup and syncs when back online. Tap the dot in the top-right corner to manually retry sync.

---

## Backup and restore

**Export all data:**
Top bar → **⋯ menu** → **Export all data** — saves a `.json` file

**Import data:**
Top bar → **⋯ menu** → **Import data** — select your `.json` file

Use this to move data between devices or keep a manual backup.

---

## Key features

- **52-week rolling calendar** — WE47 (2026) through WE52 (2027), Mon–Sun
- **Week grid** — view 3 weeks at a time, scroll forward/back, see shift detail at a glance
- **At a Glance panel** — dashboard overview of upcoming weeks with staffing bars
- **Jobs & shifts** — add jobs with PO, client, site address, map link, client contact
- **Personnel** — RIW number, phone, individual shift times, conflict detection
- **Staff directory** — auto-populated from shifts, searchable, direct WA/SMS buttons
- **Conflict detection** — warns when the same person is rostered on two jobs same day
- **Send crew lists** — personalised SMS or WhatsApp per person with all their shifts, site contact, crew list and Google/Apple calendar links
- **Digital dockets** — per shift: works completed, crew hours, travel hours, LAFHA, assets, comments, client + supervisor signature, exports to PDF
- **PDF export** — crew list per job, weekly report, and signed dockets
- **Supabase cloud sync** — real-time across all devices

---

*Taver Group Scheduling Tool v1.3.0*
