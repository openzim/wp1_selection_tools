CC=gcc
CFLAGS=
LDFLAGS=
SRC=$(wildcard ./src/*.c)
BIN=$(SRC:.c=)

all: $(BIN)
	for i in `ls src/ | grep -v "\.c"` ; do cp ./src/$$i ./ ; done	

%: %.c
	$(CC) -o $@ $< $(CFLAGS)

clean:
	for i in `ls ./src/ | grep -v "\.c"` ; do rm ./src/$$i ; done
	for i in `ls ./ | grep -v "\.pl" | grep -v Makefile | grep -v src` ; do rm ./$$i ; done