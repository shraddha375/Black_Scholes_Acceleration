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
