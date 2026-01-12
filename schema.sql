-- SOC/SOH Base Schema (ERD-focus)

-- 1) 資產層：電池/Pack/Cell 基本資料
CREATE TABLE battery_pack (
  pack_id INT,
  pack_code VARCHAR(64),
  chemistry VARCHAR(64),     -- e.g., NMC, LFP
  nominal_capacity_ah FLOAT, -- rated capacity
  nominal_voltage_v FLOAT,
  note TEXT,
  PRIMARY KEY (pack_id)
);

CREATE TABLE battery_cell (
  cell_id INT,
  pack_id INT,
  cell_code VARCHAR(64),
  position_in_pack VARCHAR(32), -- e.g., P01, S03
  nominal_capacity_ah FLOAT,
  nominal_voltage_v FLOAT,
  note TEXT,
  PRIMARY KEY (cell_id),
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id)
);

-- 2) 實驗層：一次測試/一次記錄（可追溯batch）
CREATE TABLE test_session (
  session_id INT,
  asset_type VARCHAR(16),     -- 'PACK' or 'CELL'
  pack_id INT,
  cell_id INT,
  rig VARCHAR(64),            -- tester name/model
  operator VARCHAR(64),
  start_time DATETIME,
  end_time DATETIME,
  ambient_temp_c FLOAT,
  protocol_name VARCHAR(128), -- HPPC, UDDS, DST, etc.
  protocol_version VARCHAR(64),
  note TEXT,
  PRIMARY KEY (session_id),
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id),
  FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id)
);

-- 3) 循環層：cycle-level（SOH 特徵層）
CREATE TABLE cycle (
  cycle_id INT,
  session_id INT,
  cycle_index INT,            -- 1..N
  mode VARCHAR(16),           -- 'CHG','DIS','MIX'
  start_time DATETIME,
  end_time DATETIME,
  PRIMARY KEY (cycle_id),
  FOREIGN KEY (session_id) REFERENCES test_session(session_id)
);

-- 4) 時序層：原始量測
CREATE TABLE timeseries_point (
  point_id INT,
  session_id INT,
  cycle_id INT,
  t_s FLOAT,                  -- time (s)
  v_v FLOAT,                  -- voltage (V)
  i_a FLOAT,                  -- current (A)
  temp_c FLOAT,               -- temperature (C)
  soc_ref FLOAT,              -- 若有 ground truth / coulomb counting
  note TEXT,
  PRIMARY KEY (point_id),
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (cycle_id) REFERENCES cycle(cycle_id)
);

-- 5) 特徵層：由 timeseries/cycle 計算出來的特徵（ML 訓練用）
CREATE TABLE cycle_feature (
  feat_id INT,
  cycle_id INT,
  q_discharge_ah FLOAT,        -- discharge capacity (Ah)
  e_discharge_wh FLOAT,        -- discharge energy (Wh)
  v_min_v FLOAT,
  v_avg_v FLOAT,
  v_end_v FLOAT,
  temp_max_c FLOAT,
  r_internal_mohm FLOAT,       -- e.g., from pulse (HPPC) or fitting
  dVdQ FLOAT,                  -- optional
  PRIMARY KEY (feat_id),
  FOREIGN KEY (cycle_id) REFERENCES cycle(cycle_id)
);

-- 6) 標籤層：SOC / SOH 目標值
CREATE TABLE label_soc (
  soc_label_id INT,
  session_id INT,
  point_id INT,
  soc_value FLOAT,             -- 0~1 (or 0~100)
  definition VARCHAR(64),      -- 'coulomb_count', 'OCV_lookup', 'BMS_ref'
  PRIMARY KEY (soc_label_id),
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
);

CREATE TABLE label_soh (
  soh_label_id INT,
  asset_type VARCHAR(16),      -- 'PACK' or 'CELL'
  pack_id INT,
  cell_id INT,
  cycle_id INT,
  soh_value FLOAT,             -- 0~1 (or 0~100)
  definition VARCHAR(64),      -- 'capacity_ratio', 'resistance_ratio', etc.
  ref_capacity_ah FLOAT,       -- baseline capacity for ratio
  PRIMARY KEY (soh_label_id),
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id),
  FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id),
  FOREIGN KEY (cycle_id) REFERENCES cycle(cycle_id)
);

-- 7) 模型層：訓練/推論可追溯
CREATE TABLE model_run (
  run_id INT,
  task VARCHAR(16),            -- 'SOC' or 'SOH'
  model_name VARCHAR(128),
  data_version VARCHAR(64),    -- e.g., SQL view version / dataset tag
  train_start_time DATETIME,
  train_end_time DATETIME,
  metric_json TEXT,
  note TEXT,
  PRIMARY KEY (run_id)
);

CREATE TABLE prediction (
  pred_id INT,
  run_id INT,
  session_id INT,
  cycle_id INT,
  point_id INT,
  target VARCHAR(16),          -- 'SOC' or 'SOH'
  y_pred FLOAT,
  y_true FLOAT,
  PRIMARY KEY (pred_id),
  FOREIGN KEY (run_id) REFERENCES model_run(run_id),
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (cycle_id) REFERENCES cycle(cycle_id),
  FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
);
