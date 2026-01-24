**Black–Scholes Option Pricing (FPGA Implementation)**

Implemented a hardware-oriented Black–Scholes option pricing engine using a finite state machine (FSM) control structure to sequence the computation deterministically. The design evaluates European call and put prices using fixed-point arithmetic, emphasizing predictable execution, numerical stability, and explicit control over intermediate operations.

Rather than deeply pipelining the computation, the system was structured as a modular FSM with clearly defined computation stages, enabling straightforward pipelining or parallelization in future revisions. Key considerations included fixed-point error management, state-level resource reuse, and accuracy–latency tradeoffs when mapping a continuous financial model onto constrained digital hardware.

Whitepaper and Project Presenation Slides are included in _Documentation_ folder.

## ESP32 Wi-Fi Provisioning (Prototype)

This branch contains prototype Wi-Fi provisioning code for the ESP32,
including access-point–based credential setup and non-volatile storage.

This functionality was explored during development but was **not used in the
final HFT device implementation**, which prioritizes deterministic startup
and a minimal runtime footprint.

The final project code remains on the `main` branch.
