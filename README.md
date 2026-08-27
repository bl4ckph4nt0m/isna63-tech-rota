# ISNA63 Tech Rota

Drag-and-drop volunteer scheduler for the ISNA63 tech team covering breakouts, film festival, and Qira'at on Sat 5 & Sun 6 September. Single static HTML page. Assignments sync live across every viewer through Supabase.

## Deploy

### 1. Create the Supabase project

1. Go to https://supabase.com and create a new project (free tier is fine).
2. Once it's ready, open the **SQL Editor** and run:

   ```sql
   create table if not exists rota (
     id int primary key,
     state jsonb not null default '{}'::jsonb,
     updated_at timestamptz not null default now()
   );

   insert into rota (id, state) values (1, '{}'::jsonb)
   on conflict (id) do nothing;

   alter table rota enable row level security;

   create policy "rota_read"   on rota for select using (true);
   create policy "rota_insert" on rota for insert with check (true);
   create policy "rota_update" on rota for update using (true) with check (true);

   -- Live sync across devices
   alter publication supabase_realtime add table rota;
   ```

3. In **Project Settings → API**, copy:
   - **Project URL** (e.g. `https://abcxyz.supabase.co`)
   - **anon public** key

### 2. Fill in the config

Open `index.html` and replace the placeholders near the top:

```html
<script>
  window.APP_CONFIG = {
    SUPABASE_URL:      'https://YOUR-PROJECT.supabase.co',
    SUPABASE_ANON_KEY: 'YOUR-ANON-KEY',
    PASSCODE:          'change-me',
  };
</script>
```

- `SUPABASE_URL` and `SUPABASE_ANON_KEY` are safe to commit — Supabase's RLS is what protects the data.
- `PASSCODE` is a **soft gate**: it keeps casual visitors out but lives in the client, so treat it as "keep out" signage, not a security boundary. Rotate it by editing this file.

### 3. Deploy to Vercel

1. Push this repo to GitHub (already done if you cloned it).
2. Go to https://vercel.com/new and import the repo.
3. No build settings needed — it's a static HTML file. Just click **Deploy**.

That's it. Every visitor with the passcode sees the same live rota; changes propagate in ~1 second.

## How it works

- Everything is stored in a single `rota` row (`id = 1`) as JSON.
- On any drag/drop the client debounces (300 ms) then upserts the whole state.
- Realtime subscribes to changes on that row; other devices apply them immediately, skipping their own echo.
- If Supabase can't be reached, the page falls back to localStorage so you can still work; the sync pill in the header shows the current status (`Live`, `Saving`, `Offline`).

## Local edits

Just open `index.html` in a browser — no build step, no dependencies. The Supabase JS client loads from `esm.sh` at runtime.
