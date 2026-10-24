PYTHON ?= python3
RUNTIME_PYTHON ?= .venv_linux/bin/python
VCS ?= vcs

# Fixed Flag-10 runtime. Students do not train or export another model.
CLASS ?= JP
IMAGE_INPUT ?= my_test.png
IMAGE_OUTPUT ?= demo/my_test.rgb
MODEL_DIR ?= model
WORK_DIR ?= work
ATTENTION ?= $(WORK_DIR)/A_rtl.dat
EXPECTED ?=
TB_DEFINES ?=

.PHONY: help demo_custom demo_sw model_back rtl_sim syn_sim rtl_processing \
	full_flow superlint synthesize demo-all make_rtl make_syn country_rtl \
	rtl_model_back rtl_correct syn_correct synthesis

help:
	@echo "Fixed Flag-10 student environment:"
	@echo "  make demo_sw CLASS=JP       image pre-processing"
	@echo "  make model_back CLASS=JP    image post-processing"
	@echo "  make rtl_sim                RTL simulation with public data"
	@echo "  make syn_sim                SYN simulation with public data"
	@echo "  make rtl_processing CLASS=JP process model Q/K with RTL"
	@echo "  make full_flow CLASS=JP     run the whole flow"
	@echo "  make superlint              run JasperGold Superlint"
	@echo "  make synthesize             synthesize src/TASAD.sv"

demo_custom:
	$(RUNTIME_PYTHON) tools/prepare_image.py \
		--input $(IMAGE_INPUT) \
		--output $(IMAGE_OUTPUT)
	$(RUNTIME_PYTHON) -m runtime.run_demo \
		--image $(IMAGE_OUTPUT) \
		--backend software \
		--model-dir $(MODEL_DIR) \
		--work-dir $(WORK_DIR)

demo_sw:
	$(RUNTIME_PYTHON) -m runtime.model_front \
		--image demo/$(CLASS).rgb \
		--model-dir $(MODEL_DIR) \
		--work-dir $(WORK_DIR)

model_back:
	$(RUNTIME_PYTHON) -m runtime.model_back \
		--attention $(ATTENTION) \
		--model-dir $(MODEL_DIR) \
		--work-dir $(WORK_DIR) \
		--expected $(CLASS)

demo-all:
	$(RUNTIME_PYTHON) tools/run_demo_all.py \
		--backend software \
		--model-dir $(MODEL_DIR) \
		--demo-dir demo \
		--work-dir work/demo_all \
		--output reports/rtl/demo_all.csv

full_flow:
	$(MAKE) demo_sw CLASS=$(CLASS)
	$(MAKE) rtl_processing
	$(MAKE) model_back CLASS=$(CLASS)

# Normal processing simulations do not compare against the public golden file.
rtl_processing:
	cd sim && $(VCS) -R -sverilog $(TB_DEFINES) \
		tb_tasad_application.sv +define+FSDB -debug_access+all -full64

# Public correctness simulations use sim/Q.dat, sim/K.dat, and sim/A_rtl.dat.
rtl_sim:
	cd sim && $(VCS) -R -sverilog $(TB_DEFINES) \
		tb_tasad_application.sv -debug_access+all -full64 \
		+define+CHECK_GOLDEN +define+RTL_CORRECT+FSDB

syn_sim:
	cd sim && $(VCS) -R -sverilog $(TB_DEFINES) \
		tb_tasad_application.sv -debug_access+all -full64 \
		+define+SYN +define+CHECK_GOLDEN +define+RTL_CORRECT+FSDB

nWave:
	cd sim && nWave TASAD.fsdb &

synthesize:
	dc_shell -f ./script/synthesis.tcl

superlint:
	jg -superlint ./script/superlint.tcl

# Backward-compatible aliases for the instructor workspace.
make_rtl: rtl_processing
make_syn:
	cd sim && $(VCS) -R -sverilog +define+SYN $(TB_DEFINES) \
		tb_tasad_application.sv -debug_access+all -full64
country_rtl: full_flow
rtl_model_back: model_back
rtl_correct: rtl_sim
syn_correct: syn_sim
synthesis: synthesize
