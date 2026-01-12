# liam-erd-schema
Battery base schema for Liam ERD

# Battery SOC / SOH Data Schema

This repository defines a structured and extensible database schema for
**State of Charge (SOC)** and **State of Health (SOH)** estimation in battery systems.

The schema is designed to support:
- Battery testing and aging experiments
- Machine learning and data-driven modeling
- Full traceability from raw measurements to model predictions
- Both research and industry-oriented workflows

This project focuses on **data clarity, reproducibility, and scalability**.

---

## 1. Design Philosophy

The schema follows several core principles:

- **Layered structure**  
  Raw data, features, labels, and model results are clearly separated.
- **Traceability**  
  Every data point and prediction can be traced back to a test session and asset.
- **SOC / SOH separation**  
  SOC and SOH have different time scales and data characteristics and are modeled accordingly.
- **Model-agnostic**  
  The schema does not assume any specific algorithm (e.g., LSTM, GPR, CNN).

---

## 2. Schema Layers Overview

The database schema is organized into the following logical layers:

| Layer | Description | Tables |
|-----|------------|--------|
| Asset Layer | Battery hardware metadata | `battery_pack`, `battery_cell` |
| Experiment Layer | Test batch and protocol definition | `test_session` |
| Cycle Layer | Charge/discharge cycles | `cycle` |
| Time-series Layer | High-frequency measurements | `timeseries_point` |
| Feature Layer | Extracted cycle-level features | `cycle_feature` |
| Label Layer | SOC / SOH ground truth | `label_soc`, `label_soh` |
| Model Layer | Training & inference traceability | `model_run`, `prediction` |

---

## 3. Asset Layer

### battery_pack
Stores metadata of battery packs.

Key attributes:
- Chemistry (e.g., NMC, LFP)
- Nominal capacity and voltage

### battery_cell
Defines individual cells and their relationship to a battery pack.

Typical usage:
- Cell-level SOH modeling
- Pack-to-cell degradation analysis

---

## 4. Experiment Layer

### test_session
Defines a single test batch or experiment.

This table is critical for traceability and experiment management.

Examples:
- HPPC test at 25°C
- DST aging test at elevated temperature

Key attributes:
- Test protocol name and version
- Test equipment
- Ambient conditions
- Asset under test (pack or cell)

---

## 5. Cycle Layer

### cycle
Represents charge/discharge cycles within a test session.

Typical usage:
- Tracking aging trends over cycle index
- Linking SOH features to specific cycles

---

## 6. Time-series Layer (SOC-oriented)

### timeseries_point
Stores raw, high-frequency measurements.

Typical signals:
- Voltage
- Current
- Temperature
- Time

This table is the **primary input source for SOC estimation models**.

Optional reference SOC values (e.g., coulomb counting or BMS reference) can be stored for supervised learning.

---

## 7. Feature Layer (SOH-oriented)

### cycle_feature
Stores features extracted from time-series data at the cycle level.

Common SOH-related features:
- Discharge capacity
- Discharge energy
- Internal resistance
- Voltage statistics
- Temperature extremes

This table is the **primary input source for SOH estimation models**.

---

## 8. Label Layer

### label_soc
Defines SOC ground truth values.

- Typically linked to individual time-series points
- Supports multiple SOC definitions (e.g., coulomb counting, OCV-based)

### label_soh
Defines SOH ground truth values.

- Typically linked to cycles
- Supports multiple SOH definitions:
  - Capacity-based SOH
  - Resistance-based SOH

---

## 9. Model and Prediction Tracking

### model_run
Tracks model training and evaluation metadata.

Stored information:
- Task type (SOC or SOH)
- Model name
- Dataset version
- Training time
- Evaluation metrics

### prediction
Stores model prediction results.

Supports:
- Point-level SOC predictions
- Cycle-level SOH predictions
- Comparison between predicted and true values

This enables full **model reproducibility and auditability**.

---

## 10. SOC vs SOH Usage Summary

| Table | Used for SOC | Used for SOH |
|-----|-------------|--------------|
| timeseries_point | ✓ | |
| cycle_feature | | ✓ |
| label_soc | ✓ | |
| label_soh | | ✓ |
| test_session | ✓ | ✓ |
| battery_pack | ✓ | ✓ |
| battery_cell | ✓ | ✓ |
| model_run | ✓ | ✓ |
| prediction | ✓ | ✓ |

---

## 11. Typical Data Flow

1. Battery assets are registered (`battery_pack`, `battery_cell`)
2. A test session is created (`test_session`)
3. Raw measurements are recorded (`timeseries_point`)
4. Cycles are segmented (`cycle`)
5. Features are extracted (`cycle_feature`)
6. SOC / SOH labels are assigned (`label_soc`, `label_soh`)
7. Models are trained and evaluated (`model_run`)
8. Predictions are stored and analyzed (`prediction`)

---

## 12. Intended Use Cases

- Battery SOC estimation under dynamic load
- Battery SOH estimation and aging analysis
- Data pipeline development for BMS algorithms
- Research experiments and reproducible ML studies
- Industry-grade battery data management

---

## 13. Notes

- This repository focuses on **schema definition and data structure**, not on specific models.
- SQL files provided are intended for:
  - ERD visualization
  - Schema documentation
  - Database implementation reference

---

## License
To be defined by the project owner.
