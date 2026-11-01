-- AST2 Mining v2 initial schema
-- MySQL 8.0+ / InnoDB / utf8mb4
-- Import into a NEW database first. Do not drop existing tables.
SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  telegram_id VARCHAR(32) NOT NULL,
  username VARCHAR(64) NULL,
  first_name VARCHAR(128) NULL,
  last_name VARCHAR(128) NULL,
  language_code VARCHAR(16) NULL,
  points DECIMAL(36,9) NOT NULL DEFAULT 0,
  status ENUM('active','blocked') NOT NULL DEFAULT 'active',
  referred_by BIGINT UNSIGNED NULL,
  referral_code VARCHAR(32) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_telegram_id (telegram_id),
  UNIQUE KEY uq_users_referral_code (referral_code),
  KEY idx_users_referred_by (referred_by),
  CONSTRAINT fk_users_referred_by FOREIGN KEY (referred_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS admin_users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  telegram_id VARCHAR(32) NOT NULL,
  role ENUM('owner','admin','moderator') NOT NULL DEFAULT 'admin',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admin_telegram_id (telegram_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS wallets (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  network VARCHAR(16) NOT NULL DEFAULT 'TON',
  address VARCHAR(128) NOT NULL,
  ownership_verified TINYINT(1) NOT NULL DEFAULT 0,
  verified_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_wallet_address (network,address),
  KEY idx_wallet_user (user_id),
  CONSTRAINT fk_wallet_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS level_configs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  level_number INT UNSIGNED NOT NULL,
  min_holding_ast2 DECIMAL(36,9) NOT NULL,
  daily_reward_ast2 DECIMAL(36,9) NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_level_number (level_number),
  CHECK (level_number BETWEEN 1 AND 500),
  CHECK (min_holding_ast2 >= 0),
  CHECK (daily_reward_ast2 >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS holding_snapshots (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  wallet_address VARCHAR(128) NOT NULL,
  jetton_master VARCHAR(128) NOT NULL,
  raw_balance VARCHAR(100) NOT NULL,
  token_decimals TINYINT UNSIGNED NOT NULL,
  balance_ast2 DECIMAL(36,9) NOT NULL,
  checked_at DATETIME NOT NULL,
  provider VARCHAR(40) NOT NULL,
  PRIMARY KEY (id),
  KEY idx_holding_user_time (user_id,checked_at),
  CONSTRAINT fk_holding_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mining_claims (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  level_number INT UNSIGNED NOT NULL,
  holding_snapshot_id BIGINT UNSIGNED NULL,
  reward_ast2 DECIMAL(36,9) NOT NULL,
  claim_date DATE NOT NULL,
  status ENUM('credited','reversed') NOT NULL DEFAULT 'credited',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_mining_user_date (user_id,claim_date),
  KEY idx_mining_date (claim_date),
  CONSTRAINT fk_mining_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_mining_snapshot FOREIGN KEY (holding_snapshot_id) REFERENCES holding_snapshots(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS checkins (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  reward_points DECIMAL(36,9) NOT NULL DEFAULT 0,
  reward_ast2 DECIMAL(36,9) NOT NULL DEFAULT 0,
  checkin_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_checkin_user_date (user_id,checkin_date),
  CONSTRAINT fk_checkin_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS spin_rewards (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  label VARCHAR(80) NOT NULL,
  reward_type ENUM('points','ast2','none') NOT NULL DEFAULT 'points',
  reward_amount DECIMAL(36,9) NOT NULL DEFAULT 0,
  probability DECIMAL(8,5) NOT NULL DEFAULT 0,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CHECK (probability >= 0 AND probability <= 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS spin_history (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  spin_reward_id BIGINT UNSIGNED NULL,
  reward_type ENUM('points','ast2','none') NOT NULL,
  reward_amount DECIMAL(36,9) NOT NULL DEFAULT 0,
  spin_date DATE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_spin_user_date (user_id,spin_date),
  CONSTRAINT fk_spin_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_spin_reward FOREIGN KEY (spin_reward_id) REFERENCES spin_rewards(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS social_tasks (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title VARCHAR(160) NOT NULL,
  description TEXT NULL,
  task_type VARCHAR(40) NOT NULL,
  target_url VARCHAR(500) NULL,
  reward_points DECIMAL(36,9) NOT NULL DEFAULT 0,
  reward_ast2 DECIMAL(36,9) NOT NULL DEFAULT 0,
  verification_type ENUM('manual','link','telegram_check','admin') NOT NULL DEFAULT 'manual',
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  starts_at DATETIME NULL,
  ends_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_tasks_active (is_active,starts_at,ends_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS task_completions (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  task_id BIGINT UNSIGNED NOT NULL,
  user_id BIGINT UNSIGNED NOT NULL,
  status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  proof_url VARCHAR(500) NULL,
  reviewed_by_telegram_id VARCHAR(32) NULL,
  reviewed_at DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_task_user (task_id,user_id),
  KEY idx_task_completion_status (status),
  CONSTRAINT fk_completion_task FOREIGN KEY (task_id) REFERENCES social_tasks(id) ON DELETE CASCADE,
  CONSTRAINT fk_completion_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS allocations (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  source_type ENUM('mining','checkin','spin','task','referral','admin') NOT NULL,
  source_id BIGINT UNSIGNED NULL,
  amount_ast2 DECIMAL(36,9) NOT NULL,
  status ENUM('available','locked','withdrawn','cancelled') NOT NULL DEFAULT 'available',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_alloc_user_status (user_id,status),
  KEY idx_alloc_source (source_type,source_id),
  CONSTRAINT fk_alloc_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS referrals (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  inviter_user_id BIGINT UNSIGNED NOT NULL,
  invited_user_id BIGINT UNSIGNED NOT NULL,
  reward_ast2 DECIMAL(36,9) NOT NULL DEFAULT 0,
  status ENUM('pending','qualified','rewarded','rejected') NOT NULL DEFAULT 'pending',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  qualified_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_referral_invited (invited_user_id),
  KEY idx_referral_inviter (inviter_user_id),
  CONSTRAINT fk_referral_inviter FOREIGN KEY (inviter_user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_referral_invited FOREIGN KEY (invited_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS withdrawals (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  wallet_address VARCHAR(128) NOT NULL,
  amount_ast2 DECIMAL(36,9) NOT NULL,
  status ENUM('pending','approved','rejected','paid','cancelled') NOT NULL DEFAULT 'pending',
  admin_telegram_id VARCHAR(32) NULL,
  admin_note VARCHAR(500) NULL,
  ton_tx_hash VARCHAR(160) NULL,
  requested_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reviewed_at DATETIME NULL,
  paid_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_withdraw_status_date (status,requested_at),
  KEY idx_withdraw_user (user_id),
  CONSTRAINT fk_withdraw_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_settings (
  setting_key VARCHAR(80) NOT NULL,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (setting_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_telegram_id VARCHAR(32) NOT NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(60) NOT NULL,
  entity_id BIGINT UNSIGNED NULL,
  details JSON NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_audit_actor_time (actor_telegram_id,created_at),
  KEY idx_audit_entity (entity_type,entity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO app_settings (setting_key,setting_value) VALUES
 ('token_symbol','AST2'),
 ('token_network','TON_MAINNET'),
 ('jetton_master','EQCO-aQDxDMY80yRMlSGlQN_ecJFV0sdA8U7RWTXbA0vufNx'),
 ('allocation_reserve_ast2','500000000'),
 ('mining_enabled','0'),
 ('withdrawals_enabled','0')
ON DUPLICATE KEY UPDATE setting_key = VALUES(setting_key);
