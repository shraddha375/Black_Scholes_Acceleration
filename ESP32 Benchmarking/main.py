#
# 
# main.py
# Black-Scholes Benchmarking Script
#
#

import time
import math
import urandom

# Normal CDF using erf
def norm_cdf(x):
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))

# Generate a random float between min and max
def rand_float(min_val, max_val):
    return min_val + (urandom.getrandbits(16) / 65535.0) * (max_val - min_val)

# Perform 3 lookups and time each
times = []
results = []
inputs = []

for _ in range(3):
    x = rand_float(-5.0, 5.0)
    inputs.append(x)

    start = time.ticks_us()
    result = norm_cdf(x)
    end = time.ticks_us()

    elapsed = time.ticks_diff(end, start)
    times.append(elapsed)
    results.append(result)

# Calculate average time
avg_time = sum(times) / len(times)

# Output results
for i in range(3):
    print(f"Input {i+1}: {inputs[i]:.4f}, Result: {results[i]:.6f}, Time: {times[i]} µs")

print(f"\nAverage time per lookup: {avg_time:.2f} µs")

import time
import math
import urandom

# Generate random float between min and max
def rand_float(min_val, max_val):
    return min_val + (urandom.getrandbits(16) / 65535.0) * (max_val - min_val)

# Black-Scholes d1 formula
def black_scholes_d1(S, K, T, r, sigma):
    return (math.log(S / K) + (r + 0.5 * sigma**2) * T) / (sigma * math.sqrt(T))

# Generate and time 3 random d1 computations
times = []
results = []
inputs = []

for _ in range(3):
    S     = rand_float(50.0, 150.0)     # Stock price
    K     = rand_float(50.0, 150.0)     # Strike price
    T     = rand_float(0.1, 2.0)        # Time to maturity (in years)
    r     = rand_float(0.0, 0.1)        # Risk-free rate (0% to 10%)
    sigma = rand_float(0.1, 0.5)        # Volatility (10% to 50%)

    input_set = (S, K, T, r, sigma)
    inputs.append(input_set)

    start = time.ticks_us()
    d1 = black_scholes_d1(S, K, T, r, sigma)
    end = time.ticks_us()

    elapsed = time.ticks_diff(end, start)
    times.append(elapsed)
    results.append(d1)

# Calculate average time
avg_time = sum(times) / len(times)

# Print results
for i in range(3):
    S, K, T, r, sigma = inputs[i]
    print(f"Input {i+1}: S={S:.2f}, K={K:.2f}, T={T:.2f}, r={r:.4f}, σ={sigma:.4f}")
    print(f"  d₁ = {results[i]:.6f}, Time: {times[i]} µs")

print(f"\nAverage time per d₁ computation: {avg_time:.2f} µs")

# Generate random float between min and max
def rand_float(min_val, max_val):
    return min_val + (urandom.getrandbits(16) / 65535.0) * (max_val - min_val)

# d1 formula
def compute_d1(S, K, T, r, sigma):
    return (math.log(S / K) + (r + 0.5 * sigma**2) * T) / (sigma * math.sqrt(T))

# d2 formula
def compute_d2(d1, sigma, T):
    return d1 - sigma * math.sqrt(T)

# Benchmark 3 random d2 computations
times = []
results = []
inputs = []

for _ in range(3):
    S     = rand_float(50.0, 150.0)
    K     = rand_float(50.0, 150.0)
    T     = rand_float(0.1, 2.0)
    r     = rand_float(0.0, 0.1)
    sigma = rand_float(0.1, 0.5)

    d1 = compute_d1(S, K, T, r, sigma)

    start = time.ticks_us()
    d2 = compute_d2(d1, sigma, T)
    end = time.ticks_us()

    elapsed = time.ticks_diff(end, start)

    inputs.append((S, K, T, r, sigma, d1))
    results.append(d2)
    times.append(elapsed)

# Average timing
avg_time = sum(times) / len(times)

# Print results
for i in range(3):
    S, K, T, r, sigma, d1 = inputs[i]
    print(f"Input {i+1}: S={S:.2f}, K={K:.2f}, T={T:.2f}, r={r:.4f}, σ={sigma:.4f}")
    print(f"  d₁ = {d1:.6f}")
    print(f"  d₂ = {results[i]:.6f}, Time: {times[i]} µs")

print(f"\nAverage time per d₂ computation: {avg_time:.2f} µs")

# Norm CDF using erf
def norm_cdf(x):
    return 0.5 * (1 + math.erf(x / math.sqrt(2)))

# Random float generator
def rand_float(min_val, max_val):
    return min_val + (urandom.getrandbits(16) / 65535.0) * (max_val - min_val)

# Full Black-Scholes call option price
def black_scholes_call(S, K, T, r, sigma):
    d1 = (math.log(S / K) + (r + 0.5 * sigma**2) * T) / (sigma * math.sqrt(T))
    d2 = d1 - sigma * math.sqrt(T)
    Nd1 = norm_cdf(d1)
    Nd2 = norm_cdf(d2)
    return S * Nd1 - K * math.exp(-r * T) * Nd2

# Run 3 tests
times = []
results = []
inputs = []

for _ in range(3):
    S     = rand_float(50.0, 150.0)
    K     = rand_float(50.0, 150.0)
    T     = rand_float(0.1, 2.0)
    r     = rand_float(0.0, 0.1)
    sigma = rand_float(0.1, 0.5)

    start = time.ticks_us()
    price = black_scholes_call(S, K, T, r, sigma)
    end = time.ticks_us()

    elapsed = time.ticks_diff(end, start)

    inputs.append((S, K, T, r, sigma))
    results.append(price)
    times.append(elapsed)

# Average time
avg_time = sum(times) / len(times)

# Print results
for i in range(3):
    S, K, T, r, sigma = inputs[i]
    print(f"Input {i+1}: S={S:.2f}, K={K:.2f}, T={T:.2f}, r={r:.4f}, σ={sigma:.4f}")
    print(f"  Call Price = {results[i]:.6f}, Time: {times[i]} µs")

print(f"\nAverage time per Black-Scholes call: {avg_time:.2f} µs")

