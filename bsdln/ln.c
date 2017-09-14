/*
 * Copyright (c) 1987, 1993, 1994
 *	The Regents of the University of California.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	$Id: ln.c,v 1.6.2.2 1997/08/24 21:52:04 jkh Exp $
 */

#ifndef lint
static char const copyright[] =
"@(#) Copyright (c) 1987, 1993, 1994\n\
	The Regents of the University of California.  All rights reserved.\n";
#endif /* not lint */

#ifndef lint
static char const sccsid[] = "@(#)ln.c	8.2 (Berkeley) 3/31/94";
#endif /* not lint */

#include <sys/param.h>
#include <sys/stat.h>

#include <err.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifdef PATHCONVERT
int	aflag;				/* Absolute symbolic link. */
#endif
int	fflag;				/* Unlink existing files. */
#ifdef PATHCONVERT
int	rflag;				/* Relative symbolic link. */
#endif
int	sflag;				/* Symbolic, not hard, link. */
					/* System link call. */
int (*linkf) __P((const char *, const char *));
#ifdef PATHCONVERT
char	*abs2rel __P((const char *, const char *, char *, const size_t));
char	*rel2abs __P((const char *, const char *, char *, const size_t));
#endif

int	linkit __P((char *, char *, int));
void	usage __P((void));

int
main(argc, argv)
	int argc;
	char *argv[];
{
	extern int optind;
	struct stat sb;
	int ch, exitval;
	char *sourcedir;

#ifdef PATHCONVERT
	while ((ch = getopt(argc, argv, "afrs")) != -1)
#else
	while ((ch = getopt(argc, argv, "fs")) != -1)
#endif
		switch (ch) {
#ifdef PATHCONVERT
		case 'a':
			aflag = 1;
			rflag = 0;
			break;
#endif
		case 'f':
			fflag = 1;
			break;
#ifdef PATHCONVERT
		case 'r':
			rflag = 1;
			aflag = 0;
			break;
#endif
		case 's':
			sflag = 1;
			break;
		case '?':
		default:
			usage();
		}

	argv += optind;
	argc -= optind;

	linkf = sflag ? symlink : link;

	switch(argc) {
	case 0:
		usage();
	case 1:				/* ln target */
		exit(linkit(argv[0], ".", 1));
	case 2:				/* ln target source */
		exit(linkit(argv[0], argv[1], 0));
	}
					/* ln target1 target2 directory */
	sourcedir = argv[argc - 1];
	if (stat(sourcedir, &sb))
		err(1, "%s", sourcedir);
	if (!S_ISDIR(sb.st_mode))
		usage();
	for (exitval = 0; *argv != sourcedir; ++argv)
		exitval |= linkit(*argv, sourcedir, 1);
	exit(exitval);
}

int
linkit(target, source, isdir)
	char *target, *source;
	int isdir;
{
	struct stat sb;
	int exists;
	char *p, path[MAXPATHLEN];
#ifdef PATHCONVERT
	char base[MAXPATHLEN];
	char abstarget[MAXPATHLEN];
	char reltarget[MAXPATHLEN];
#endif

	if (!sflag) {
		/* If target doesn't exist, quit now. */
		if (stat(target, &sb)) {
			warn("%s", target);
			return (1);
		}
		/* Only symbolic links to directories. */
		if (S_ISDIR(sb.st_mode)) {
			errno = EISDIR;
			warn("%s", target);
			return (1);
		}
	}

#ifdef PATHCONVERT
	if (!isdir && (exists = !stat(source, &sb)) && S_ISDIR(sb.st_mode))
		isdir = 1;
	if (sflag && (aflag || rflag)) {
		/* convert target directory into absolute name */
		if (*target != '/') {
			if (getcwd(base, MAXPATHLEN) == NULL)
				err(1, "couldn't get current directory.");
			if (rel2abs(target, base, abstarget, MAXPATHLEN) == NULL)
				err(1, "couldn't convert path");
			target = abstarget;
		}
		/* convert target directory into relative name */
		if (rflag) {
			if (!isdir) {
				if ((p = strrchr(source, '/')) != NULL) {
					int col = p - source + 1;
					strncpy(path, source, col);
					path[col] = 0;
				} else {
					path[0] = '.';
					path[1] = 0;
				}
				p = path;
			} else
				p = source;
			if (realpath(p, base) == NULL)
				err(1, p);
			if (abs2rel(target, base, reltarget, MAXPATHLEN) == NULL)
				err(1, "couldn't convert path");
			target = reltarget;
		}
	}
	/* If the source is a directory, append the target's name. */
	if (isdir) {
#else
	if (isdir || ((exists = !stat(source, &sb)) && S_ISDIR(sb.st_mode))) {
#endif
		if ((p = strrchr(target, '/')) == NULL)
			p = target;
		else
			++p;
		(void)snprintf(path, sizeof(path), "%s/%s", source, p);
		source = path;
		exists = !lstat(source, &sb);
	} else
		exists = !lstat(source, &sb);
	/*
	 * If the file exists, and -f was specified, unlink it.
	 * Attempt the link.
	 */
	if ((fflag && exists && unlink(source)) || (*linkf)(target, source)) {
		warn("%s", source);
		return (1);
	}
	return (0);
}

void
usage()
{
	(void)fprintf(stderr, "%s\n%s\n",
#ifdef PATHCONVERT
	    "usage: ln [-afrs] file1 file2",
	    "       ln [-afrs] file ... directory");
#else
	    "usage: ln [-fs] file1 file2",
	    "       ln [-fs] file ... directory");
#endif
	exit(1);
}
