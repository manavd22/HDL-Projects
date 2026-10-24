# Verilog & SystemVerilog HDL Projects Portfolio
**Digital Design Projects for VLSI/Semiconductor Applications**

[![HDL](https://img.shields.io/badge/HDL-Verilog%20%7C%20SystemVerilog-blue.svg)](https://en.wikipedia.org/wiki/SystemVerilog)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-success.svg)]()

---

## 📋 Overview

This repository contains digital design projects implemented in Verilog and SystemVerilog HDL, demonstrating skills essential for ASIC/FPGA design roles in the semiconductor industry. They range from classic FSM and arithmetic designs to a hardware accelerator for Vision Transformer self-attention. Each project includes RTL design, testbenches, and documentation.

**Author:** Manav Dalela

---

## 📂 Repository Structure

```
├── Personal Projects/   # Verilog projects: Traffic Light Controller, Booth's Multiplier
├── TASAD/               # SystemVerilog ViT self-attention accelerator (NCKU AISSM 2026)
└── README.md
```

---

## 🚀 Projects

| # | Project | Language | Highlights |
|---|---------|----------|------------|
| 1 | [Traffic Light Controller](#1-traffic-light-controller) | Verilog | 8-state Moore FSM, pedestrian & emergency override |
| 2 | [Booth's Algorithm Multiplier](#2-booths-algorithm-multiplier) | Verilog | Radix-2 signed multiplication, parameterizable width |
| 3 | [TASAD – ViT Self-Attention Accelerator](#3-tasad--vision-transformer-self-attention-accelerator) | SystemVerilog | Bit-exact against golden model across all 4,096 outputs |

---

### 1. Traffic Light Controller
**Advanced FSM-based Traffic Management System**

A 4-way intersection traffic light controller with pedestrian crossing support, emergency vehicle override, and configurable timing parameters.

📁 **Directory:** [`Personal Projects/`](Personal%20Projects)

**Features:**
- ✅ 8-state Moore FSM implementation
- ✅ Pedestrian crossing with request buttons (NS/EW)
- ✅ Emergency vehicle override (highest priority)
- ✅ Parameterizable timing (green, yellow, red phases)
- ✅ Enable/disable control with state freeze
- ✅ 100% state coverage verification

**Skills Demonstrated:**
- Finite State Machine design
- Sequential and combinational logic separation
- Safety-critical system design
- Comprehensive verification methodology

---

### 2. Booth's Algorithm Multiplier
**Efficient Signed Multiplication Hardware**

A clean implementation of Booth's algorithm for signed multiplication, demonstrating arithmetic algorithm design in hardware.

📁 **Directory:** [`Personal Projects/`](Personal%20Projects)

**Features:**
- ✅ Radix-2 Booth's algorithm implementation
- ✅ Signed multiplication (two's complement)
- ✅ Parameterizable width (8/16/32 bits)
- ✅ FSM-based control architecture
- ✅ Compact and readable code

**Skills Demonstrated:**
- Arithmetic algorithm implementation
- Signed number handling
- Efficient hardware design
- Algorithm optimization

---

### 3. TASAD – Vision Transformer Self-Attention Accelerator
**Hardware Accelerator for Transformer Attention, built at the NCKU AISSM Semiconductor Summer School 2026 (Taiwan)**

TASAD is a SystemVerilog RTL accelerator for the self-attention computation at the core of Vision Transformers (ViT). Self-attention is dominated by large matrix multiplications, which makes it a natural target for dedicated hardware. The design was verified **bit-exactly against a golden reference model across all 4,096 attention-score outputs**, and taken through a synthesis flow.

📁 **Directory:** [`TASAD/`](TASAD)

**Features:**
- ✅ Synthesizable SystemVerilog RTL for ViT self-attention
- ✅ Bit-exact match with golden reference model (4,096 / 4,096 outputs)
- ✅ Golden reference model for automated result comparison
- ✅ Simulation and synthesis flows driven by a `Makefile`
- ✅ Synthesis reports included

**Project Structure:**
```
TASAD/
├── src/            # SystemVerilog RTL source
├── sim/            # Testbenches and simulation setup
├── model/          # Golden reference model
├── syn/            # Synthesis scripts and constraints
├── reports/        # Synthesis / simulation reports
├── script/         # Helper scripts
├── tools/          # Tool utilities
├── demo/           # Demo files
├── Makefile        # Build, simulate and synthesize
└── requirements.txt
```

**Getting Started:**
```bash
cd TASAD
pip install -r requirements.txt   # Python dependencies for the reference model / scripts
make                              # see Makefile for available targets
```

**Skills Demonstrated:**
- Hardware acceleration of AI/ML workloads
- Datapath design for matrix operations
- Fixed-point arithmetic and bit-exact verification
- Golden-model-based verification methodology
- RTL-to-synthesis flow with Makefile automation

---

## 🛠️ Technology Stack

### Languages & Tools
- **HDL:** Verilog, SystemVerilog
- **Simulation:** Xilinx Vivado
- **Scripting:** Python, Make
- **Flow:** RTL design → simulation → golden-model comparison → synthesis

### Design Methodology
- Synchronous design principles
- FSM-based control structures
- Modular and parameterizable designs
- Separation of datapath and control
- Industry-standard coding practices

---

## 🎯 Skills Demonstrated

### Digital Design
- ✅ **Finite State Machines (FSM)** - Moore and Mealy architectures
- ✅ **Sequential Logic** - Registers, counters, state machines
- ✅ **Combinational Logic** - Arithmetic units, multiplexers, decoders
- ✅ **Hardware Accelerators** - Datapaths for Transformer self-attention
- ✅ **Timing Analysis** - Setup/hold time, clock domains
- ✅ **Design Constraints** - SDC files for synthesis

### Verilog / SystemVerilog HDL
- ✅ **Parameterizable Design** - Reusable, scalable modules
- ✅ **Blocking vs Non-blocking** - Proper usage for synthesis
- ✅ **Synthesis-Friendly Coding** - Industry best practices
- ✅ **Module Hierarchy** - Structured design approach
- ✅ **Signed & Fixed-Point Arithmetic** - Two's complement operations

### Verification
- ✅ **Self-Checking Testbenches** - Automated pass/fail verification
- ✅ **Golden-Model Comparison** - Bit-exact checking against a reference model
- ✅ **Coverage-Driven Testing** - 100% state/functional coverage
- ✅ **Corner Case Testing** - Edge conditions and fault scenarios
- ✅ **Waveform Analysis** - VCD generation and debugging
- ✅ **Regression Testing** - Automated test suites

---

## 📬 Contact

**Manav Dalela** · B.Tech ECE (VLSI Design minor), Manipal Institute of Technology
Feel free to reach out via GitHub for questions or collaboration.
