VLOGAN ?= vcs-2024.09 vlogan
VLOGAN_ARGS ?= -kdb -nc -assert svaext +v2k -timescale=1ns/1ps
VcsDir := $(SimDir)/$(target)
VcsCompileScript := $(VcsDir)/compile.$(target).sh

hw-script:
	$(Bender) update
	$(Bender) script $(target)     \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	--vlog-arg="$(VLOGAN_ARGS)"    \
	--vlogan-bin="$(VLOGAN)"       \
	> $(VcsCompileScript)
	chmod +x $(VcsCompileScript)
