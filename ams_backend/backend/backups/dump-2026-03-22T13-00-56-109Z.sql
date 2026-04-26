-- ============================================================
-- Database Dump
-- Created at : 2026-03-22T13:00:56.109Z
-- Dialect    : postgres
-- Tables     : SchoolYears, Offices, Users, Schedules, SupervisorUsers, ActivityRecords, Logs, Summaries
-- ============================================================

-- Foreign key checks disabled via CASCADE in table definitions

-- ──────────────────────────────────────────────────────────
-- Table: `SchoolYears`
-- Columns : 6
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SchoolYears";
CREATE TABLE IF NOT EXISTS "SchoolYears" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SchoolYears_id_seq"::regclass)' PRIMARY KEY,
    "office_id" INTEGER NOT NULL,
    "current_sy" INTEGER NOT NULL DEFAULT '2025',
    "current_iteration" INTEGER NOT NULL DEFAULT '1',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | office_id | current_sy | current_iteration | createdAt | updatedAt
INSERT INTO "SchoolYears" ("id", "office_id", "current_sy", "current_iteration", "createdAt", "updatedAt") VALUES
    (1, 1, 2025, 2, 'Mon Mar 16 2026 02:46:17 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 16:38:20 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Offices`
-- Columns : 8
-- Rows    : 3
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Offices";
CREATE TABLE IF NOT EXISTS "Offices" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Offices_id_seq"::regclass)' PRIMARY KEY,
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "office_name" CHARACTER VARYING(255) NOT NULL,
    "office_latitude" NUMERIC NOT NULL,
    "office_longitude" NUMERIC NOT NULL,
    "office_altitude" NUMERIC NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | office_id | office_name | office_latitude | office_longitude | office_altitude | createdAt | updatedAt
INSERT INTO "Offices" ("id", "office_id", "office_name", "office_latitude", "office_longitude", "office_altitude", "createdAt", "updatedAt") VALUES
    (1, '0001', 'OVPREPQA', '14.2121', '121.1674', '0.1', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)'),
    (2, 'M-1773650531927', 'MISD', '0', '0', '0', 'Mon Mar 16 2026 16:42:11 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 16:42:11 GMT+0800 (Philippine Standard Time)'),
    (3, 'M-1773650544841', 'MISD', '0', '0', '0', 'Mon Mar 16 2026 16:42:24 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 16:42:24 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Users`
-- Columns : 16
-- Rows    : 5
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Users";
CREATE TABLE IF NOT EXISTS "Users" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Users_id_seq"::regclass)' PRIMARY KEY,
    "first_name" CHARACTER VARYING(255) NOT NULL,
    "middle_name" CHARACTER VARYING(255),
    "last_name" CHARACTER VARYING(255) NOT NULL,
    "ccc_id" CHARACTER VARYING(255) NOT NULL,
    "email" CHARACTER VARYING(255) NOT NULL,
    "password" CHARACTER VARYING(255) NOT NULL,
    "role" USER-DEFINED NOT NULL,
    "profile_link" CHARACTER VARYING(255),
    "course" CHARACTER VARYING(255) NOT NULL,
    "target_hours" INTEGER NOT NULL DEFAULT '450',
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "current_sy" INTEGER NOT NULL DEFAULT '2025',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | first_name | middle_name | last_name | ccc_id | email | password | role | profile_link | course | target_hours | office_id | isAdmin | current_sy | createdAt | updatedAt
INSERT INTO "Users" ("id", "first_name", "middle_name", "last_name", "ccc_id", "email", "password", "role", "profile_link", "course", "target_hours", "office_id", "isAdmin", "current_sy", "createdAt", "updatedAt") VALUES
    (1, 'John Dave', 'C', 'Pega', '2022-10934', 'jcpega@ccc.edu.ph', '$2a$10$fGz6.3P9GDqntj3aXsRc3eiac/IycKScxwY5T2ADGpUUKDehpeFme', 'student', NULL, 'Bachelor of Science in Computer Science', 450, '0001', false, 2025, 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)'),
    (2, 'Christ Bien', 'C', 'Tuiza', '2022-11185', 'cbctuiza@ccc.edu.ph', '$2a$10$fGz6.3P9GDqntj3aXsRc3eiac/IycKScxwY5T2ADGpUUKDehpeFme', 'student', NULL, 'Bachelor of Science in Information Technology', 600, '0001', false, 2025, 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)'),
    (3, 'Adrian', 'R', 'Catindig', '2022-10255', 'arcatindig@ccc.edu.ph', '$2a$10$fGz6.3P9GDqntj3aXsRc3eiac/IycKScxwY5T2ADGpUUKDehpeFme', 'student', NULL, 'Bachelor of Science in Information Technology', 600, '0001', false, 2025, 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)'),
    (4, 'Jayzee', 'R', 'Reolo', '0000-00000', 'jprafanan@ccc.edu.ph', '$2a$10$fGz6.3P9GDqntj3aXsRc3eiac/IycKScxwY5T2ADGpUUKDehpeFme', 'supervisor', NULL, '', 0, '0001', false, 2025, 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)'),
    (5, 'Regina', 'G', 'Almonte', 'ADMIN-00000', 'rgalmonte@ccc.edu.ph', '$2a$10$fGz6.3P9GDqntj3aXsRc3eiac/IycKScxwY5T2ADGpUUKDehpeFme', 'supervisor', NULL, '', 0, '0001', true, 2025, 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:16 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Schedules`
-- Columns : 12
-- Rows    : 2
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Schedules";
CREATE TABLE IF NOT EXISTS "Schedules" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Schedules_id_seq"::regclass)' PRIMARY KEY,
    "date" DATE NOT NULL,
    "time_in" TIME WITHOUT TIME ZONE NOT NULL,
    "time_out" TIME WITHOUT TIME ZONE,
    "proof_in" CHARACTER VARYING(255),
    "proof_out" CHARACTER VARYING(255),
    "isAcceptedEarly" BOOLEAN DEFAULT true,
    "isAcceptedWorkFromHome" BOOLEAN DEFAULT true,
    "isWorkFromHome" BOOLEAN DEFAULT false,
    "ccc_id" CHARACTER VARYING(255) NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | date | time_in | time_out | proof_in | proof_out | isAcceptedEarly | isAcceptedWorkFromHome | isWorkFromHome | ccc_id | createdAt | updatedAt
INSERT INTO "Schedules" ("id", "date", "time_in", "time_out", "proof_in", "proof_out", "isAcceptedEarly", "isAcceptedWorkFromHome", "isWorkFromHome", "ccc_id", "createdAt", "updatedAt") VALUES
    (1, '2026-01-15', '07:55:00', '17:27:00', 'https://res.cloudinary.com/dy6z8wadm/image/upload/v1768436491/ccc-ojt-proofs/f4dgwlwpgp9hlehpw2k7.jpg', 'https://res.cloudinary.com/dy6z8wadm/image/upload/v1768469279/ccc-ojt-proofs/y08p3eoqlgrhdjoz39ob.jpg', true, true, false, '2022-10934', 'Thu Jan 15 2026 08:21:32 GMT+0800 (Philippine Standard Time)', 'Thu Jan 15 2026 18:45:09 GMT+0800 (Philippine Standard Time)'),
    (2, '2026-01-15', '07:50:00', '17:27:00', 'https://res.cloudinary.com/dy6z8wadm/image/upload/v1768436608/ccc-ojt-proofs/u6z1aep0rnatktwrdetl.jpg', 'https://res.cloudinary.com/dy6z8wadm/image/upload/v1768469278/ccc-ojt-proofs/yjkldu976u00xprsti5n.jpg', true, true, false, '2022-10255', 'Thu Jan 15 2026 08:23:29 GMT+0800 (Philippine Standard Time)', 'Thu Jan 15 2026 18:45:23 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `SupervisorUsers`
-- Columns : 5
-- Rows    : 2
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SupervisorUsers";
CREATE TABLE IF NOT EXISTS "SupervisorUsers" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SupervisorUsers_id_seq"::regclass)' PRIMARY KEY,
    "ccc_id" CHARACTER VARYING(255) NOT NULL,
    "all_users" ARRAY DEFAULT '(ARRAY[]',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | ccc_id | all_users | createdAt | updatedAt
INSERT INTO "SupervisorUsers" ("id", "ccc_id", "all_users", "createdAt", "updatedAt") VALUES
    (1, '0000-00000', '2022-10934,2022-11185,2022-10255', 'Mon Mar 16 2026 02:46:17 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:17 GMT+0800 (Philippine Standard Time)'),
    (2, 'ADMIN-00000', '2022-10934,2022-11185,2022-10255', 'Mon Mar 16 2026 02:46:17 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 02:46:17 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `ActivityRecords`
-- Columns : 6
-- Rows    : 0
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "ActivityRecords";
CREATE TABLE IF NOT EXISTS "ActivityRecords" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("ActivityRecords_id_seq"::regclass)' PRIMARY KEY,
    "image_url" CHARACTER VARYING(255) DEFAULT '',
    "description" TEXT,
    "schedule_record_date" CHARACTER VARYING(255) NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | image_url | description | schedule_record_date | createdAt | updatedAt
-- (no data in "ActivityRecords")

-- ──────────────────────────────────────────────────────────
-- Table: `Logs`
-- Columns : 6
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Logs";
CREATE TABLE IF NOT EXISTS "Logs" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Logs_id_seq"::regclass)' PRIMARY KEY,
    "user_ccc_id" CHARACTER VARYING(255),
    "log_type" USER-DEFINED NOT NULL,
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | user_ccc_id | log_type | message | createdAt | updatedAt
INSERT INTO "Logs" ("id", "user_ccc_id", "log_type", "message", "createdAt", "updatedAt") VALUES
    (1, '0000-00000', 'update', 'Advanced to iteration 1 for office 0001', 'Mon Mar 16 2026 16:38:20 GMT+0800 (Philippine Standard Time)', 'Mon Mar 16 2026 16:38:20 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Summaries`
-- Columns : 5
-- Rows    : 0
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Summaries";
CREATE TABLE IF NOT EXISTS "Summaries" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Summaries_id_seq"::regclass)' PRIMARY KEY,
    "schedule_record_date" CHARACTER VARYING(255) NOT NULL,
    "summary_text" TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | schedule_record_date | summary_text | createdAt | updatedAt
-- (no data in "Summaries")

-- End of dump

-- ============================================================
-- End of Dump — 2026-03-22T13:00:56.109Z
-- ============================================================