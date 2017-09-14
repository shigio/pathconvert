NAME=           pathconvert
LIB=            lib$(NAME).a
OBJS=           rel2abs.o abs2rel.o

all: $(OBJS)
	ar -cq $(LIB) $(OBJS)
test: all
	chmod u+w t
	(cd t; make test)
clean:
	(cd t; make clean)
	rm -f *.o $(LIB)
