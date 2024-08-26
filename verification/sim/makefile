all: compile wave verdi1
TOP_MODULE =TOP_MODULE
fsdb_name =${TOP_MODULE}.fsdb_name
path_name = /ext/home/wangyufei/Projects/ISP/design

INIT_COMPILE = $(shell if [ ! -e irun ];then mkdir -p irun; fi;)
INIT_VERDI = $(shell if [ ! -e irun ];then mkdir -p verdi; fi;)

compile:
	@echo $(INIT_COMPILE) create irun dir successfully!
	cd irun && bsub -q digital -Is xrun -sv +64bit -access	\
	-rwc	\
	+xmlicq	\
	+nottimingcheck	\
	+nospecify	\
	+xmtimescale+1ns/10ps	\
	-f $(path_name)/filelist.f	\
	-disable_sem2009

wave:
	@echo $(INIT_VERDI) create verdi dir successfully!
	cd verdi && bsub -q digital -Is verdi +v2k -sv	\
	-syntaxerrormax 1000000 -ssv -ssy -ssz	\
	-f
	-ssf ../$(fsdb_name) & ${path_name}/filelist.f

verdi1:
	@echo $(INIT_VERDI) create verdi dir successfully!
	cd verdi && bsub -q digital -Is verdi +v2k -sv	\
	-syntaxerrormax 1000000 -ssv -ssy -ssz	\
	-f ${path_name}/filelist.f &

clean:
	rm -rf irun	\
	rm -rf verdi