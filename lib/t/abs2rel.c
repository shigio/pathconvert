#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/param.h>
#include <errno.h>

char	*abs2rel __P((const char *, const char *, char *, size_t));

int
main(argc, argv)
int	argc;
char	*argv[];
{
	char result[MAXPATHLEN];
	char cwd[MAXPATHLEN];

	if (argc < 2) {
		fprintf(stderr, "usage: abs2rel path [base]\n");
		exit(1);
	}
	if (argc == 2) {
		if (!getcwd(cwd, MAXPATHLEN)) {
			fprintf(stderr, "cannot get current directory.\n");
			exit(1);
		}
	} else
		strcpy(cwd, argv[2]);
	
	if (abs2rel(argv[1], cwd, result, MAXPATHLEN)) {
		printf("%s\n", result);
	} else
		printf("ERROR\n");
	exit(0);
}
