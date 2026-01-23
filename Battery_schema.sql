-- Recommended: use InnoDB for FK support
-- Make sure your DB default engine is InnoDB.

-- 1) 資料層：電池/Pack/Cell
CREATE TABLE battery_pack (
  pack_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  pack_code VARCHAR(64) UNIQUE,
  chemistry VARCHAR(64),     -- NMC, LFP
  nominal_capacity_ah FLOAT,
  nominal_voltage_v FLOAT,
  note TEXT
) ENGINE=InnoDB;

CREATE TABLE battery_cell (
  cell_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  pack_id BIGINT NOT NULL,
  cell_code VARCHAR(64) UNIQUE,
  position_in_pack VARCHAR(32), -- e.g., P01, S03
  nominal_capacity_ah FLOAT,
  nominal_voltage_v FLOAT,
  note TEXT,
  INDEX idx_cell_pack (pack_id),
  CONSTRAINT fk_cell_pack
    FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 2) 實驗層：一次測試/一次記錄
CREATE TABLE test_session (
  session_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  asset_type ENUM('PACK','CELL') NOT NULL,
  pack_id BIGINT NULL,
  cell_id BIGINT NULL,
  rig VARCHAR(64),
  operator VARCHAR(64),
  start_time DATETIME,
  end_time DATETIME,
  ambient_temp_c FLOAT,
  protocol_name VARCHAR(128),
  protocol_version VARCHAR(64),
  note TEXT,
  INDEX idx_sess_pack (pack_id),
  INDEX idx_sess_cell (cell_id),
  CONSTRAINT fk_sess_pack
    FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sess_cell
    FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- NOTE (document rule):
-- asset_type='PACK' => pack_id NOT NULL and cell_id IS NULL
-- asset_type='CELL' => cell_id NOT NULL and pack_id IS NULL (or pack_id optional if you want redundancy)

-- 3) 循環層：cycle-level
CREATE TABLE test_cycle (
  cycle_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT NOT NULL,
  cycle_index INT NOT NULL,            -- 1..N
  mode ENUM('CHG','DIS','MIX') NOT NULL,
  start_time DATETIME,
  end_time DATETIME,
  UNIQUE KEY uq_cycle (session_id, cycle_index),
  INDEX idx_cycle_session (session_id),
  CONSTRAINT fk_cycle_session
    FOREIGN KEY (session_id) REFERENCES test_session(session_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 4) 時序層：原始量測（建議統一用 ts_ms）
CREATE TABLE timeseries_point (
  point_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT NOT NULL,
  cycle_id BIGINT NULL,
  ts_ms BIGINT NOT NULL,               -- epoch ms
  t_s FLOAT NULL,                      -- optional, relative time
  v_v FLOAT,
  i_a FLOAT,
  temp_c FLOAT,
  soc_ref FLOAT,
  note TEXT,
  INDEX idx_ts_session_time (session_id, ts_ms),
  INDEX idx_ts_cycle_time (cycle_id, ts_ms),
  CONSTRAINT fk_ts_session
    FOREIGN KEY (session_id) REFERENCES test_session(session_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ts_cycle
    FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 5) 特徵層
CREATE TABLE cycle_feature (
  feat_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  cycle_id BIGINT NOT NULL,
  q_discharge_ah FLOAT,
  e_discharge_wh FLOAT,
  v_min_v FLOAT,
  v_avg_v FLOAT,
  v_end_v FLOAT,
  temp_max_c FLOAT,
  r_internal_mohm FLOAT,
  dVdQ FLOAT,
  UNIQUE KEY uq_feat_cycle (cycle_id),
  CONSTRAINT fk_feat_cycle
    FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 6) 標籤層：SOC / SOH
CREATE TABLE label_soc (
  soc_label_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  session_id BIGINT NOT NULL,
  point_id BIGINT NOT NULL,
  soc_value FLOAT NOT NULL,
  definition VARCHAR(64),
  UNIQUE KEY uq_soc_point (point_id, definition),
  INDEX idx_soc_session (session_id),
  CONSTRAINT fk_soc_session
    FOREIGN KEY (session_id) REFERENCES test_session(session_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_soc_point
    FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE label_soh (
  soh_label_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  asset_type ENUM('PACK','CELL') NOT NULL,
  pack_id BIGINT NULL,
  cell_id BIGINT NULL,
  cycle_id BIGINT NOT NULL,
  soh_value FLOAT NOT NULL,
  definition VARCHAR(64),
  ref_capacity_ah FLOAT,
  INDEX idx_soh_cycle (cycle_id),
  INDEX idx_soh_pack (pack_id),
  INDEX idx_soh_cell (cell_id),
  CONSTRAINT fk_soh_pack
    FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_soh_cell
    FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_soh_cycle
    FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- 7) 模型層
CREATE TABLE model_run (
  run_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  task ENUM('SOC','SOH') NOT NULL,
  model_name VARCHAR(128) NOT NULL,
  data_version VARCHAR(64),
  train_start_time DATETIME,
  train_end_time DATETIME,
  metric_json JSON NULL,
  note TEXT
) ENGINE=InnoDB;

CREATE TABLE prediction (
  pred_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_id BIGINT NOT NULL,
  session_id BIGINT NULL,
  cycle_id BIGINT NULL,
  point_id BIGINT NULL,
  target ENUM('SOC','SOH') NOT NULL,
  y_pred FLOAT NOT NULL,
  y_true FLOAT NULL,
  INDEX idx_pred_run (run_id),
  INDEX idx_pred_session (session_id),
  INDEX idx_pred_cycle (cycle_id),
  INDEX idx_pred_point (point_id),
  CONSTRAINT fk_pred_run
    FOREIGN KEY (run_id) REFERENCES model_run(run_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pred_session
    FOREIGN KEY (session_id) REFERENCES test_session(session_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_pred_cycle
    FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_pred_point
    FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Heat data update (your thermal simulation table)
CREATE TABLE battery_thermal_ts (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  run_id VARCHAR(64) NOT NULL,
  ts_ms BIGINT NOT NULL,
  current_a FLOAT,
  voltage_v FLOAT,
  soc FLOAT,
  temp_cell_c FLOAT,
  temp_ambient_c FLOAT,
  temp_rise_rate FLOAT,
  INDEX idx_run_ts (run_id, ts_ms)
) ENGINE=InnoDB;
