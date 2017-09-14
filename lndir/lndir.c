/* $XConsortium: lndir.c,v 1.14 95/01/09 20:08:20 kaleb Exp $ */
/* $XFree86: xc/config/util/lndir.c,v 3.3 1995/01/28 15:41:09 dawes Exp $ */
/* Create shadow link tree (after X11R4 script of the same name)
   Mark Reinhold (mbr@lcs.mit.edu)/3 January 1990 */

/* 
Copyright (c) 1990,  X Consortium

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
X CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

Except as contained in this notice, the name of the X Consortium shall not be
used in advertising or otherwise to promote the sale, use or other dealings
in this Software without prior written authorization from the X Consortium.

*/

/* From the original /bin/sh script:

  Used to create a copy of the a directory tree that has links for all
  non-directories (except those named RCS, SCCS or CVS.adm).  If you are
  building the distribution on more than one machine, you should use
  this technique.

  If your master sources are located in /usr/local/src/X and you would like
  your link tree to be in /usr/local/src/new-X, do the following:

   	%  mkdir /usr/local/src/new-X
	%  cd /usr/local/src/new-X
   	%  lndir ../X
*/

#include <X11/Xos.h>
#include <X11/Xfuncproto.h>
#include <stdio.h>
#include <sys/stat.h>
#if !defined(MINIX)
#include <sys/param.h>
#endif
#include <errno.h>

#ifndef X_NOT_POSIX
#include <dirent.h>
#else
#ifdef SYSV
#include <dirent.h>
#else
#ifdef USG
#include <dirent.h>
#else
#include <sys/dir.h>
#ifndef dirent
#define dirent direct
#endif
#endif
#endif
#endif
#ifndef MAXPATHLEN
#define MAXPATHLEN 2048
#endif

#if NeedVarargsPrototypes
#include <stdarg.h>
#endif

#ifdef X_NOT_STDC_ENV
extern int errno;
#endif
int silent;

char *rcurdir;
char *curdir;

#ifdef PATHCONVERT
char cwd[MAXPATHLEN];
#endif
void
quit (
#if NeedVarargsPrototypes
    int code, char * fmt, ...)
#else
    code, fmt, a1, a2, a3)
    char *fmt;
#endif
{
#if NeedVarargsPrototypes
    va_list args;
    va_start(args, fmt);
    vfprintf (stderr, fmt, args);
    va_end(args);
#else
    fprintf (stderr, fmt, a1, a2, a3);
#endif
    putc ('\n', stderr);
    exit (code);
}

void
quiterr (code, s)
    char *s;
{
    perror (s);
    exit (code);
}

void
msg (
#if NeedVarargsPrototypes
    char * fmt, ...)
#else
    fmt, a1, a2, a3)
    char *fmt;
#endif
{
#if NeedVarargsPrototypes
    va_list args;
#endif
    if (curdir) {
	fprintf (stderr, "%s:\n", curdir);
	curdir = 0;
    }
#if NeedVarargsPrototypes
    va_start(args, fmt);
    vfprintf (stderr, fmt, args);
    va_end(args);
#else
    fprintf (stderr, fmt, a1, a2, a3);
#endif
    putc ('\n', stderr);
}

void
mperror (s)
    char *s;
{
    if (curdir) {
	fprintf (stderr, "%s:\n", curdir);
	curdir = 0;
    }
    perror (s);
}


int equivalent(lname, rname)
    char *lname;
    char *rname;
{
    char *s;

    if (!strcmp(lname, rname))
	return 1;
    for (s = lname; *s && (s = strchr(s, '/')); s++) {
	while (s[1] == '/')
	    strcpy(s+1, s+2);
    }
    return !strcmp(lname, rname);
}


/* Recursively create symbolic links from the current directory to the "from"
   directory.  Assumes that files described by fs and ts are directories. */

dodir (fn, fs, ts, rel)
char *fn;			/* name of "from" directory, either absolute or
				   relative to cwd */
struct stat *fs, *ts;		/* stats for the "from" directory and cwd */
int rel;			/* if true, prepend "../" to fn before using */
{
    DIR *df;
    struct dirent *dp;
    char buf[MAXPATHLEN + 1], *p;
    char symbuf[MAXPATHLEN + 1];
    struct stat sb, sc;
    int n_dirs;
    int symlen;
    char *ocurdir;
#ifdef PATHCONVERT
    char *savep;
    char result[MAXPATHLEN];
#endif

    if ((fs->st_dev == ts->st_dev) && (fs->st_ino == ts->st_ino)) {
	msg ("%s: From and to directories are identical!", fn);
	return 1;
    }

    if (rel)
	strcpy (buf, "../");
    else
	buf[0] = '\0';
    strcat (buf, fn);
    
    if (!(df = opendir (buf))) {
	msg ("%s: Cannot opendir", buf);
	return 1;
    }

    p = buf + strlen (buf);
    *p++ = '/';
    n_dirs = fs->st_nlink;
    while (dp = readdir (df)) {
	if (dp->d_name[strlen(dp->d_name) - 1] == '~')
	    continue;
	strcpy (p, dp->d_name);

	if (n_dirs > 0) {
	    if (stat (buf, &sb) < 0) {
		mperror (buf);
		continue;
	    }

#ifdef S_ISDIR
	    if(S_ISDIR(sb.st_mode))
#else
	    if (sb.st_mode & S_IFDIR) 
#endif
	    {
		/* directory */
		n_dirs--;
		if (dp->d_name[0] == '.' &&
		    (dp->d_name[1] == '\0' || (dp->d_name[1] == '.' &&
					       dp->d_name[2] == '\0')))
		    continue;
		if (!strcmp (dp->d_name, "RCS"))
		    continue;
		if (!strcmp (dp->d_name, "SCCS"))
		    continue;
		if (!strcmp (dp->d_name, "CVS"))
		    continue;
		if (!strcmp (dp->d_name, "CVS.adm"))
		    continue;
		ocurdir = rcurdir;
		rcurdir = buf;
		curdir = silent ? buf : (char *)0;
		if (!silent)
		    printf ("%s:\n", buf);
		if ((stat (dp->d_name, &sc) < 0) && (errno == ENOENT)) {
		    if (mkdir (dp->d_name, 0777) < 0 ||
			stat (dp->d_name, &sc) < 0) {
			mperror (dp->d_name);
			curdir = rcurdir = ocurdir;
			continue;
		    }
		}
		if (readlink (dp->d_name, symbuf, sizeof(symbuf) - 1) >= 0) {
		    msg ("%s: is a link instead of a directory", dp->d_name);
		    curdir = rcurdir = ocurdir;
		    continue;
		}
		if (chdir (dp->d_name) < 0) {
		    mperror (dp->d_name);
		    curdir = rcurdir = ocurdir;
		    continue;
		}
#ifdef PATHCONVERT
		savep = cwd + strlen(cwd);
		sprintf(savep, "/%s", dp->d_name);
#endif
		dodir (buf, &sb, &sc, (buf[0] != '/'));
		if (chdir ("..") < 0)
		    quiterr (1, "..");
#ifdef PATHCONVERT
		*savep = 0;
#endif
		curdir = rcurdir = ocurdir;
		continue;
	    }
	}

	/* non-directory */
	symlen = readlink (dp->d_name, symbuf, sizeof(symbuf) - 1);
	if (symlen >= 0) {
	    symbuf[symlen] = '\0';
	    if (!equivalent (symbuf, buf))
		msg ("%s: %s", dp->d_name, symbuf);
#ifdef PATHCONVERT
	} else {
	    if (abs2rel(buf, cwd, result, MAXPATHLEN) == NULL)
		quit (2, "%s: Cannot convert.", buf);    
	    if (symlink (result, dp->d_name) < 0)
	        mperror (dp->d_name);
	}
#else
	} else if (symlink (buf, dp->d_name) < 0)
	    mperror (dp->d_name);
#endif
    }

    closedir (df);
    return 0;
}


main (ac, av)
int ac;
char **av;
{
    char *fn, *tn;
    struct stat fs, ts;
    char real[MAXPATHLEN];

    silent = 0;
    if (ac > 1 && !strcmp(av[1], "-silent")) {
	silent = 1;
    }
    if (ac < silent + 2 || ac > silent + 3)
	quit (1, "usage: %s [-silent] fromdir [todir]", av[0]);

    fn = av[silent + 1];
    if (ac == silent + 3)
	tn = av[silent + 2];
    else
	tn = ".";

    /* to directory */
    if (stat (tn, &ts) < 0)
	quiterr (1, tn);
#ifdef S_ISDIR
    if (!(S_ISDIR(ts.st_mode)))
#else
    if (!(ts.st_mode & S_IFDIR))
#endif
	quit (2, "%s: Not a directory", tn);
#ifdef PATHCONVERT
    if (realpath(fn, real) == NULL)
	quiterr (1, "%s: not found.", fn);
    fn = real;
#endif
    if (chdir (tn) < 0)
	quiterr (1, tn);
#ifdef PATHCONVERT
    if (!getcwd(cwd, MAXPATHLEN))
	quiterr (1, "Cannot get current directory.");
#endif

    /* from directory */
    if (stat (fn, &fs) < 0)
	quiterr (1, fn);
#ifdef S_ISDIR
    if (!(S_ISDIR(fs.st_mode)))
#else
    if (!(fs.st_mode & S_IFDIR))
#endif
	quit (2, "%s: Not a directory", fn);

    exit (dodir (fn, &fs, &ts, 0));
}
