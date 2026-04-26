-- ============================================================
-- Database Dump
-- Created at : 2026-04-13T14:09:27.996Z
-- Dialect    : postgres
-- Tables     : Offices, Users, Schedules, SupervisorUsers, OfficeBackups, ActivityRecords, Logs, SchoolYears, Summaries, SpecialKeys, SuperAdmins, SuperAdminLogs
-- ============================================================

-- Foreign key checks disabled via CASCADE in table definitions

-- ──────────────────────────────────────────────────────────
-- Table: `Offices`
-- Columns : 14
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "Offices";
CREATE TABLE IF NOT EXISTS "Offices" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("Offices_id_seq"::regclass)' PRIMARY KEY,
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "office_name" CHARACTER VARYING(255) NOT NULL,
    "office_latitude" NUMERIC NOT NULL,
    "office_longitude" NUMERIC NOT NULL,
    "office_altitude" NUMERIC NOT NULL,
    "time_in_start" TIME WITHOUT TIME ZONE NOT NULL DEFAULT '06:00:00',
    "time_in_start_wfh" TIME WITHOUT TIME ZONE NOT NULL DEFAULT '08:00:00',
    "time_in_end" TIME WITHOUT TIME ZONE NOT NULL DEFAULT '17:00:00',
    "time_out_cap" TIME WITHOUT TIME ZONE NOT NULL DEFAULT '21:00:00',
    "allow_weekend" BOOLEAN DEFAULT false,
    "deactivated" BOOLEAN DEFAULT false,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | office_id | office_name | office_latitude | office_longitude | office_altitude | time_in_start | time_in_start_wfh | time_in_end | time_out_cap | allow_weekend | deactivated | createdAt | updatedAt
INSERT INTO "Offices" ("id", "office_id", "office_name", "office_latitude", "office_longitude", "office_altitude", "time_in_start", "time_in_start_wfh", "time_in_end", "time_out_cap", "allow_weekend", "deactivated", "createdAt", "updatedAt") VALUES
    (1, '0001', 'OVPREPQA', '14.2121', '121.1674', '0.1', '06:00:00', '08:00:00', '17:00:00', '21:00:00', false, false, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Users`
-- Columns : 18
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
    "custom_id" CHARACTER VARYING(255) NOT NULL DEFAULT '',
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "isAdmin" BOOLEAN NOT NULL DEFAULT false,
    "status" USER-DEFINED NOT NULL DEFAULT 'active',
    "current_sy" INTEGER NOT NULL DEFAULT '2025',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | first_name | middle_name | last_name | ccc_id | email | password | role | profile_link | course | target_hours | custom_id | office_id | isAdmin | status | current_sy | createdAt | updatedAt
INSERT INTO "Users" ("id", "first_name", "middle_name", "last_name", "ccc_id", "email", "password", "role", "profile_link", "course", "target_hours", "custom_id", "office_id", "isAdmin", "status", "current_sy", "createdAt", "updatedAt") VALUES
    (4, 'Jayzee', 'R', 'Reolo', '0000-00000', 'jprafanan@ccc.edu.ph', '$2a$10$ZjAYgrJhdqr56/H.FqF.Ce8XpkZo4rJCPVSgey7wKKdBCBp9dopMW', 'supervisor', NULL, '', 0, 'OVPREP-SUPERVISOR-0001', '0001', false, 'active', 2025, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)'),
    (5, 'Regina', 'G', 'Almonte', 'OVPREPQA-ADMIN-0001', 'rgalmonte@ccc.edu.ph', '$2a$10$ZjAYgrJhdqr56/H.FqF.Ce8XpkZo4rJCPVSgey7wKKdBCBp9dopMW', 'supervisor', NULL, '', 0, 'OVPREPQA-ADMIN', '0001', true, 'active', 2025, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)'),
    (1, 'John Dave', 'C', 'Pega', '2022-10934', 'jcpega@ccc.edu.ph', '$2a$10$ZjAYgrJhdqr56/H.FqF.Ce8XpkZo4rJCPVSgey7wKKdBCBp9dopMW', 'student', NULL, 'Bachelor of Science in Computer Science', 450, 'OVPREP-0004', '0001', false, 'active', 2025, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:14 GMT+0800 (Philippine Standard Time)'),
    (2, 'Christ Bien', 'C', 'Tuiza', '2022-11185', 'cbctuiza@ccc.edu.ph', '$2a$10$ZjAYgrJhdqr56/H.FqF.Ce8XpkZo4rJCPVSgey7wKKdBCBp9dopMW', 'student', NULL, 'Bachelor of Science in Information Technology', 600, 'OVPREP-0000', '0001', false, 'active', 2025, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:23 GMT+0800 (Philippine Standard Time)'),
    (3, 'Adrian', 'R', 'Catindig', '2022-10255', 'arcatindig@ccc.edu.ph', '$2a$10$ZjAYgrJhdqr56/H.FqF.Ce8XpkZo4rJCPVSgey7wKKdBCBp9dopMW', 'student', NULL, 'Bachelor of Science in Information Technology', 600, 'OVPREP-0003', '0001', false, 'active', 2025, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:31 GMT+0800 (Philippine Standard Time)');

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
    (1, '0000-00000', '2022-10934,2022-11185,2022-10255', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)'),
    (2, 'OVPREPQA-ADMIN-0001', '2022-10934,2022-11185,2022-10255', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `OfficeBackups`
-- Columns : 8
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "OfficeBackups";
CREATE TABLE IF NOT EXISTS "OfficeBackups" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("OfficeBackups_id_seq"::regclass)' PRIMARY KEY,
    "unique_id" CHARACTER VARYING(255) NOT NULL,
    "version" INTEGER DEFAULT '0',
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "json_backup" JSON NOT NULL,
    "backup_by_superadmin" BOOLEAN DEFAULT false,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | unique_id | version | office_id | json_backup | backup_by_superadmin | createdAt | updatedAt
INSERT INTO "OfficeBackups" ("id", "unique_id", "version", "office_id", "json_backup", "backup_by_superadmin", "createdAt", "updatedAt") VALUES
    (1, 'SA_2026Apr13193541_0001', 1, '0001', '[object Object]', true, 'Mon Apr 13 2026 19:35:41 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:35:41 GMT+0800 (Philippine Standard Time)');

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
    (1, '2022-10934', 'info', 'User 2022-10934 (student) logged in from IP Unknown (Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36)', 'Mon Apr 13 2026 21:58:48 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:58:48 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `SchoolYears`
-- Columns : 6
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SchoolYears";
CREATE TABLE IF NOT EXISTS "SchoolYears" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SchoolYears_id_seq"::regclass)' PRIMARY KEY,
    "office_id" CHARACTER VARYING(255) NOT NULL,
    "current_sy" INTEGER NOT NULL DEFAULT '2025',
    "current_iteration" INTEGER NOT NULL DEFAULT '1',
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | office_id | current_sy | current_iteration | createdAt | updatedAt
INSERT INTO "SchoolYears" ("id", "office_id", "current_sy", "current_iteration", "createdAt", "updatedAt") VALUES
    (1, '0001', 2025, 1, 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)');

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

-- ──────────────────────────────────────────────────────────
-- Table: `SpecialKeys`
-- Columns : 6
-- Rows    : 0
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SpecialKeys";
CREATE TABLE IF NOT EXISTS "SpecialKeys" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SpecialKeys_id_seq"::regclass)' PRIMARY KEY,
    "key" CHARACTER VARYING(255) NOT NULL,
    "email" CHARACTER VARYING(255) NOT NULL,
    "expires_at" TIMESTAMP WITH TIME ZONE NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | key | email | expires_at | createdAt | updatedAt
-- (no data in "SpecialKeys")

-- ──────────────────────────────────────────────────────────
-- Table: `SuperAdmins`
-- Columns : 6
-- Rows    : 1
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SuperAdmins";
CREATE TABLE IF NOT EXISTS "SuperAdmins" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SuperAdmins_id_seq"::regclass)' PRIMARY KEY,
    "username" CHARACTER VARYING(255) NOT NULL,
    "email" CHARACTER VARYING(255) NOT NULL,
    "password" CHARACTER VARYING(255) NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | username | email | password | createdAt | updatedAt
INSERT INTO "SuperAdmins" ("id", "username", "email", "password", "createdAt", "updatedAt") VALUES
    (1, 'SuperAdmin', 'jdmaster888@gmail.com', '$2a$10$7.tuZDohou3pLAj/7Qc92O8.RYL9aPRxskH2BhSRnzBfYt5vMGdWm', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:26:23 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `SuperAdminLogs`
-- Columns : 5
-- Rows    : 17
-- ──────────────────────────────────────────────────────────

DROP TABLE IF EXISTS "SuperAdminLogs";
CREATE TABLE IF NOT EXISTS "SuperAdminLogs" (
    "id" INTEGER NOT NULL DEFAULT 'nextval("SuperAdminLogs_id_seq"::regclass)' PRIMARY KEY,
    "log_type" USER-DEFINED NOT NULL,
    "message" TEXT NOT NULL,
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | log_type | message | createdAt | updatedAt
INSERT INTO "SuperAdminLogs" ("id", "log_type", "message", "createdAt", "updatedAt") VALUES
    (1, 'backup', 'Super admin backed up all offices: 1 succeeded, 0 failed.', 'Mon Apr 13 2026 19:35:41 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 19:35:41 GMT+0800 (Philippine Standard Time)'),
    (2, 'update', 'Member 2022-10934 (John Dave Pega) updated. Changes: status: "active" → "deleted".', 'Mon Apr 13 2026 20:15:24 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:15:24 GMT+0800 (Philippine Standard Time)'),
    (3, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "active" → "pending_for_delete".', 'Mon Apr 13 2026 20:21:47 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:21:47 GMT+0800 (Philippine Standard Time)'),
    (4, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "pending_for_delete" → "active".', 'Mon Apr 13 2026 20:33:39 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:33:39 GMT+0800 (Philippine Standard Time)'),
    (5, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "active" → "pending_for_delete".', 'Mon Apr 13 2026 20:41:43 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:41:43 GMT+0800 (Philippine Standard Time)'),
    (6, 'update', 'Member 2022-10255 (Adrian Catindig) updated. Changes: status: "active" → "deleted".', 'Mon Apr 13 2026 20:51:45 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:51:45 GMT+0800 (Philippine Standard Time)'),
    (7, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "pending_for_delete" → "deleted".', 'Mon Apr 13 2026 20:55:01 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 20:55:01 GMT+0800 (Philippine Standard Time)'),
    (8, 'update', 'Member 2022-10934 (John Dave Pega) restored from "deleted" to "active".', 'Mon Apr 13 2026 21:01:07 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:01:07 GMT+0800 (Philippine Standard Time)'),
    (9, 'update', 'Member 2022-10255 (Adrian Catindig) updated. Changes: status: "deleted" → "active".', 'Mon Apr 13 2026 21:01:19 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:01:19 GMT+0800 (Philippine Standard Time)'),
    (10, 'update', 'Member 2022-11185 (Christ Bien Tuiza) restored from "deleted" to "active".', 'Mon Apr 13 2026 21:10:11 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:10:11 GMT+0800 (Philippine Standard Time)'),
    (11, 'update', 'Member 2022-10934 (John Dave Pega) updated. Changes: status: "active" → "deleted".', 'Mon Apr 13 2026 21:10:19 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:10:19 GMT+0800 (Philippine Standard Time)'),
    (12, 'update', 'Member 2022-10255 (Adrian Catindig) updated. Changes: status: "active" → "pending_for_delete".', 'Mon Apr 13 2026 21:10:36 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:10:36 GMT+0800 (Philippine Standard Time)'),
    (13, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "active" → "pending_for_delete".', 'Mon Apr 13 2026 21:10:53 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:10:53 GMT+0800 (Philippine Standard Time)'),
    (14, 'update', 'Member 2022-10934 (John Dave Pega) restored from "deleted" to "active".', 'Mon Apr 13 2026 21:50:14 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:14 GMT+0800 (Philippine Standard Time)'),
    (15, 'update', 'Member 2022-11185 (Christ Bien Tuiza) updated. Changes: status: "pending_for_delete" → "active".', 'Mon Apr 13 2026 21:50:23 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:23 GMT+0800 (Philippine Standard Time)'),
    (16, 'update', 'Member 2022-10255 (Adrian Catindig) updated. Changes: status: "pending_for_delete" → "active".', 'Mon Apr 13 2026 21:50:32 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:50:32 GMT+0800 (Philippine Standard Time)'),
    (17, 'update', 'Member 0000-00000 (Jayzee Reolo) updated. Changes: none.', 'Mon Apr 13 2026 21:51:52 GMT+0800 (Philippine Standard Time)', 'Mon Apr 13 2026 21:51:52 GMT+0800 (Philippine Standard Time)');

-- End of dump

-- ============================================================
-- End of Dump — 2026-04-13T14:09:27.996Z
-- ============================================================