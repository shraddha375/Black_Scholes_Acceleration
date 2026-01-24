## **Black–Scholes Option Pricing (FPGA Implementation)**

Implemented a hardware-oriented Black–Scholes option pricing engine using a finite state machine (FSM) control structure to sequence the computation deterministically. The design evaluates European call and put prices using fixed-point arithmetic, emphasizing predictable execution, numerical stability, and explicit control over intermediate operations.

Rather than deeply pipelining the computation, the system was structured as a modular FSM with clearly defined computation stages, enabling straightforward pipelining or parallelization in future revisions. Key considerations included fixed-point error management, state-level resource reuse, and accuracy–latency tradeoffs when mapping a continuous financial model onto constrained digital hardware.

Whitepaper and Project Presenation Slides are included in _Documentation_ folder.
