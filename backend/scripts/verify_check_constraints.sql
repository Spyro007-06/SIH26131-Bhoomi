-- Proves the two constraints docs/DESIGN.md §5 insists live in the schema
-- actually reject at the database, not in Python.
--
-- Everything happens inside one transaction that is rolled back at the end, so
-- running this leaves no rows behind.
--
--   psql "$CONN" -f scripts/verify_check_constraints.sql

BEGIN;

-- Parent rows the two inserts need.
INSERT INTO app_user (id, role, phone, name)
VALUES ('11111111-1111-1111-1111-111111111111', 'farmer', '+910000000000', 'CHECK probe');

INSERT INTO farm (id, farmer_id, crop, growth_stage, region, location)
VALUES ('22222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111',
        'paddy', 'tillering', 'Nashik',
        ST_GeogFromText('SRID=4326;POINT(73.7898 19.9975)'));

INSERT INTO problem (id, farm_id, problem_type)
VALUES ('33333333-3333-3333-3333-333333333333',
        '22222222-2222-2222-2222-222222222222', 'disease');

\echo ''
\echo '=== 1. Alert with inspection_tasks = [] — must be REJECTED ==='
SAVEPOINT probe_alert;
INSERT INTO alert (farm_id, trigger_type, target, risk_level, reason, inspection_tasks)
VALUES ('22222222-2222-2222-2222-222222222222',
        'weather', 'blast', 'high',
        'Humidity above 90% for 4 consecutive nights at tillering stage.',
        '[]'::jsonb);
ROLLBACK TO SAVEPOINT probe_alert;

\echo ''
\echo '=== 1b. Same alert with one task — must be ACCEPTED ==='
SAVEPOINT probe_alert_ok;
INSERT INTO alert (farm_id, trigger_type, target, risk_level, reason, inspection_tasks)
VALUES ('22222222-2222-2222-2222-222222222222',
        'weather', 'blast', 'high',
        'Humidity above 90% for 4 consecutive nights at tillering stage.',
        '["Check the upper leaves on 10 plants across the field."]'::jsonb);
ROLLBACK TO SAVEPOINT probe_alert_ok;

\echo ''
\echo '=== 2. Advisory whose chemical rung is NOT last — must be REJECTED ==='
SAVEPOINT probe_advisory;
INSERT INTO advisory (problem_id, possible_issue, what_to_check, what_to_avoid, ladder)
VALUES ('33333333-3333-3333-3333-333333333333',
        'Early blast (confidence: high).',
        'Diamond-shaped lesions with grey centres on upper leaves.',
        'Do not top-dress nitrogen now. It accelerates spread.',
        '[{"tier":"chemical","action":"Tricyclazole 75 WP","dosage":"0.6 g per litre","phi_days":30,"reentry_hours":24},
          {"tier":"cultural","action":"Drain the field and let it dry for 48 hours."}]'::jsonb);
ROLLBACK TO SAVEPOINT probe_advisory;

\echo ''
\echo '=== 2b. Same ladder with chemical last — must be ACCEPTED ==='
SAVEPOINT probe_advisory_ok;
INSERT INTO advisory (problem_id, possible_issue, what_to_check, what_to_avoid, ladder)
VALUES ('33333333-3333-3333-3333-333333333333',
        'Early blast (confidence: high).',
        'Diamond-shaped lesions with grey centres on upper leaves.',
        'Do not top-dress nitrogen now. It accelerates spread.',
        '[{"tier":"cultural","action":"Drain the field and let it dry for 48 hours."},
          {"tier":"chemical","action":"Tricyclazole 75 WP","dosage":"0.6 g per litre","phi_days":30,"reentry_hours":24}]'::jsonb);
ROLLBACK TO SAVEPOINT probe_advisory_ok;

ROLLBACK;
