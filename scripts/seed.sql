-- ─────────────────────────────────────────────────────────
-- KopDar — Seed Data
-- ─────────────────────────────────────────────────────────
-- Run after schema migrations.
-- Uses gen_random_uuid() for UUIDs (PostgreSQL 13+).

BEGIN;

-- ══════════════════════════════════════════════════════════
--  ZONES
-- ══════════════════════════════════════════════════════════
INSERT INTO zones (id, name, city, province, status, created_at, updated_at) VALUES
  (gen_random_uuid(), 'Cilandak',       'Jakarta Selatan', 'DKI Jakarta',   'active', NOW(), NOW()),
  (gen_random_uuid(), 'Mampang',        'Jakarta Selatan', 'DKI Jakarta',   'active', NOW(), NOW()),
  (gen_random_uuid(), 'Tebet',          'Jakarta Selatan', 'DKI Jakarta',   'active', NOW(), NOW()),
  (gen_random_uuid(), 'Depok Kota',     'Depok',           'Jawa Barat',    'active', NOW(), NOW()),
  (gen_random_uuid(), 'Bekasi Kota',    'Bekasi',          'Jawa Barat',    'active', NOW(), NOW()),
  (gen_random_uuid(), 'Bogor Kota',     'Bogor',           'Jawa Barat',    'active', NOW(), NOW()),
  (gen_random_uuid(), 'Tangerang Kota', 'Tangerang',       'Banten',        'active', NOW(), NOW()),
  (gen_random_uuid(), 'Kemayoran',      'Jakarta Pusat',   'DKI Jakarta',   'active', NOW(), NOW()),
  (gen_random_uuid(), 'Kelapa Gading',  'Jakarta Utara',   'DKI Jakarta',   'active', NOW(), NOW()),
  (gen_random_uuid(), 'Kembangan',      'Jakarta Barat',   'DKI Jakarta',   'active', NOW(), NOW());

-- ══════════════════════════════════════════════════════════
--  ADMIN USERS (3)
-- ══════════════════════════════════════════════════════════
INSERT INTO users (id, phone, name, role, created_at, updated_at) VALUES
  (gen_random_uuid(), '081100000001', 'Andi Saputra',    'admin', NOW(), NOW()),
  (gen_random_uuid(), '081100000002', 'Siti Rahayu',     'admin', NOW(), NOW()),
  (gen_random_uuid(), '081100000003', 'Dedi Kurniawan',  'admin', NOW(), NOW());

-- ══════════════════════════════════════════════════════════
--  DRIVER USERS (20) + DRIVER PROFILES
-- ══════════════════════════════════════════════════════════
-- 8 pending, 10 approved, 2 rejected

-- ── Pending drivers (8) ───────────────────────────────────
INSERT INTO users (id, phone, name, role, created_at, updated_at) VALUES
  (gen_random_uuid(), '081210000001', 'Budi Santoso',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000002', 'Rina Wati',         'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000003', 'Ahmad Fauzi',       'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000004', 'Dewi Lestari',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000005', 'Eko Prasetyo',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000006', 'Fitri Handayani',   'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000007', 'Gilang Ramadhan',   'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000008', 'Hendra Gunawan',    'driver', NOW(), NOW());

-- ── Approved drivers (10) ─────────────────────────────────
INSERT INTO users (id, phone, name, role, created_at, updated_at) VALUES
  (gen_random_uuid(), '081210000009',  'Indra Lesmana',     'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000010',  'Joko Widodo Putra', 'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000011',  'Kartika Sari',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000012',  'Lukman Hakim',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000013',  'Maya Angelina',     'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000014',  'Nugroho Adi',       'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000015',  'Oktavia Putri',     'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000016',  'Putra Wijaya',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000017',  'Rudi Hartono',      'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000018',  'Sari Dewi',         'driver', NOW(), NOW());

-- ── Rejected drivers (2) ──────────────────────────────────
INSERT INTO users (id, phone, name, role, created_at, updated_at) VALUES
  (gen_random_uuid(), '081210000019', 'Tono Sugiarto',   'driver', NOW(), NOW()),
  (gen_random_uuid(), '081210000020', 'Ulya Mahmudah',   'driver', NOW(), NOW());

-- ── Driver profiles ───────────────────────────────────────
-- Note: user_id references are done via subqueries for portability.
-- In production, use application-level seeding with proper FK IDs.

-- Pending (8)
INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900001', 'Jl. Mampang Prapatan No. 10',  'Jakarta Selatan', 'DKI Jakarta',
  'motor', 'Honda',  'Vario 160',  2024, 'B 1234 KPD', 'Hitam',
  'BCA',     '1234567801', 'BUDI SANTOSO',      'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000001';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900002', 'Jl. Margonda Raya No. 45',     'Depok',           'Jawa Barat',
  'motor', 'Yamaha', 'NMAX 155',   2023, 'B 2345 KPD', 'Merah',
  'Mandiri', '1234567802', 'RINA WATI',         'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000002';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900003', 'Jl. TB Simatupang No. 88',     'Jakarta Selatan', 'DKI Jakarta',
  'mobil', 'Toyota', 'Avanza 2022',2022, 'B 3456 KPD', 'Putih',
  'BRI',     '1234567803', 'AHMAD FAUZI',        'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000003';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900004', 'Jl. Raya Bogor Km. 30',        'Depok',           'Jawa Barat',
  'motor', 'Honda',  'Beat 2023',  2023, 'B 4567 KPD', 'Biru',
  'BCA',     '1234567804', 'DEWI LESTARI',       'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000004';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900005', 'Jl. Bekasi Raya No. 100',       'Bekasi',          'Jawa Barat',
  'motor', 'Suzuki', 'Satria FU',  2021, 'B 5678 KPD', 'Hijau',
  'BNI',     '1234567805', 'EKO PRASETYO',       'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000005';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900006', 'Jl. Cilandak KKO No. 5',        'Jakarta Selatan', 'DKI Jakarta',
  'motor', 'Honda',  'PCX 160',   2024, 'B 6789 KPD', 'Abu-abu',
  'BCA',     '1234567806', 'FITRI HANDAYANI',    'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000006';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900007', 'Jl. Kemang Raya No. 22',        'Jakarta Selatan', 'DKI Jakarta',
  'mobil', 'Honda',  'Brio 2023', 2023, 'B 7890 KPD', 'Merah',
  'Mandiri', '1234567807', 'GILANG RAMADHAN',    'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000007';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900008', 'Jl. Raya Condet No. 33',        'Jakarta Selatan', 'DKI Jakarta',
  'motor', 'Yamaha', 'Aerox 155', 2023, 'B 8901 KPD', 'Kuning',
  'BCA',     '1234567808', 'HENDRA GUNAWAN',     'pending', NULL, NOW(), NOW()
FROM users u WHERE u.phone = '081210000008';

-- Approved (10)
INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900009', 'Jl. Ragunan No. 15',            'Jakarta Selatan', 'DKI Jakarta',
  'motor', 'Honda',  'Vario 125', 2022, 'B 9012 KPD', 'Hitam',
  'BCA',     '1234567809', 'INDRA LESMANA',      'approved', NULL, NOW() - INTERVAL '30 days', NOW()
FROM users u WHERE u.phone = '081210000009';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900010', 'Jl. Pasar Minggu No. 20',       'Jakarta Selatan', 'DKI Jakarta',
  'mobil', 'Daihatsu','Xenia 2022',2022, 'B 0123 KPD', 'Silver',
  'Mandiri', '1234567810', 'JOKO WIDODO PUTRA',  'approved', NULL, NOW() - INTERVAL '25 days', NOW()
FROM users u WHERE u.phone = '081210000010';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900011', 'Jl. Lenteng Agung No. 8',       'Jakarta Selatan', 'DKI Jakarta',
  'motor', 'Yamaha', 'Lexi S',    2023, 'B 1122 KPD', 'Merah',
  'BRI',     '1234567811', 'KARTIKA SARI',       'approved', NULL, NOW() - INTERVAL '20 days', NOW()
FROM users u WHERE u.phone = '081210000011';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900012', 'Jl. Margonda Raya No. 100',     'Depok',           'Jawa Barat',
  'motor', 'Honda',  'Scoopy 2023',2023,'B 2233 KPD', 'Coklat',
  'BCA',     '1234567812', 'LUKMAN HAKIM',       'approved', NULL, NOW() - INTERVAL '18 days', NOW()
FROM users u WHERE u.phone = '081210000012';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900013', 'Jl. Juanda No. 50',             'Depok',           'Jawa Barat',
  'mobil', 'Suzuki', 'Ertiga 2021',2021,'B 3344 KPD', 'Putih',
  'BNI',     '1234567813', 'MAYA ANGELINA',      'approved', NULL, NOW() - INTERVAL '15 days', NOW()
FROM users u WHERE u.phone = '081210000013';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900014', 'Jl. Sultan Agung No. 12',       'Bekasi',          'Jawa Barat',
  'motor', 'Honda',  'Revo Fit',  2021, 'B 4455 KPD', 'Hitam',
  'BCA',     '1234567814', 'NUGROHO ADI',        'approved', NULL, NOW() - INTERVAL '12 days', NOW()
FROM users u WHERE u.phone = '081210000014';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900015', 'Jl. Raya Narogong No. 77',      'Bekasi',          'Jawa Barat',
  'motor', 'Yamaha', 'Mio M3',    2022, 'B 5566 KPD', 'Biru',
  'Mandiri', '1234567815', 'OKTAVIA PUTRI',      'approved', NULL, NOW() - INTERVAL '10 days', NOW()
FROM users u WHERE u.phone = '081210000015';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900016', 'Jl. Dewi Sartika No. 8',        'Jakarta Timur',   'DKI Jakarta',
  'motor', 'Honda',  'CB150R',    2023, 'B 6677 KPD', 'Merah',
  'BCA',     '1234567816', 'PUTRA WIJAYA',       'approved', NULL, NOW() - INTERVAL '8 days', NOW()
FROM users u WHERE u.phone = '081210000016';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900017', 'Jl. KH Abdullah No. 45',        'Jakarta Pusat',   'DKI Jakarta',
  'mobil', 'Toyota', 'Calya 2022',2022, 'B 7788 KPD', 'Abu-abu',
  'BRI',     '1234567817', 'RUDI HARTONO',       'approved', NULL, NOW() - INTERVAL '5 days', NOW()
FROM users u WHERE u.phone = '081210000017';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900018', 'Jl. Pluit Raya No. 10',         'Jakarta Utara',   'DKI Jakarta',
  'motor', 'Yamaha', 'Fazzio',    2024, 'B 8899 KPD', 'Krem',
  'BCA',     '1234567818', 'SARI DEWI',          'approved', NULL, NOW() - INTERVAL '3 days', NOW()
FROM users u WHERE u.phone = '081210000018';

-- Rejected (2)
INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900019', 'Jl. Pahlawan No. 99',           'Bekasi',          'Jawa Barat',
  'motor', 'Honda',  'Vario 110', 2015, 'B 9900 KPD', 'Merah',
  'BCA',     '1234567819', 'TONO SUGIARTO',      'rejected', 'Foto KTP tidak jelas, silakan upload ulang dengan pencahayaan yang baik', NOW() - INTERVAL '7 days', NOW()
FROM users u WHERE u.phone = '081210000019';

INSERT INTO drivers (id, user_id, nik, address, city, province,
  vehicle_type, vehicle_brand, vehicle_model, vehicle_year, vehicle_plate, vehicle_color,
  bank_name, bank_account, bank_holder, status, rejection_reason, created_at, updated_at)
SELECT gen_random_uuid(), u.id,
  '3275010101900020', 'Jl. Raya Serpong No. 150',      'Tangerang',       'Banten',
  'mobil', 'Daihatsu','Sigra 2020',2020, 'B 0011 KPD', 'Putih',
  'Mandiri', '1234567820', 'ULYA MAHMUDAH',      'rejected', 'NIK tidak sesuai dengan foto KTP, mohon periksa kembali', NOW() - INTERVAL '4 days', NOW()
FROM users u WHERE u.phone = '081210000020';

-- ── Platform associations ─────────────────────────────────
INSERT INTO driver_platforms (driver_id, platform_name)
SELECT d.id, p.name
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN (VALUES ('gojek'), ('grab'), ('shopeefood'), ('maxim'), ('indrive')) AS p(name)
WHERE u.phone IN ('081210000001','081210000009','081210000010','081210000011','081210000012')
  AND p.name IN ('gojek','grab');

INSERT INTO driver_platforms (driver_id, platform_name)
SELECT d.id, p.name
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN (VALUES ('gojek'), ('grab'), ('shopeefood')) AS p(name)
WHERE u.phone IN ('081210000002','081210000003','081210000013','081210000014')
  AND p.name IN ('gojek','grab','shopeefood');

INSERT INTO driver_platforms (driver_id, platform_name)
SELECT d.id, 'gojek'
FROM drivers d JOIN users u ON d.user_id = u.id
WHERE u.phone IN ('081210000004','081210000005','081210000006','081210000007','081210000008',
                   '081210000015','081210000016','081210000017','081210000018','081210000019','081210000020');

-- ══════════════════════════════════════════════════════════
--  SAMPLE TRANSACTIONS (for approved drivers)
-- ══════════════════════════════════════════════════════════
-- Income entries for the last 7 days
INSERT INTO transactions (id, driver_id, type, amount, description, platform, category, created_at)
SELECT gen_random_uuid(), d.id, 'income', (floor(random()*300000)+50000)::int,
  'Penghasilan narik', p.name, 'income', NOW() - (n || ' days')::interval
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN generate_series(0, 6) AS n
CROSS JOIN LATERAL (VALUES ('gojek'),('grab')) AS p(name)
WHERE d.status = 'approved'
  AND random() > 0.3;

-- Expense entries
INSERT INTO transactions (id, driver_id, type, amount, description, category, created_at)
SELECT gen_random_uuid(), d.id, 'expense', (floor(random()*50000)+10000)::int,
  e.descr, e.cat, NOW() - (n || ' days')::interval
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN generate_series(0, 6) AS n
CROSS JOIN LATERAL (VALUES
  ('Bensin','fuel'), ('Makan siang','food'), ('Parkir','parking'), ('Pulsa data','other')
) AS e(descr, cat)
WHERE d.status = 'approved'
  AND random() > 0.5;

-- ══════════════════════════════════════════════════════════
--  SAVINGS GOALS
-- ══════════════════════════════════════════════════════════
INSERT INTO savings (id, driver_id, goal_name, target_amount, current_amount, daily_amount, status, created_at, updated_at)
SELECT gen_random_uuid(), d.id, s.goal, s.target, (s.target * random() * 0.4)::int, s.daily, 'active', NOW() - INTERVAL '30 days', NOW()
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN LATERAL (VALUES
  ('Dana Darurat', 15000000, 10000),
  ('Servis Motor', 2000000,  5000)
) AS s(goal, target, daily)
WHERE d.status = 'approved'
  AND random() > 0.3;

-- ══════════════════════════════════════════════════════════
--  PINJOL RECORDS
-- ══════════════════════════════════════════════════════════
INSERT INTO pinjol_records (id, driver_id, app_name, principal, interest_rate_pct, monthly_installment, start_date, end_date, risk_level, created_at, updated_at)
SELECT gen_random_uuid(), d.id, p.app, p.principal, p.rate, p.installment,
  NOW() - (p.months || ' months')::interval, NOW() + ((p.term - p.months) || ' months')::interval,
  CASE WHEN p.rate > 2.0 THEN 'high' WHEN p.rate > 1.0 THEN 'medium' ELSE 'low' END,
  NOW(), NOW()
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN LATERAL (VALUES
  ('Kredivo',    3000000, 2.5, 350000, 12, 6),
  ('Akulaku',    1500000, 3.0, 200000,  9, 4),
  ('Shopee PayLater', 800000, 1.5, 100000, 6, 2)
) AS p(app, principal, rate, installment, term, months)
WHERE d.status = 'approved'
  AND u.phone IN ('081210000009','081210000010','081210000011','081210000012','081210000014');

-- ══════════════════════════════════════════════════════════
--  EMERGENCY CONTACTS
-- ══════════════════════════════════════════════════════════
INSERT INTO emergency_contacts (id, driver_id, contact_name, contact_phone, relationship, created_at)
SELECT gen_random_uuid(), d.id, c.name, c.phone, c.rel, NOW()
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN LATERAL (VALUES
  ('Istri ' || u.name, '0812999' || lpad((row_number() OVER ())::text, 4, '0'), 'Pasangan')
) AS c(name, phone, rel)
WHERE d.status = 'approved';

-- ══════════════════════════════════════════════════════════
--  COMMUNITY POSTS (15)
-- ══════════════════════════════════════════════════════════
INSERT INTO community_posts (id, driver_id, content, category, zone_name, likes, created_at)
SELECT gen_random_uuid(), d.id, p.content, p.cat, d.city, floor(random()*50)::int, NOW() - (n || ' hours')::interval
FROM drivers d
JOIN users u ON d.user_id = u.id
CROSS JOIN generate_series(0, 2) AS n
CROSS JOIN LATERAL (VALUES
  ('Tips hemat bensin: jaga kecepatan 60-70 km/h di jalan tol, bisa hemat 15%!', 'tips'),
  ('Ada yang tahu area Cilandak lagi rame order nggak? Sejak pagi sepi banget.', 'question'),
  ('Hari ini Grab lagi promo, orderan food delivery pada numpuk. Gas!', 'info')
) AS p(content, cat)
WHERE d.status = 'approved'
LIMIT 15;

COMMIT;
