/* ============================================================
   BARBERÍA TRIADA · config.js
   Conexión a Supabase. La anon/publishable key es PÚBLICA por diseño
   (la seguridad la da la RLS, no esconder la key) → es correcto que
   viva acá y se publique en GitHub Pages.

   ❌ NUNCA pongas acá la "Database Password" ni la "service_role key".
   ============================================================ */
window.BT_CONFIG = {
  supabaseUrl:     'https://afpzmqasodpxvhxixwgo.supabase.co',
  supabaseAnonKey: 'sb_publishable_V94HmhBdX2R7tTY6mNsX0Q_6gd-Pg1_'
};
