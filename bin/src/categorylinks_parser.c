#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

char n = 'A';

int main ()
{
  char c;

  while (fscanf(stdin,"%c",&c) != EOF) {
    if ( c == '\\') {
      fscanf(stdin,"%c",&c);
      if ( n == 'B' || n == 'C' ) {
	fprintf(stdout, "%c", c);
      }
    } else {
      switch( n ) {
      case 'A' :
	if (c == '(') {
	  n = 'B';
	}      
	break;
	
      case 'B' :
	if (c == ',') {
	  n = 'C';
	  fscanf(stdin, "%c", &c);
	  fprintf(stdout, " ");
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	
      case 'C' :
	if (c == '\'') {
	  n = 'D';
	  fscanf(stdin, "%c", &c);
	  fscanf(stdin, "%c", &c);
	  fprintf(stdout, "\n");
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	
      case 'D' :
        if (c == '\'') {
          n = 'E';
        }
        break;
	
      case 'E' :
	if (c == ')') {
	  n = 'A';
	}
	break;
      }
    }
  }

  fclose(stdout) ;
}
