-- ============================================================
-- Liam ERD Schema (ERD-only, parser-friendly)
-- Purpose: SOC / SOH data platform conceptual model
-- Note: This version is for ERD & documentation ONLY
-- ============================================================

-- 1) Asset Layer: Battery Pack / Cell
CREATE TABLE battery_pack (
  pack_id BIGINT PRIMARY KEY,
  pack_code VARCHAR(64),
  chemistry VARCHAR(64),              -- NMC, LFP
  nominal_capacity_ah FLOAT,
  nominal_voltage_v FLOAT,
  note TEXT
);

CREATE TABLE battery_cell (
  cell_id BIGINT PRIMARY KEY,
  pack_id BIGINT,
  cell_code VARCHAR(64),
  position_in_pack VARCHAR(32),       -- e.g. P01, S03
  nominal_capacity_ah FLOAT,
  nominal_voltage_v FLOAT,
  note TEXT,
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id)
);

-- ============================================================
-- 2) Experiment Layer: Test Session (traceable batch)
-- ============================================================
CREATE TABLE test_session (
  session_id BIGINT PRIMARY KEY,
  asset_type VARCHAR(16),             -- PACK or CELL
  pack_id BIGINT,
  cell_id BIGINT,
  rig VARCHAR(64),                    -- tester name/model
  operator VARCHAR(64),
  start_time DATETIME,
  end_time DATETIME,
  ambient_temp_c FLOAT,
  protocol_name VARCHAR(128),         -- HPPC, UDDS, DST
  protocol_version VARCHAR(64),
  note TEXT,
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id),
  FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id)
);

-- ============================================================
-- 3) Cycle Layer: Cycle-level structure (SOH base)
-- ============================================================
CREATE TABLE test_cycle (
  cycle_id BIGINT PRIMARY KEY,
  session_id BIGINT,
  cycle_index INT,                    -- 1..N
  mode VARCHAR(16),                   -- CHG / DIS / MIX
  start_time DATETIME,
  end_time DATETIME,
  FOREIGN KEY (session_id) REFERENCES test_session(session_id)
);

-- ============================================================
-- 4) Timeseries Layer: Raw measurement points
-- ============================================================
CREATE TABLE timeseries_point (
  point_id BIGINT PRIMARY KEY,
  session_id BIGINT,
  cycle_id BIGINT,
  ts_ms BIGINT,                       -- epoch time (ms)
  t_s FLOAT,                          -- relative time (s)
  v_v FLOAT,                          -- voltage (V)
  i_a FLOAT,                          -- current (A)
  temp_c FLOAT,                       -- temperature (°C)
  soc_ref FLOAT,                      -- reference SOC (if available)
  note TEXT,
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
);

-- ============================================================
-- 5) Feature Layer: Derived cycle features (ML input)
-- ============================================================
CREATE TABLE cycle_feature (
  feat_id BIGINT PRIMARY KEY,
  cycle_id BIGINT,
  q_discharge_ah FLOAT,
  e_discharge_wh FLOAT,
  v_min_v FLOAT,
  v_avg_v FLOAT,
  v_end_v FLOAT,
  temp_max_c FLOAT,
  r_internal_mohm FLOAT,
  dVdQ FLOAT,
  FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
);

-- ============================================================
-- 6) Label Layer: SOC / SOH targets
-- ============================================================
CREATE TABLE label_soc (
  soc_label_id BIGINT PRIMARY KEY,
  session_id BIGINT,
  point_id BIGINT,
  soc_value FLOAT,
  definition VARCHAR(64),             -- coulomb_count / OCV_lookup / BMS_ref
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
);

CREATE TABLE label_soh (
  soh_label_id BIGINT PRIMARY KEY,
  asset_type VARCHAR(16),             -- PACK or CELL
  pack_id BIGINT,
  cell_id BIGINT,
  cycle_id BIGINT,
  soh_value FLOAT,
  definition VARCHAR(64),             -- capacity_ratio / resistance_ratio
  ref_capacity_ah FLOAT,
  FOREIGN KEY (pack_id) REFERENCES battery_pack(pack_id),
  FOREIGN KEY (cell_id) REFERENCES battery_cell(cell_id),
  FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id)
);

-- ============================================================
-- 7) Model Layer: Training / Inference traceability
-- ============================================================
CREATE TABLE model_run (
  run_id BIGINT PRIMARY KEY,
  task VARCHAR(16),                   -- SOC or SOH
  model_name VARCHAR(128),
  data_version VARCHAR(64),
  train_start_time DATETIME,
  train_end_time DATETIME,
  metric_json TEXT,
  note TEXT
);

CREATE TABLE prediction (
  pred_id BIGINT PRIMARY KEY,
  run_id BIGINT,
  session_id BIGINT,
  cycle_id BIGINT,
  point_id BIGINT,
  target VARCHAR(16),                 -- SOC or SOH
  y_pred FLOAT,
  y_true FLOAT,
  FOREIGN KEY (run_id) REFERENCES model_run(run_id),
  FOREIGN KEY (session_id) REFERENCES test_session(session_id),
  FOREIGN KEY (cycle_id) REFERENCES test_cycle(cycle_id),
  FOREIGN KEY (point_id) REFERENCES timeseries_point(point_id)
);

-- ============================================================
-- 8) Thermal Simulation Timeseries (PoC / Independent)
-- ============================================================
CREATE TABLE battery_thermal_ts (
  id BIGINT PRIMARY KEY,
  run_id VARCHAR(64),
  ts_ms BIGINT,
  current_a FLOAT,
  voltage_v FLOAT,
  soc FLOAT,
  temp_cell_c FLOAT,
  temp_ambient_c FLOAT,
  temp_rise_rate FLOAT
);
