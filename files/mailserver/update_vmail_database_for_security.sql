USE vmail;

ALTER TABLE user
ADD COLUMN salt TEXT NULL;