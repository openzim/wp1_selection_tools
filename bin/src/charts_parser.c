#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>

char n = 'A';
char h1, h2;

char hex2int(char c) 
{
  if(c >= '0' && c <= '9')
    return c - '0';
  if(c >= 'A' && c <= 'F')
    return c - 'A' + 10;
  if(c >= 'a' && c <= 'f')
    return c - 'a' + 10;
  return -1;
}

int main ()
{
  char c;

  while (fscanf(stdin,"%c",&c) != EOF) {
    if ( c == '\\') {
      fscanf(stdin,"%c",&c);
      fprintf(stdout, "%c", c);
    }
    else if ( c == '%') {
      fscanf(stdin,"%c",&h1);
      fscanf(stdin,"%c",&h2);
      c = hex2int(h1)*16 + hex2int(h2);
      if (c == ' ')
      	c = '_';
      fprintf(stdout, "%c", c );
    } 
    else {
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
	}
	break;
	
      case 'C' :
	if (c == '\'') {
	  n = 'D';
	  fscanf(stdin, "%c", &c);
	  fscanf(stdin, "%c", &c);
	  fprintf(stdout, " ");
	} else {
	  fprintf(stdout, "%c", c);
	}
	break;
	

      case 'D' :
        if (c == '\'') {
          n = 'E';
          fscanf(stdin, "%c", &c);
          fprintf(stdout, " ");
        } else {
          fprintf(stdout, "%c", c);
        }
        break;

      case 'E' :
        if (c == ',') {
          n = 'F';
          fprintf(stdout, "\n");
        } else {
          fprintf(stdout, "%c", c);
        }
        break;

      case 'F' :
	if (c == ')') {
	  n = 'A';
	}
	break;
      }
    }
  }

  fclose(stdout) ;
}
