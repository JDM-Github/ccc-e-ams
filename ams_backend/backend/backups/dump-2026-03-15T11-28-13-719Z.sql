-- ============================================================
-- Database Dump
-- Created at : 2026-03-15T11:28:13.719Z
-- Dialect    : postgres
-- Tables     : Offices, Users, Schedules, SupervisorUsers, ActivityRecords, Logs
-- ============================================================

-- Foreign key checks disabled via CASCADE in table definitions

-- ──────────────────────────────────────────────────────────
-- Table: `Offices`
-- Columns : 8
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
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | office_id | office_name | office_latitude | office_longitude | office_altitude | createdAt | updatedAt
INSERT INTO "Offices" ("id", "office_id", "office_name", "office_latitude", "office_longitude", "office_altitude", "createdAt", "updatedAt") VALUES
    (1, 'T-1773309761273', 'TestOffice', '0', '0', '0', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Users`
-- Columns : 15
-- Rows    : 4
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
    "createdAt" TIMESTAMP WITH TIME ZONE NOT NULL,
    "updatedAt" TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Columns: id | first_name | middle_name | last_name | ccc_id | email | password | role | profile_link | course | target_hours | office_id | isAdmin | createdAt | updatedAt
INSERT INTO "Users" ("id", "first_name", "middle_name", "last_name", "ccc_id", "email", "password", "role", "profile_link", "course", "target_hours", "office_id", "isAdmin", "createdAt", "updatedAt") VALUES
    (1, 'John Dave', '', 'Pega', '2022-10934', 'jcpega@ccc.edu.ph', '$2a$10$qxX/QYHSktGR2/BXlenplO5EcmvzUJA7hLgXNqaaI7o6KfKxf7IFK', 'supervisor', NULL, '', 0, 'T-1773309761273', true, 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)'),
    (2, 'Test', '', 'Test', '2022-10965', 'jcpega1@ccc.edu.ph', '$2a$10$fbR92oFltg8rIMlmXTkBKOVP1WV0CbclKVR.hnan8m6kweDrZ2jqG', 'supervisor', NULL, '', 450, 'T-1773309761273', false, 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)'),
    (3, 'Ulol', '', 'Ulol', '2022-109345', 'jdmaster888@gmail.com', '$2a$10$SMFfngIwB7j5PXZcVIUpLO1eb3yi46niBkkEolY7JMAibtvJvuJs6', 'student', NULL, 'Bachelor of Freaking Science', 500, 'T-1773309761273', false, 'Thu Mar 12 2026 18:21:03 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:21:03 GMT+0800 (Philippine Standard Time)'),
    (4, 'Test2', '', 'Test', '2022-1093456', 'jdmaster2@gmail.com', '$2a$10$G8va1ko8OeIIB3k0L.7fduitY/50OHTISjbi1A4lKhnEBFmEsSeVO', 'supervisor', 'https://res.cloudinary.com/dy6z8wadm/image/upload/v1773312535/ccc-ojt-proofs/re0578srabd3shzqnue0.jpg', '', 450, 'T-1773309761273', false, 'Thu Mar 12 2026 18:44:53 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:48:54 GMT+0800 (Philippine Standard Time)');

-- ──────────────────────────────────────────────────────────
-- Table: `Schedules`
-- Columns : 12
-- Rows    : 0
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
-- (no data in "Schedules")

-- ──────────────────────────────────────────────────────────
-- Table: `SupervisorUsers`
-- Columns : 5
-- Rows    : 3
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
    (2, '2022-10965', '', 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)'),
    (1, '2022-10934', '2022-109345', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:21:03 GMT+0800 (Philippine Standard Time)'),
    (3, '2022-1093456', '2022-109345', 'Thu Mar 12 2026 18:44:53 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:44:53 GMT+0800 (Philippine Standard Time)');

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
-- Rows    : 26
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
    (1, '2022-10934', 'create', 'Admin account created: John Dave Pega (Office: TestOffice)', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:02:41 GMT+0800 (Philippine Standard Time)'),
    (2, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:03:06 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:03:06 GMT+0800 (Philippine Standard Time)'),
    (3, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:11:50 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:11:50 GMT+0800 (Philippine Standard Time)'),
    (4, '2022-10934', 'create', 'Supervisor account created: Test Test', 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:12:26 GMT+0800 (Philippine Standard Time)'),
    (5, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:17:56 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:17:56 GMT+0800 (Philippine Standard Time)'),
    (6, '2022-10934', 'create', 'Student account created: Ulol Ulol', 'Thu Mar 12 2026 18:21:03 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:21:03 GMT+0800 (Philippine Standard Time)'),
    (7, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:21:22 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:21:22 GMT+0800 (Philippine Standard Time)'),
    (8, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:21:32 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:21:32 GMT+0800 (Philippine Standard Time)'),
    (9, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:22:28 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:22:28 GMT+0800 (Philippine Standard Time)'),
    (10, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:23:03 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:23:03 GMT+0800 (Philippine Standard Time)'),
    (11, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:23:16 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:23:16 GMT+0800 (Philippine Standard Time)'),
    (12, '2022-109345', 'error', 'Login failed: Invalid password', 'Thu Mar 12 2026 18:23:20 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:23:20 GMT+0800 (Philippine Standard Time)'),
    (13, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:23:43 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:23:43 GMT+0800 (Philippine Standard Time)'),
    (14, '2022-109345', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:24:02 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:24:02 GMT+0800 (Philippine Standard Time)'),
    (15, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:32:38 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:32:38 GMT+0800 (Philippine Standard Time)'),
    (16, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:33:47 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:33:47 GMT+0800 (Philippine Standard Time)'),
    (17, '2022-109345', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:34:16 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:34:16 GMT+0800 (Philippine Standard Time)'),
    (18, '2022-109345', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:39:47 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:39:47 GMT+0800 (Philippine Standard Time)'),
    (19, '2022-10965', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:40:36 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:40:36 GMT+0800 (Philippine Standard Time)'),
    (20, '2022-10965', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:43:54 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:43:54 GMT+0800 (Philippine Standard Time)'),
    (21, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:44:29 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:44:29 GMT+0800 (Philippine Standard Time)'),
    (22, '2022-10934', 'create', 'Supervisor account created: Test2 Test', 'Thu Mar 12 2026 18:44:53 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:44:53 GMT+0800 (Philippine Standard Time)'),
    (23, '2022-1093456', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:46:29 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:46:29 GMT+0800 (Philippine Standard Time)'),
    (24, NULL, 'info', 'Proof image uploaded successfully', 'Thu Mar 12 2026 18:48:53 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:48:53 GMT+0800 (Philippine Standard Time)'),
    (25, '2022-1093456', 'update', 'Profile picture updated', 'Thu Mar 12 2026 18:48:54 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:48:54 GMT+0800 (Philippine Standard Time)'),
    (26, '2022-10934', 'info', 'User logged in successfully', 'Thu Mar 12 2026 18:49:08 GMT+0800 (Philippine Standard Time)', 'Thu Mar 12 2026 18:49:08 GMT+0800 (Philippine Standard Time)');

-- End of dump

-- ============================================================
-- End of Dump — 2026-03-15T11:28:13.719Z
-- ============================================================