PROGS = rel2abs abs2rel
LIBPATH	=../libpathconvert.a
DPADD=	$(LIBPATH)
LDADD=	$(LIBPATH)

all: $(PROGS)

rel2abs: rel2abs.c $(DPADD)
	cc -o rel2abs rel2abs.c $(LDADD)
abs2rel: abs2rel.c $(DPADD)
	cc -o abs2rel abs2rel.c $(LDADD)
test: $(PROGS)
	perl ./test.pl
clean:
	rm -f $(PROGS) *.o err
