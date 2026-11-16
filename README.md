# Spin & Share — shared spin-the-wheel website

This is a starter website with:
- Shared rooms and room codes
- Participant names
- One-time results (a result is claimed once for the whole room)
- Real-time choice-list updates on connected phones
- Private admin sign-in and spin-history dashboard

## 1. Create the database
1. Create a free project at https://supabase.com/.
2. Open **SQL Editor** in the Supabase dashboard.
3. Paste and run all of `supabase/schema.sql`.
4. In **Authentication > Providers**, enable **Anonymous Sign-Ins**.
5. In **Database > Replication** (or the Realtime settings), enable Realtime for `public.choices`.

## 2. Create your admin account
1. In Supabase, open **Authentication > Users** and create an account using your own email and password (or sign up through the app's auth settings).
2. In SQL Editor, run this, replacing the email:
   `insert into public.admin_users(email) values ('you@example.com');`
3. Keep your admin password private. Do not share the admin account.

## 3. Connect the website
1. In Supabase, open **Project Settings > API**.
2. Copy the **Project URL** and the **anon/public key**.
3. Open `index.html` in a text editor.
4. Replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` near the bottom with those values.
   - The anon/public key is intended for browser use; never put a `service_role` or secret key in this website.

## 4. Publish it
Upload `index.html` to a static host such as Netlify or Vercel, or import this folder into Replit and deploy it as a static website. The Supabase database remains the shared backend.
Then share the published website URL and room code with participants.

## 5. Use it
- Admin: open the Admin / Developer tab, sign in, create a room, and add choices (one per line).
- Share the room code with participants.
- Participants open the site on their own phones, enter their name and room code, and spin.
- Admin can enter the room code in the dashboard to view the results and timestamps.

## Important notes
- The database transaction locks the room while a result is claimed, preventing two phones from receiving the same remaining choice.
- The admin history is private to approved admin accounts.
- This starter version has no participant account verification; participants can type a display name. If you need verified identities, add participant sign-in.
- Do not publish until you have tested with two separate phones/browser sessions.
