# EECS 151/251A ASIC Project Specification: Checkpoint 3
<p align="center">
Prof. John Wawrzynek
</p>
<p align="center">
TA: Kevin He, Kevin Anderson
</p>
<p align="center">
Department of Electrical Engineering and Computer Science
</p>
<p align="center">
College of Engineering, University of California, Berkeley
</p>

---

## Cache

A processor operates on data in memory. Memory can hold billions of bits,
which can either be instructions or data. In a VLSI design,
it is a bad idea to store this many bits close to the processor.
The chip area required would be huge - consider how many DRAM chips your PC has, and that DRAM cells
are much smaller than SRAM cells (which can actually be implemented in the same CMOS process).
Moreover, the entire processor would have to slow down to accommodate delays in the large memory
array. Instead, caches are used to create the illusion of a large memory with low latency.

Your task is to implement a simple cache for your RISC-V processor, based on
predefined SRAM macros and the interface specified below.

### Overview

When you request data at a given address, the cache should determine if it has the requested data.
If it does (cache hit), the data is returned immediately.
Otherwise if it is not found (cache miss), the cache fetches the bits from the
main memory.
Caches store data in "ways." A way is a logical element which contains valid bits, tag bits, and data.
The simplest type of cache is direct-mapped (a 1-way cache). A cache stores data in larger units (lines)
than single words. In each way, a given address may only occupy a single location, determined by the
lowest bits of the cache line address. The remaining address bits are called the “tag” and are stored so
that we can check if a given cache line belongs to a given address. The valid bit indicates which lines
contain valid data.
Multi-way caches allow more flexibility in what data is stored in the cache, since there are multiple
locations for a line to occupy (the number of ways). For this reason, a "replacement policy" is needed.
This is used to decide which way's data to evict when fetching new data. For this project you may use
any policy you wish, but pseudo-random is recommended.

### Implementation

You have been given the interface of a cache (`Cache.v`), and your next task is to implement the cache.
EECS151A students should build a direct-mapped cache, and EECS251A students are required to implement a cache that either:
1. is configurable to be either direct-mapped or at least 2-way set associative; or
2. is set-associative with configurable associativity.

You are welcome to implement a more performant cache if you desire.
Your cache should store 4 kbyte (4096 bytes, or 2^15 bits) of data;
if you wish to increase the size, implement the 4 kbyte
cache first and upgrade later.

For your data and tag arrays, use SRAMs from the
[SRAM library](https://github.com/rahulk29/sram22_sky130_macros)
that you explored in lab 6.

You should use cache lines that are 512 bits (16 words) for this project. The memory interface is
128 bits, meaning that you will require multiple (4) cycles to perform memory transactions.
Here is a description of each signal in `Cache.v`:
|                        |                                        |
|------------------------|----------------------------------------|
| `clk`                  | clock |
| `reset`                | reset |
| `cpu_req_valid`        | The CPU is requesting a memory transaction |
| `cpu_req_rdy`          | The cache is ready for a CPU memory transaction |
| `cpu_req_addr`         | The address of the CPU memory transaction |
| `cpu_req_data`         | The write data for a CPU memory write (ignored on reads) |
| `cpu_req_write`        | The 4-bit write mask for a CPU memory transaction (each bit corresponds to the byte address within the word). `4’b0000` indicates a read. |
| `cpu_resp_val`         | The cache has output valid data to the CPU after a memory read |
| `cpu_resp_data`        | The data requested by the CPU |
| `mem_req_val`          | The cache is requesting a memory transaction to main memory |
| `mem_req_rdy`          | Main memory is ready for the cache to provide a memory address |
| `mem_req_addr`         | The address of the main memory transaction from the cache. Note that this address is narrower than the CPU byte address since main memory has wider data._ |
| `mem_req_rw`           | 1 if the main memory transaction is a write; 0 for a read. |
| `mem_req_data_valid`   | The cache is providing write data to main memory. |
| `mem_req_data_ready`   | Main memory is ready for the cache to provide write data. |
| `mem_req_data_bits`    | Data to write to main memory from the cache (128 bits/4 words). |
| `mem_req_data_mask`    | Byte-level write mask to main memory. May be `16’hFFFF` for a full write. |
| `mem_resp_val`         | The main memory response data is valid. |
| `mem_resp_data`        | Main memory response data to the cache (128 bits/4 words). |

To design your cache, start by outlining where the SRAMs should go.
You should use 4 256x32 SRAMs for data, and 1 64x32 SRAM for metadata.
The metadata SRAM should store tags and valid bits.

Next you should develop a state machine that covers all the events that your cache needs to handle
for both hits and misses. You can do it without an explicit state machine, but you will probably suffer. Keep in
mind you will need to write any valid data back to main memory before you start refilling the cache (you
can use a write-back or a write-through policy). Both of these transactions will take multiple cycles.

As a part of your implementation, you will need to divide cache addresses
into tag, index, and offset bits.
If you need a refresher on how to partition T/I/O bits, refer to [CS 61C](https://cs61c.org/).

### Testing

You should now be able to pass the `bmark` test. The test suite includes many C programs that do
various things to test your processor and cache implementation. You can observe the number of cycles
that each bmark test takes to run by opening `bmark_output/*.out` and taking note of the number
on the last line. The `make sim-rtl test bmark=all` target will also print this number for you.
To run a specific benchmark (e.g., cachetest), run
```
make sim-rtl test_bmark=cachetest.out
```
After completing your cache, run the tests with both the cache included and with the fake memory
(`no_cache_mem`) included. To use no_cache_mem be sure to have `+define+no_cache_mem` in the
simOptions variable in the `sim-rtl.yml` file. To use your cache, comment out `+define+no_cache_mem`.
Take note of the cycle counts for both. You should see the cycle counts increase when you use the cache.

### 7. Checkpoint 2 Deliverables
*Checkoff due: 6PM  4/25/24 (Kevin A's OH)*

Please answer the following questions to be checked off by a TA.
1. Show that all of the tests (assembly tests and the benchmark tests) pass **using the cache**.
2. Show the block diagram of your cache.
3. What was the difference in the cycle count for the `bmark` test with the perfect memory and the
cache?
4. Show your final pipeline diagram, updated to match the code.
