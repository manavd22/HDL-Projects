# TASAD – Vision Transformer Self-Attention Accelerator

**SystemVerilog hardware accelerator for Transformer self-attention**
Built at the NCKU AISSM Semiconductor Summer School 2026, National Cheng Kung University, Taiwan.

---

## Overview

TASAD accelerates the self-attention computation at the core of Vision Transformers (ViT). Self-attention is dominated by large matrix multiplications, which makes it a natural target for dedicated hardware. The RTL was verified **bit-exactly against a golden reference model across all 4,096 attention-score outputs** and taken through a synthesis flow.

## Highlights

- ✅ Synthesizable SystemVerilog RTL
- ✅ Bit-exact match with golden reference (4,096 / 4,096 outputs)
- ✅ Automated golden-model comparison
- ✅ Makefile-driven simulation and synthesis
- ✅ Synthesis reports included

## Directory Structure

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

## Getting Started

```bash
pip install -r requirements.txt   # Python dependencies
make                              # see Makefile for available targets
```

## Skills Demonstrated

Hardware acceleration of AI/ML workloads · Datapath design for matrix operations · Fixed-point arithmetic · Golden-model-based verification · RTL-to-synthesis flow

---

**Author:** Manav Dalela · [Back to main repository](../README.md)
