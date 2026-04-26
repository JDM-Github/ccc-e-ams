-- ============================================================
-- Database Dump
-- Created at : 2026-03-15T11:44:03.377Z
-- Dialect    : postgres
-- Tables     : Offices, Users, Schedules, SupervisorUsers, ActivityRecords, Logs, SchoolYears
-- ============================================================

-- Foreign key checks disabled via CASCADE in table definitions

-- ──────────────────────────────────────────────────────────
-- Table: `Offices`
-- Columns : 8
-- Rows    : 0
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
-- (no data in "Offices")

-- ──────────────────────────────────────────────────────────
-- Table: `Users`
-- Columns : 16
-- Rows    : 0
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
-- (no data in "Users")

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
-- Rows    : 0
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
-- (no data in "SupervisorUsers")

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
-- Rows    : 0
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
-- (no data in "Logs")

-- ──────────────────────────────────────────────────────────
-- Table: `SchoolYears`
-- Columns : 6
-- Rows    : 0
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
-- (no data in "SchoolYears")

-- End of dump

-- ============================================================
-- End of Dump — 2026-03-15T11:44:03.377Z
-- ============================================================