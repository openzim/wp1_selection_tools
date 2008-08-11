CC=gcc
CFLAGS=-O
LDFLAGS=
SRC=$(wildcard ./src/*.c)
BIN=$(SRC:.c=)

all: $(BIN)
	for i in `ls src/ | grep -v "\.c"` ; do cp ./src/$$i ./bin/ ; done	

%: %.c
	$(CC) -o $@ $< $(CFLAGS)

clean:
	for i in `ls ./src/ | grep -v "\.c"` ; do rm ./src/$$i ; done
	for i in `ls ./bin/ | grep -v "\.pl"` ; do rm ./bin/$$i ; done
