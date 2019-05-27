#SUBDIR = lib gnuln bsdln lndir
SUBDIR = lib

all:
	for d in $(SUBDIR); do \
		(cd $$d && $(MAKE)); \
	done
test:
	for d in $(SUBDIR); do \
		(cd $$d && $(MAKE) test); \
	done
clean:
	for d in $(SUBDIR); do \
		(cd $$d && $(MAKE) clean); \
	done
