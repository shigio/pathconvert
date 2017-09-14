#	@(#)Makefile	8.2 (Berkeley) 5/31/93
#	$Id: Makefile,v 1.3 1994/09/24 02:55:45 davidg Exp $

PROG=	ln
CFLAGS+=-I${.CURDIR}/../lib
LDADD+= -L${.CURDIR}/../lib -lpathconvert
BINDIR?=        /bin
MANDIR?=        /usr/share/man/man
MAN1=	ln.1
CFLAGS+= -DPATHCONVERT -Wall -Wmissing-prototypes

.include <bsd.prog.mk>
