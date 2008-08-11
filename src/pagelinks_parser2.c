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

  char fromID[50];
  char toNS[4];
  char toTitle[1000];

  int index = 0;
 
  long int goodlinks = 0;
  long int badlinks = 0;
  long int lines = 0;
  int countoutput = 0;

  while (fscanf(stdin,"%c",&c) != EOF) {
      switch( n ) {
      case 'A' :
        if ( c == '\n'){ 
          lines++;
	} else if (c == '(') {
	  n = 'B';
          index = 0;
	}      
	break;
	
      case 'B' :
//        if ( c == '\\') {
//          fscanf(stdin,"%c",&c);
//          fromID[index++] = c;
//        } else 
       if (c == ',') {
	  n = 'C';
          fromID[index] = '\0';
          index = 0;
	} else {
          fromID[index++] = c;
	}
	break;
	
      case 'C' :
//        if ( c == '\\') {
//          fscanf(stdin,"%c",&c);
//          toNS[index++] = c;
//	} else 
        if (c == ',') {
	  n = 'D';
          toNS[index] = '\0';
          index = 0;
          fscanf(stdin,"%c",&c);  // Skip opening single quote
	} else {
	  toNS[index++] = c;
	}
	break;
	
      case 'D' :
        if ( c == '\\') {
          fscanf(stdin,"%c",&c);
          toTitle[index++] = c;
	} else if (c == '\'') {
	  n = 'A';
          toTitle[index] = '\0';
          index = 0;
          if ( ! strcmp(toNS, "0") ) { 
            fprintf(stdout, "%s %s\n", fromID, toTitle);
            goodlinks++;
          } else { 
            badlinks++;       
          }
          if ( 0 == goodlinks % 2500000 ) { 
             countoutput++;
//            fprintf(stderr, "pagelinks_parser %d: %6ld lines %10ld kept %10ld skipped\n", 
//                            countoutput, lines, goodlinks, badlinks);
             fprintf(stderr, ".");
          }

	} else {
          toTitle[index++] = c;
	}
	break;
  
    }  
  }

  fprintf(stderr, "\n");
  fclose(stdout) ;
}
