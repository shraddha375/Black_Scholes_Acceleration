## `exp.sv`

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

## `ln.sv`

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
