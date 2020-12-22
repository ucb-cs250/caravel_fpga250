# ---- Test patterns for fpga 250 ----

.SUFFIXES:
.SILENT: clean all

PATTERNS = basic_config standalone_test integration

all:  ${PATTERNS}
	for i in ${PATTERNS}; do \
		echo "Tesing $$i"; \
		( cd $$i && make -f Makefile &> verify.log) ; \
	done

clean:  ${PATTERNS}
	for i in ${PATTERNS}; do \
		( cd $$i && make clean ) ; \
	done

.PHONY: clean all
