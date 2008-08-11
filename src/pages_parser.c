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
      if ( n == 'B' || n == 'C' || n == 'D' ) {
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
	  fprintf(stdout, " ");
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	
      case 'C' :
	if (c == ',') {
	  n = 'D';
	  fscanf(stdin, "%c", &c);
	  fprintf(stdout, " ");
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	
      case 'D' :
	if (c == '\'') {
	  n = 'E';
	  fprintf(stdout, " ");
	  fscanf(stdin, "%c", &c);
	  fscanf(stdin, "%c", &c);
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	
      case 'E' :
	if (c == '\'') {
	  n = 'F';
	  fscanf(stdin, "%c", &c);
	}
	break;

      case 'F' :
	if (c == ',') {
	  n = 'G';
	}
	break;

      case 'G' :
	if (c == ',') {
	  n = 'H';
	  fprintf(stdout, "\n");
	}
	else {
	  fprintf(stdout, "%c", c);
	}
	break;
      
      case 'H' :
	if (c == ',') {
	  n = 'I';
	}
	break;
	
      case 'I' :
	if (c == ',') {
	  fscanf(stdin, "%c", &c);
	  n = 'J';
	}
	break;
	
      case 'J' :
	if (c == '\'') {
	  n = 'K';
	  fscanf(stdin, "%c", &c);
	}
	break;

      case 'K' :
        if (c == ',') {
          fscanf(stdin, "%c", &c);
          n = 'L';
        }
        break;

      case 'L' :
        if (c == ')') {
          fscanf(stdin, "%c", &c);
          n = 'A';
        }
        break;
	
      }
    }
  }

  fclose(stdout) ;
}
