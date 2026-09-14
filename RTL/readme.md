# `black_scholes.sv`

This SystemVerilog module implements a **Black-Scholes European Call Option Pricing Engine**. It integrates all the mathematical building blocks analyzed previously (`ln`, `sqrt`, `exp`, and `norm_cdf`) into a pipelined **Finite State Machine (FSM)**.

---

### Black-Scholes Mathematical Formula

The hardware evaluates the standard European Call Option formula:

$$C = S \cdot N(d_1) - K \cdot e^{-rT} \cdot N(d_2)$$

Where intermediate terms $d_1$ and $d_2$ are defined as:

$$d_1 = \frac{\ln(S/K) + \left(r + \frac{\sigma^2}{2}\right)T}{\sigma \sqrt{T}}, \quad d_2 = d_1 - \sigma \sqrt{T}$$

#### Inputs & Financial Variables

* `S`: Current Asset/Stock Price (Q6.10)
* `K`: Strike Price (Q6.10)
* `r`: Risk-Free Interest Rate (Q6.10)
* `sigma` ($\sigma$): Volatility (Q6.10)
* `T`: Time to Maturity in years (Q6.10)

---

### Format Alignment: Q6.10 vs Q4.12

The top-level inputs/outputs and most submodules (`ln`, `sqrt`, `exp`) use **Q6.10 fixed-point arithmetic** ($1.0 = 1024$).

However, the `norm_cdf` module expects a **Q4.12 input** ($1.0 = 4096$).
To convert Q6.10 data to Q4.12 before feeding `norm_cdf`, the module shifts the values left by 2 bits (`<<< 2`, since $2^2 = 4$). To shift `norm_cdf` outputs back to Q6.10, it shifts right by 2 bits (`>>> 2`).

---

### Step-by-Step FSM State Execution

The FSM controls a 4-stage pipeline that computes independent terms in parallel before accumulating the final option price.

```
+------+    +-------+    +-------+    +-------+    +-------+    +------+
| IDLE | -> | CALC1 | -> | CALC2 | -> | CALC3 | -> | CALC4 | -> | DONE |
+------+    +-------+    +-------+    +-------+    +-------+    +------+

```

#### 1. State `CALC1`: Base Sub-Calculations

```systemverilog
ln_input   <= (S <<< 10) / K;
sqrt_input <= T;
rate_term  <= r + ((sig_inter * sig_inter) >>> 11);

```

* **$\ln(S/K)$ Prep:** Multiplies $S$ by $1024$ (`<<< 10`) before dividing by $K$ to preserve fixed-point precision. The result is fed to `ln_inst`.
* **$\sqrt{T}$ Prep:** Feeds $T$ directly into `sqrt_inst`.
* **Rate Term ($r + \frac{\sigma^2}{2}$):** Squaring $\sigma$ yields $Q12.20$. Shifting right by 11 divides by $2 \times 1024 = 2048$, leaving a Q6.10 value for $\frac{\sigma^2}{2}$.

#### 2. State `CALC2`: $d_1$ Numerator & Denominator

```systemverilog
numerator <= ((rate_term * T) >>> 10) + ln_result;
denom     <= (sig_inter * sqrt_result) >>> 10;

```

* **Numerator:** Multiplies $(r + \frac{\sigma^2}{2})$ by $T$, scales down by 1024 (`>>> 10`), and adds the output from `ln_inst` ($\ln(S/K)$).
* **Denominator:** Multiplies $\sigma$ by the output from `sqrt_inst` ($\sqrt{T}$) and rescales to Q6.10.

#### 3. State `CALC3`: Term Computation ($d_1$, $d_2$, Discount, $N(d)$)

```systemverilog
exp_input   <= -((r_inter * T) >>> 10);
norm1_input <= ((numerator <<< 10) / denom) <<< 2;
norm2_input <= (((numerator <<< 10) / denom) - denom) <<< 2;

```

* **Discount Factor ($e^{-rT}$):** Computes $-r \cdot T$ in Q6.10 and feeds it into `exp_inst`.
* **$d_1$ Calculation:** Computes $\frac{\text{numerator}}{\text{denominator}}$ and converts Q6.10 to Q4.12 (`<<< 2`) for `norm1` ($N(d_1)$).
* **$d_2$ Calculation:** Computes $d_1 - \text{denominator}$ ($\sigma \sqrt{T}$) and converts to Q4.12 (`<<< 2`) for `norm2` ($N(d_2)$).

#### 4. State `CALC4`: Final Call Price Assembly

```systemverilog
call_price <= ((s_inter * (norm1_result >>> 2)) >>> 10)
            - (((k_inter * exp_result) >>> 10) * (norm2_result >>> 2) >>> 10);

```

Evaluates the final formula:

1. **Stock Term:** $S \cdot N(d_1)$
2. **Strike Term:** $K \cdot e^{-rT} \cdot N(d_2)$
3. **Subtraction:** Subtracts the strike term from the stock term to yield `call_price`.

#### 5. State `DONE`

* Asserts the `done` high signal indicating the computation is complete and `call_price` is valid.

---

### Summary of Module Architecture

| Pipeline Stage | Mathematical Operations Executed | Modules Triggered |
| --- | --- | --- |
| **`CALC1`** | $S/K$, $r + \sigma^2/2$ | `ln_inst`, `sqrt_inst` |
| **`CALC2`** | $\ln(S/K) + (r + \sigma^2/2)T$, $\sigma\sqrt{T}$ | Combinational Dividers/Multipliers |
| **`CALC3`** | $-rT$, $d_1 = \text{Num}/\text{Denom}$, $d_2 = d_1 - \text{Denom}$ | `exp_inst`, `norm1`, `norm2` |
| **`CALC4`** | $S \cdot N(d_1) - K \cdot e^{-rT} \cdot N(d_2)$ | Final Output Register |

# `norm_cdf.sv`

This SystemVerilog module computes the **Cumulative Distribution Function (CDF) of a Normal Distribution** $\Phi(x)$ over the range $x \in [-5.0, 5.0]$ using a **Look-Up Table (LUT) with Linear Interpolation**.

Unlike other modules, this code uses a **Q4.12 fixed-point format** and performs piecewise-linear interpolation to improve calculation precision between ROM entries.

---

### Core Data Representation (Q4.12 Format)

The module operates using **16-bit signed Q4.12 fixed-point arithmetic**:

* **1 Sign Bit:** Represents positive/negative sign.
* **3 Integer Bits:** Represent whole numbers.
* **12 Fractional Bits:** Provide a scaling factor of $2^{12} = 4096$.

Because $1.0 = 4096$, real numbers translate to integers by multiplying by $4096$:

* **$x = 0.0$:** $0.0 \times 4096 = \mathbf{0}$
* **$x = -5.0$:** $-5.0 \times 4096 = \mathbf{-20480}$ (or `-5 <<< 12`)
* **$x = +5.0$:** $+5.0 \times 4096 = \mathbf{20480}$ (or `5 <<< 12`)

---

### Mathematical Domain & Output Range

The standard normal CDF $\Phi(x)$ measures probability:

* **Lower Bound ($x = -5.0$):** $\Phi(-5.0) \approx 0.00000029 \rightarrow \text{Q4.12 value } \mathbf{0}$
* **Center ($x = 0.0$):** $\Phi(0.0) = 0.5 \rightarrow 0.5 \times 4096 = \mathbf{2048}$
* **Upper Bound ($x = +5.0$):** $\Phi(+5.0) \approx 0.9999997 \rightarrow 1.0 \times 4096 = \mathbf{4096}$

The output value probability range $[0.0, 1.0]$ fits within $[0, 4096]$ in Q4.12 precision.

---

### Step-by-Step Code Walkthrough

#### 1. Input Clamping (Domain Enforcement)

```
logic signed [15:0] x_clamped;
always_comb begin
    if (x_in < -16'sd20480)
        x_clamped = (-5 <<< 12);
    else if (x_in > (5 <<< 12))
        x_clamped = (5 <<< 12);
    else
        x_clamped = x_in;
end

```

* **Domain Limit ($[-5.0, 5.0]$):** Beyond $\pm 5.0$ standard deviations, the normal CDF is effectively $0.0$ or $1.0$.
* **Implementation:** `5 <<< 12` dynamically shifts the integer $5$ by 12 bits to produce `20480`. Any input lower than `-20480` or higher than `20480` is clamped to prevent memory lookup overflow.

---

#### 2. Address & Fractional Offset Calculation

```
logic signed [16:0] x_offset;
always_comb begin
    x_offset = x_clamped + (5 <<< 12); // Shift range to [0, 10.0]
end

logic [9:0] addr;
logic [5:0] frac;
always_comb begin
    addr = x_offset / 80;
    frac = x_offset % 80;
end

```

* **Domain Shift:** Adding `20480` shifts the input domain from $[-5.0, +5.0]$ to $[0.0, 10.0]$ (`0` to `40960` in Q4.12). A 17-bit register (`x_offset`) is used to prevent signed overflow during addition.
   * **Base Address (`addr`):** Dividing by `80` divides the domain into steps of $\frac{80}{4096} \approx 0.01953$.
* Max address: $40960 \div 80 = \mathbf{512}$ (requires a **513-entry ROM**).


* **Fractional Part (`frac`):** The modulo operator `% 80` extracts the remainder (range $[0, 79]$), representing the distance between the lower ROM entry (`val1`) and upper ROM entry (`val2`).

---

#### 3. Dual-Port ROM Lookup & Linear Interpolation

```
logic [15:0] val1, val2;
norm_rom lut (
    .addr(addr),
    .val1(val1),
    .val2(val2)
); 

logic signed [15:0] delta;
logic signed [21:0] interp_mult;
logic signed [15:0] interp;

always_comb begin
    delta       = val2 - val1;
    interp_mult = delta * frac;       // Q4.12 * Q0.6 = Q4.18
    interp      = interp_mult >>> 6;  // Shift back to Q4.12
    n_out       = val1 + interp;      // Final interpolated output
end

```

* **Dual Readout (`norm_rom`):** Returns two consecutive table values: `val1` (value at `addr`) and `val2` (value at `addr + 1`).
* **Linear Interpolation Formula:**

    $$y = y_1 + (y_2 - y_1) \times \frac{\text{remainder}}{\text{stepSize}}$$


* **Fixed-Point Math Breakdown:**
1. `delta = val2 - val1`: Difference between adjacent ROM points ($Q4.12$).
2. `interp_mult = delta * frac`: Multiplies delta by the fractional offset ($Q4.12 \times Q0.6 = Q4.18$).
3. `interp = interp_mult >>> 6`: Arithmetic right-shift by 6 scales the product back to $Q4.12$ precision (equivalent to dividing by the step-size weighting factor).
4. `n_out = val1 + interp`: Adds the fractional offset to `val1` for the final interpolated result.
---


# `sqrt.sv`

This SystemVerilog module computes the **square root ($\sqrt{x}$)** for inputs in the range $[0.0, 16.0]$ using a **Look-Up Table (LUT)** approach. Like the previous modules, it uses fixed-point arithmetic to convert non-integer values into ROM addresses.

---

### Core Data Representation (Q6.10 Format)

The module operates using **16-bit signed Q6.10 fixed-point arithmetic**:

* **1 Sign Bit:** Represents positive/negative sign.
* **5 Integer Bits:** Represent whole numbers.
* **10 Fractional Bits:** Provide a scale factor of $2^{10} = 1024$.

Because $1.0 = 1024$, real numbers are converted to fixed-point by multiplying by $1024$:

* **$x = 0.0$:** $0.0 \times 1024 = \mathbf{0}$
* **$x = 16.0$:** $16.0 \times 1024 = \mathbf{16384}$

---

### Mathematical Domain & Output Range

The module evaluates $\sqrt{x}$ over the domain $x \in [0.0, 16.0]$:

* **Lower Bound ($x = 0.0$):** $\sqrt{0.0} = 0.0 \rightarrow \text{Q6.10 value } \mathbf{0}$
* **Upper Bound ($x = 16.0$):** $\sqrt{16.0} = 4.0 \rightarrow \text{Q6.10 value } \mathbf{4096}$

Both the input range and output values fit comfortably within the signed 16-bit Q6.10 range (maximum value $31.999$).

---

### Step-by-Step Code Walkthrough

#### 1. Input Clamping (Domain Enforcement)

```
logic signed [15:0] x_clamped;
always_comb begin
    if (x_in < 16'sd0)
        x_clamped = 16'sd0;
    else if (x_in > 16'sd16384)
        x_clamped = 16'sd16384;
    else
        x_clamped = x_in;
end

```

* **Why Clamp?** The real square root function $\sqrt{x}$ is undefined for negative numbers ($x < 0$).
* **Lower Limit (`0`):** Prevents imaginary results or errors from negative inputs.
* **Upper Limit (`16384`):** Caps the domain at $16.0$ to ensure memory lookups remain within the ROM size limits.

---

#### 2. Address Calculation (Hardware-Friendly Optimization)

```
logic [15:0] index;
logic [9:0]  addr;

always_comb begin
    index = x_clamped;
    addr  = index / 32;
end

```

* **No Shift Needed:** Since the domain starts at zero ($0.0$), `index` directly equals `x_clamped` without needing base-subtraction offset logic.
* **Power-of-Two Division (`index / 32`):**
* A step size of `32` in Q6.10 corresponds to a real-number step of:

$$\frac{32}{1024} = 0.03125$$


* **Synthesis Optimization:** Because $32 = 2^5$, dividing by 32 in hardware does **not** require a costly arithmetic divider circuit! Synthesis tools will automatically replace `index / 32` with a zero-cost bit-shift: `index >> 5`.


* **Address Range Analysis:**
* Minimum Address ($x = 0.0$): $0 \div 32 = \mathbf{0}$
* Maximum Address ($x = 16.0$): $16384 \div 32 = \mathbf{512}$
* Total ROM Size: **513 entries** (Addresses `0` through `512`).



---

#### 3. ROM Lookup & Direct Output Mapping

```
sqrt_rom rom_inst (
    .addr(addr),
    .out(sqrt_out)
);

```

* Instantiates `sqrt_rom`, a 513-entry ROM pre-loaded with Q6.10 square-root values.
* Reads the output corresponding to `addr` and assigns it directly to `sqrt_out`.

# `exp.sv`

This SystemVerilog module computes the **exponential function ($e^x$)** for non-positive inputs ($x \le 0$) using a **Look-Up Table (LUT)** approach. It uses fixed-point arithmetic to map real decimal values into integer indices for a Read-Only Memory (ROM).

---

### Core Data Representation (Q6.10 Format)

The module operates in **16-bit signed Q6.10 fixed-point arithmetic**:

* **1 Sign Bit:** Indicates positive/negative values.
* **5 Integer Bits:** Represent whole numbers.
* **10 Fractional Bits:** Provide a scaling factor of $2^{10} = 1024$.

Because $1.0 = 1024$, decimal inputs translate to integers by multiplying by $1024$:

* **$x = 0.0$:** $0.0 \times 1024 = \mathbf{0}$
* **$x = -10.0$:** $-10.0 \times 1024 = \mathbf{-10240}$

---

### Mathematical Domain & Output Values

The module evaluates $e^x$ over the non-positive domain $x \in [-10.0, 0.0]$:

* **Upper Limit ($x = 0.0$):** $e^0 = 1.0 \rightarrow \text{Q6.10 value } \mathbf{1024}$
* **Lower Limit ($x = -10.0$):** $e^{-10} \approx 0.0000454 \rightarrow \text{Q6.10 value } \mathbf{0}$

Keeping $x \le 0$ guarantees that $e^x \le 1.0$. This prevents fixed-point overflow, as positive powers like $e^{+10} \approx 22026$ would heavily exceed the maximum value representable in Q6.10 ($31.999$).

---

### Step-by-Step Code Walkthrough

#### 1. Input Clamping (Domain Enforcement)

```
logic signed [15:0] x_clamped;
always_comb begin
    if (x_in < -16'sd10240)
        x_clamped = -16'sd10240;
    else if (x_in > 16'sd0)
        x_clamped = 16'sd0;
    else
        x_clamped = x_in;
end

```

* **Lower Limit (`-10240`):** Clamps $x \le -10.0$. Below this point, $e^x$ becomes too small to represent in Q6.10 precision and rounds to zero.
* **Upper Limit (`0`):** Clamps $x \ge 0.0$. This restricts the function output to $\le 1.0$, preventing output overflow.

---

#### 2. Address Calculation for the ROM

```
logic [15:0] offset;
logic [9:0]  addr;

always_comb begin
    offset = x_clamped + 16'd10240;  // shift range to [0, 10240]
    addr   = offset / 20;            // step size = 20 (0.0195)
end

```

* **Base Shift (`offset = x_clamped + 10240`):** Adds `10240` to translate the input range from $[-10240, 0]$ into a non-negative range $[0, 10240]$.
* **Address Downscaling (`addr = offset / 20`):** Maps the offset into intervals of `20` Q6.10 units ($\approx 0.01953$).
* **Address Range Analysis:**
* Minimum Address ($x = -10.0$): $(-10240 + 10240) / 20 = \mathbf{0}$
* Maximum Address ($x = 0.0$): $(0 + 10240) / 20 = 10240 / 20 = \mathbf{512}$
* Total ROM Size: **513 entries** (Addresses `0` through `512`).



---

#### 3. ROM Lookup & Output Assignment


```
logic signed [15:0] out;

exp_rom rom_inst (
    .addr(addr),
    .out(out)
);

assign exp_out = out;

```

* **`exp_rom`:** A 513-entry ROM pre-loaded with Q6.10 values of $e^x$ corresponding to each step address.
* **Direct Readout:** Assigns the looked-up result directly to `exp_out` using step (nearest-lower-neighbor) mapping without linear interpolation.

# `ln.sv`

This SystemVerilog module computes the **natural logarithm ($\ln(x)$)** using a **Look-Up Table (LUT)** approach. It maps non-integer numbers into a 16-bit fixed-point representation and accesses pre-computed logarithm values from a Read-Only Memory (ROM).

---

### Core Data Representation (Q6.10 Format)

The module operates using **16-bit signed Q6.10 fixed-point arithmetic**:

* **1 Sign Bit:** Represents positive/negative sign.
* **5 Integer Bits:** Represent whole numbers up to 31.
* **10 Fractional Bits:** Represent fractional values with a scale factor of $2^{10} = 1024$.

Because $1.0 = 1024$, decimal inputs are converted by multiplying by $1024$:

* **$x = 0.01$:** $0.01 \times 1024 \approx \mathbf{10}$
* **$x = 10.0$:** $10.0 \times 1024 = \mathbf{10240}$

---

### Step-by-Step Code Walkthrough

#### 1. Input Clamping (Domain Protection)

```
logic signed [15:0] x_clamped;
always_comb begin
    if (x_in < 16'sd10) // clamp at ~0.01 (0.01 * 1024 = ~10)
        x_clamped = 16'sd10;
    else if (x_in > 16'sd10240) // max x = 10.0 (10.0 * 1024)
        x_clamped = 16'sd10240;
    else
        x_clamped = x_in;
end

```

* **Why Clamp?** The natural logarithm is undefined for $x \le 0$ and approaches $-\infty$ as $x \to 0^+$. Clamping forces the input into the safe range $[0.01, 10.0]$ (`10` to `10240` in Q6.10).
* **Lower Bound (`10`):** Prevents negative fixed-point overflow near zero.
* **Upper Bound (`10240`):** Caps the maximum input so memory size stays manageable.

---

#### 2. Indexing & Address Mapping

```
logic [15:0] index;
logic [9:0]  addr;

always_comb begin
    index = x_clamped - 16'd10;    // Shift base to start at 0.01
    addr  = index / 20;            // 513 entries over [0.01,10] → step ≈ 0.0195 → 20 in Q6.10
end

```

* **Base Shift (`index = x_clamped - 10`):** Subtracts `10` so that the minimum input $0.01$ maps to an index of `0`. The offset range becomes $[0, 10230]$.
* **Address Downscaling (`addr = index / 20`):** Divides the index into intervals of `20` Q6.10 units ($\approx 0.0195$ step size).
* **Address Output Range:** Integer division truncates remainders. The maximum address generated is $10230 \div 20 = \mathbf{511}$, producing addresses from `0` to `511`.

---

#### 3. ROM Lookup & Output Assignment

```
logic signed [15:0] out;
ln_rom rom_inst (
    .addr(addr),
    .out(out)
);

assign ln_out = out;

```

* Instantiates `ln_rom`, a 512-entry ROM storing pre-computed Q6.10 values of $\ln(x)$.
* Reads the output corresponding to `addr` and passes it directly to `ln_out`.
* Does not perform linear interpolation between entries; it uses a step (nearest-lower-neighbor) approximation.
