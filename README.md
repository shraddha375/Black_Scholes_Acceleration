# FPGA-Accelerated Black–Scholes Computation

This repository presents a **hardware acceleration study of the Black–Scholes option pricing model**, using an FPGA implementation to evaluate the latency and accuracy trade-offs relevant to high-frequency trading (HFT) workloads.

The project demonstrates **600×–1000× speedup** over a microcontroller-based software baseline by implementing Black–Scholes entirely in FPGA hardware using fixed-point arithmetic and lookup-table-based function approximation.

> **Note:** The accompanying paper and presentation are included in the [`Documentation/`](Documentation/) folder.

---

## Project Motivation

Low-latency computation is a critical bottleneck in high-frequency trading, where even microsecond-scale delays can impact profitability. While modern HFT systems rely on specialized hardware such as ASICs and FPGAs, these solutions are often expensive and inaccessible outside large institutions.

This project explores how **FPGA-based acceleration of core financial computations** can drastically reduce execution time, motivating the use of specialized hardware for latency-sensitive workloads in edge and embedded contexts.

---

## System Overview

The work evaluates two implementations of the Black–Scholes model:

- **FPGA Accelerator**
  - Black–Scholes implemented entirely in hardware
  - Designed for deterministic, low-latency execution
  - Evaluated using synthesis timing and on-board benchmarking

- **Embedded Software Baseline**
  - Black–Scholes implemented in software on an ESP32
  - Used as a constrained, low-power reference point for comparison

The comparison isolates the performance impact of **hardware specialization**.

---

## FPGA Computation Strategy

The FPGA design prioritizes determinism, simplicity, and resource efficiency:

- **Fixed-Point Arithmetic**
  - Q6.10 and Q4.12 formats
  - Avoids floating-point overhead while maintaining acceptable precision

- **Lookup Tables (LUTs)**
  - Precomputed `exp`, `ln`, `sqrt`, and normal CDF
  - Single-cycle access for nonlinear functions

- **Discrete Computation Stages**
  - Six-stage computation
  - Arithmetic resources reused across stages to minimize area

---

## Performance Summary

### Accuracy
- FPGA results show **~2–3% error** relative to floating-point software
- Error arises from fixed-point quantization and LUT resolution
- Accuracy is sufficient for latency-dominated financial workloads

### Latency & Speedup
- **ESP32 software:** ~300–700 μs per option
- **FPGA hardware:** ~504 ns per option (deterministic)
- **Observed speedup:** 600×–1400×

These results highlight the effectiveness of FPGA acceleration for time-critical numerical computation.

---

## Design Insights

- Fixed-point arithmetic enables substantial latency reduction with modest precision loss
- Lookup-table-based nonlinear functions are effective for deterministic execution
- FSM-based control simplifies timing analysis and resource reuse
- Hardware specialization dominates performance over general-purpose embedded execution

---

## Future Extensions

Next steps include:
- Leveraging FPGA DSP blocks for arithmetic-heavy stages
- Increasing LUT resolution or adaptive sampling
- Scaling to larger FPGAs or additional pricing models
- Integrating the accelerator into a broader embedded or edge system

---
