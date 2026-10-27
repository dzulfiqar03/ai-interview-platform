# Catatan Masalah dan Mitigasi: ai-interview-platform
 
Dokumen ini merangkum tiga masalah yang ditemukan saat menjalankan `api` (Rails) dan `web` (React + Vite) secara lokal, apa dampaknya bagi pengguna, dan cara mengatasinya. Isinya dimaksudkan sebagai referensi cepat bagi siapa pun yang menemui gejala yang sama.
 
| ID | Masalah | Severity | Layanan | Branch perbaikan |
|----|---------|----------|---------|------------------|
| F1 | Tenant tidak ditemukan, endpoint ber-tenant gagal | P0 | api | `auth/fix-models-success` |
| F2 | Tautan undangan kandidat mengarah ke API | P2 | config | `interview/failure-link-interview` |
| F3 | Skill yang dihapus di form tidak terhapus di database | P2 | web | `fix/assessment-skill-removal`, `fix/vacancies-skills-removal` |
 
---
 
## F1. Tenant tidak ditemukan
 
**Gejala**
 
- Login berakhir `401 Unauthorized`.
- Request ber-tenant dari web menjawab `403` dengan pesan `Tenant not found. Ensure the JWT scheme claim is valid.`
- Di log API, query ke tabel `organizations` berjalan tanpa schema, lalu `default_organization` dicari dengan `id = 0` dan tidak ketemu.
**Penyebab**
 
Model `Organization` membaca tabel `organizations` tanpa schema. Data hasil seed ada di `public.organizations`, sedangkan koneksi memakai `schema_search_path = ai_interview,public`, sehingga model menemukan `ai_interview.organizations` yang kosong.
 
**Dampak**
 
- Pada instalasi bersih, tidak ada endpoint ber-tenant yang bisa dipakai.
- Assessor tidak bisa masuk dan tidak bisa melihat assessment maupun lowongan tenant-nya.
**Mitigasi**
 
Di `api/app/models/organization.rb`, arahkan model ke tabel yang benar:
 
```ruby
self.table_name = 'public.organizations'
```
 
**Verifikasi**
 
- Log SQL membaca `FROM "public"."organizations"`.
- `GET /api/v1/assessments` dengan token valid menjawab `200 OK` dan memakai `tenant_id` yang benar.
- `bundle exec rspec spec/models/organization_spec.rb` lolos.
**Catatan**
 
`public.organizations` dipakai bersama `rakamin-api`. Perlu kesepakatan tim bahwa tabel ini adalah satu-satunya sumber kebenaran data organisasi.
 
---
 
## F2. Tautan undangan kandidat mati
 
**Gejala**
 
Kandidat membuka tautan `/interview/<token>` dan melihat halaman Rails `Routing Error: No route matches [GET] "/interview/<token>"`. Daftar rute di halaman itu hanya berisi `/health` dan `/api/v1/...`.
 
**Penyebab**
 
Tautan undangan dibentuk dari `APP_BASE_URL`. Nilai bawaan di `config/application.yml.sample` adalah `http://localhost:3001`, yaitu port API. Halaman interview kandidat dilayani oleh frontend (Vite, port 5173), bukan oleh API.
 
**Dampak**
 
Kandidat menerima tautan yang tidak bisa dibuka sebelum wawancara dimulai. Bagi kandidat ini adalah kegagalan pertama dan bisa berarti kehilangan kesempatan. Severity naik menjadi P1 jika nilai produksi ternyata sama.
 
**Mitigasi**
 
Arahkan `APP_BASE_URL` ke origin frontend:
 
```yaml
APP_BASE_URL: "http://localhost:5173"
```
 
Di staging dan produksi, isi dengan domain frontend yang sebenarnya.
 
**Verifikasi**
 
Tautan undangan membuka halaman kandidat (judul lowongan, durasi, dan pemeriksaan perangkat: OS dan browser, internet, mikrofon, audio output).
 
**Catatan**
 
`config/application.yml` diabaikan git. Perubahan yang berlaku untuk semua orang harus dibuat di `config/application.yml.sample`. Setiap anggota tim tetap perlu menyalin nilainya ke berkas lokal masing-masing.
 
---
 
## F3. Skill yang dihapus di form tidak terhapus
 
**Gejala**
 
Di form Edit Assessment dan Edit Vacancy, skill yang dibuang dengan tombol X hilang dari layar. Setelah Save, halaman detail tetap menampilkan skill itu. Tab Network tidak menunjukkan request PUT yang membawa penghapusan, dan tidak ada pesan error.
 
**Penyebab**
 
Model dan controller Rails sudah benar. `accepts_nested_attributes_for ... allow_destroy: true` aktif dan strong params mengizinkan `id` serta `_destroy`. Yang salah ada di web: payload simpan dibangun hanya dari skill yang masih ada di form.
 
```ts
// AssessmentEditPage.tsx
assessment_skills_attributes: data.skills.map((s, i) => ({ ...s, display_order: i }))
```
 
Skill yang dibuang lewat `remove(index)` tidak pernah dikirim sebagai `{ id, _destroy: true }`. `VacancyEditPage.tsx` memakai pola yang sama dan tidak punya blok `catch`, sehingga kegagalan simpan juga tidak terlihat.
 
**Dampak**
 
- Perubahan assessor hilang tanpa pemberitahuan.
- Skill lowongan dipakai untuk membandingkan kandidat dengan lowongan (fit/gap). Skill yang tampak sudah dihapus tetapi masih tersimpan membuat perbandingan itu salah, dan tidak ada yang menyadarinya.
**Mitigasi**
 
Bentuk payload lewat satu fungsi murni bersama, `web/src/utils/buildSkillsPayload.ts`, yang membandingkan daftar asli dengan daftar saat ini:
 
```ts
export function buildSkillsPayload(original, current) {
  const keptIds = new Set(current.filter(s => s.id != null).map(s => s.id))
  const removed = original
    .filter(s => s.id != null && !keptIds.has(s.id))
    .map(s => ({ id: s.id, _destroy: true }))
  const kept = current.map((s, i) => ({ ...s, display_order: i }))
  return [...kept, ...removed]
}
```
 
Aturannya:
 
- Skill tersimpan yang dihapus dikirim sebagai `{ id, _destroy: true }`.
- Skill yang dipertahankan tidak pernah ditandai `_destroy`.
- Skill baru (belum punya `id`) yang dihapus sebelum Save tidak dikirim sama sekali.
- `display_order` skill yang tersisa dihitung ulang berurutan.
**Verifikasi**
 
`cd web && npm test` menjalankan tiga tes Vitest untuk fungsi ini. Jalankan dari folder `web`, karena dari root repositori `npm` tidak menemukan `package.json`.