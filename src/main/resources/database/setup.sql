create database irdeto_cg

grant select, insert, update, delete, create, alter on irdeto_cg.* to irdetodev@'%';



CREATE TABLE change_types (
  id        TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name      VARCHAR(100)     NOT NULL,
  std_hours DECIMAL(5,1)     NOT NULL DEFAULT 0.0,
  PRIMARY KEY (id),
  UNIQUE KEY uq_name (name)
);

INSERT INTO change_types (name, std_hours) VALUES
  ('3rd Party Apps',                   8.0),
  ('Channel Decommission',            12.0),
  ('Channel Name / Number Change',     6.0),
  ('Day Light Saving',                 8.0),
  ('FTA Per Channel',                 10.0),
  ('Logo Change',                      4.0),
  ('New Channel (Per Channel)',        20.0),
  ('Open Tier (Per Channel)',           8.0),
  ('Open Tier (Per package Change)',   10.0),
  ('Service Move (Per Channel)',        6.0);
  
  
CREATE TABLE change_requests (
  id             CHAR(36)         NOT NULL DEFAULT (UUID()),
  title          VARCHAR(255)     NOT NULL,
  description    TEXT,
  owner          VARCHAR(100),
  jira_ticket    VARCHAR(50),
  srn            VARCHAR(50),
  change_type_id TINYINT UNSIGNED,
  std_hours      DECIMAL(5,1)     NOT NULL DEFAULT 0.0,
  status         ENUM(
                   'Draft',
                   'Impact Assessment',
                   'In Progress',
                   'Sent to Foxtel',
                   'Approved',
                   'Scheduled',
                   'Completed',
                   'On Hold',
                   'Cancelled'
                 )               NOT NULL DEFAULT 'Draft',
  cr_review      ENUM('YES','NO') NOT NULL DEFAULT 'NO',
  date_created   DATE             NOT NULL,
  deploy_date    DATE,
  created_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_status     (status),
  KEY idx_deploy     (deploy_date),
  KEY idx_owner      (owner),
  CONSTRAINT fk_cr_type FOREIGN KEY (change_type_id)
    REFERENCES change_types (id)
    ON UPDATE CASCADE ON DELETE SET NULL
);  

ALTER TABLE change_requests
  ADD COLUMN seq INT UNSIGNED NOT NULL AUTO_INCREMENT FIRST,
  ADD INDEX idx_seq (seq);

CREATE TABLE cr_week_allocations (
  id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  cr_id           CHAR(36)         NOT NULL,
  week_start_date DATE             NOT NULL COMMENT 'Monday of the ISO week',
  iso_week        TINYINT UNSIGNED NOT NULL COMMENT 'ISO week number 1-53',
  iso_year        SMALLINT UNSIGNED NOT NULL COMMENT 'ISO week-year',
  planned_hours   DECIMAL(5,1)     NOT NULL DEFAULT 0.0,
  actual_hours    DECIMAL(5,1)     NOT NULL DEFAULT 0.0,
  created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_cr_week (cr_id, week_start_date),
  KEY idx_week (iso_year, iso_week),
  CONSTRAINT fk_wkalloc_cr FOREIGN KEY (cr_id)
    REFERENCES change_requests (id)
    ON DELETE CASCADE,
  CONSTRAINT chk_hours CHECK (planned_hours >= 0 AND actual_hours >= 0)
);



CREATE VIEW v_cr_summary AS
SELECT
  cr.id,
  cr.srn,
  cr.title,
  ct.name                                     AS change_type,
  cr.std_hours                                AS est_hours,
  COALESCE(SUM(wa.planned_hours), 0)          AS planned_hours,
  COALESCE(SUM(wa.actual_hours),  0)          AS actual_hours,
  COALESCE(SUM(wa.planned_hours), 0)
    - COALESCE(SUM(wa.actual_hours), 0)       AS variance,
  cr.cr_review
FROM change_requests cr
LEFT JOIN change_types        ct ON ct.id    = cr.change_type_id
LEFT JOIN cr_week_allocations wa ON wa.cr_id = cr.id
GROUP BY cr.id, cr.srn, cr.title, ct.name, cr.std_hours, cr.cr_review;

-- Replaces WEEKLY_RAW / DEPLOYMENTS (both are projections of change_requests)
CREATE VIEW v_weekly_capacity AS
SELECT
  iso_year,
  iso_week,
  MIN(week_start_date)   AS week_start_date,
  SUM(planned_hours)     AS planned_hours,
  SUM(actual_hours)      AS actual_hours
FROM cr_week_allocations
GROUP BY iso_year, iso_week
ORDER BY iso_year, iso_week; 



-- ── change_requests ───────────────────────────────────────────────────────
INSERT INTO change_requests
  (id, title, description, owner, jira_ticket, srn, change_type_id,
   std_hours, status, cr_review, date_created, deploy_date)
VALUES
  ('Xr6mlInaGwhdA6TmLCa1',
   'Daylight Saving Changes',
   'Prepping platform changes for ending Daylight Saving time 5-April-2026',
   'Kate', 'ARWR-1453', 'SR-1044924', 4,       -- Day Light Saving
   8.0, 'In Progress', 'NO', '2026-03-06', '2026-03-19'),

  ('kb4CwhbA158y0tGw63qW',
   'Movie Hits Pop-Up Logos Fast & Fierce',
   'Pop-up logo placement for Fast & Fierce movie hits programming block.',
   'Dominik Schlueter', 'ARWR-1200', 'SR-1037814', 6,   -- Logo Change
   4.0, 'Impact Assessment', 'NO', '2026-02-10', '2026-03-26'),

  ('mT0j5tBRY6OL5DUlHxiU',
   'Movie Hits Pop-Up Logos - Oscar Winners',
   'Oscar Winners special pop-up logo set for Movie Hits channel.',
   'Dominik Schlueter', 'ARWR-1201', 'SR-1037814', 6,
   4.0, 'Impact Assessment', 'NO', '2026-02-05', '2026-03-17'),

  ('zxH3WND8rduy5l5mrppZ',
   'Movie Hits Pop-Up Logos Spotlight on Eddie Murphy',
   'Eddie Murphy spotlight branding pop-up logos for Movie Hits.',
   'Dominik Schlueter', 'ARWR-1202', 'SR-1037814', 6,
   4.0, 'Impact Assessment', 'NO', '2026-02-15', '2026-03-27'),

  ('1sq54Qs8RP0H7Uh7edh5',
   'Movie Hits Pop-Up Logos - Funny Ladies',
   'Funny Ladies pop-up logo set for Movie Hits weekly programming.',
   'Dominik Schlueter', 'ARWR-1203', 'SR-1037814', 6,
   4.0, 'In Progress', 'NO', '2026-01-20', '2026-03-04'),

  ('rFk6BXrEZgfJogmHATJw',
   'Expo Channel Re-name & Re-brand to TVSN2',
   'Full re-brand of Expo channel including name change, logo, EPG metadata and playout updates.',
   'Dominik Schlueter', 'ARWR-1180', 'SR-1037123', 3,   -- Channel Name / Number Change
   6.0, 'In Progress', 'YES', '2026-01-15', '2026-03-10'),

  ('0BulPjWJ2apKXJjJPMiy',
   'Binge & Kayo Linear Channel Source Changes ex App',
   'Update playout source configurations for Binge and Kayo linear channels following app migration.',
   'Michael de Marigny', NULL, '1037156', 10,            -- Service Move (Per Channel)
   6.0, 'Draft', 'NO', '2026-02-20', '2026-03-16'),

  ('LKHs9ULrCrZwME2MjrgQ',
   'Rolling Pop-Up Close Channel 128',
   'Decommission rolling pop-up channel 128 as per schedule.',
   NULL, NULL, '1037132', 2,                             -- Channel Decommission
   12.0, 'Draft', 'NO', '2026-02-18', '2026-03-22'),

  ('iY8Q4OYQDQlalpQQlMzY',
   'Rolling Pop-Up Close Channel 129',
   'Decommission rolling pop-up channel 129 as per schedule.',
   NULL, NULL, '1037136', 2,
   12.0, 'Draft', 'NO', '2026-02-18', '2026-09-01'),

  ('oQP1XEHTYwWuF4DixJzk',
   'Removal of ME SD Simulcast Channels x2',
   'Remove two SD simulcast channels from Middle East region as part of HD-only rollout.',
   'Kate', 'ARWR-1175', 'SR-1037152', 2,
   12.0, 'On Hold', 'YES', '2026-01-10', '2026-04-30'),

  ('z0CeSgfCU05V8HiTWdCh',
   "Vevo 80's Channel Launch",
   'Launch new Vevo 80s dedicated channel. Deployment date TBC.',
   'TBC', 'ARWR-1210', '1037189', 7,                    -- New Channel (Per Channel)
   20.0, 'Draft', 'YES', '2026-02-25', NULL),

  ('FYHhKLJ8MW00xfexYEMY',
   'Launch New Main Event UFC LV channel',
   'New UFC Las Vegas linear channel launch via Main Event for Foxtel pay-per-view subscribers.',
   'Kate / Robie', 'ARWR-1172', 'SR-1037148', 7,
   20.0, 'Sent to Foxtel', 'YES', '2026-01-08', '2026-03-31');


-- ── cr_week_allocations ───────────────────────────────────────────────────
-- week_start_date = Monday of the ISO week (2026)
-- Week  8: 2026-02-16 | Week  9: 2026-02-23 | Week 10: 2026-03-02
-- Week 11: 2026-03-09 | Week 12: 2026-03-16 | Week 13: 2026-03-23
-- Week 14: 2026-03-30 | Week 15: 2026-04-06 | Week 16: 2026-04-13
-- Week 17: 2026-04-20 | Week 18: 2026-04-27

INSERT INTO cr_week_allocations
  (cr_id, week_start_date, iso_week, iso_year, planned_hours, actual_hours)
VALUES
  -- Week 8
  ('1sq54Qs8RP0H7Uh7edh5', '2026-02-16',  8, 2026, 2.0, 1.0),
  ('rFk6BXrEZgfJogmHATJw', '2026-02-16',  8, 2026, 4.0, 3.0),

  -- Week 9
  ('1sq54Qs8RP0H7Uh7edh5', '2026-02-23',  9, 2026, 2.0, 0.5),
  ('rFk6BXrEZgfJogmHATJw', '2026-02-23',  9, 2026, 3.0, 0.0),
  ('FYHhKLJ8MW00xfexYEMY', '2026-02-23',  9, 2026, 20.0, 5.0),

  -- Week 10
  ('kb4CwhbA158y0tGw63qW', '2026-03-02', 10, 2026, 2.0, 0.0),
  ('mT0j5tBRY6OL5DUlHxiU', '2026-03-02', 10, 2026, 2.0, 0.0),
  ('rFk6BXrEZgfJogmHATJw', '2026-03-02', 10, 2026, 2.0, 0.0),
  ('FYHhKLJ8MW00xfexYEMY', '2026-03-02', 10, 2026, 20.0, 3.0),

  -- Week 11 (Daylight Saving duplicate merged: 2h + 2h = 4h)
  ('Xr6mlInaGwhdA6TmLCa1', '2026-03-09', 11, 2026, 4.0, 0.0),
  ('kb4CwhbA158y0tGw63qW', '2026-03-09', 11, 2026, 2.0, 0.0),
  ('mT0j5tBRY6OL5DUlHxiU', '2026-03-09', 11, 2026, 2.0, 0.0),
  ('FYHhKLJ8MW00xfexYEMY', '2026-03-09', 11, 2026, 20.0, 0.0),

  -- Week 12
  ('Xr6mlInaGwhdA6TmLCa1', '2026-03-16', 12, 2026, 1.0, 0.0),
  ('zxH3WND8rduy5l5mrppZ', '2026-03-16', 12, 2026, 4.0, 0.0),
  ('FYHhKLJ8MW00xfexYEMY', '2026-03-16', 12, 2026, 10.0, 0.0),

  -- Week 13  (from CR_WEEK_DATA — not in CR_ALL.weeks for UFC)
  ('FYHhKLJ8MW00xfexYEMY', '2026-03-23', 13, 2026, 4.0, 0.0),

  -- Week 14
  ('oQP1XEHTYwWuF4DixJzk', '2026-03-30', 14, 2026, 10.0, 0.0),

  -- Week 15
  ('oQP1XEHTYwWuF4DixJzk', '2026-04-06', 15, 2026, 15.0, 0.0),

  -- Week 16
  ('oQP1XEHTYwWuF4DixJzk', '2026-04-13', 16, 2026, 10.0, 0.0),

  -- Week 17  (from CR_WEEK_DATA — not in CR_ALL.weeks for Expo)
  ('rFk6BXrEZgfJogmHATJw', '2026-04-20', 17, 2026, 9.0, 0.0),

  -- Week 18
  ('0BulPjWJ2apKXJjJPMiy', '2026-04-27', 18, 2026, 18.0, 0.0);


        