
CC= gcc -no-pie

CFLAGS= -g -march=native
SQLFLAGS= `mysql_config --cflags --libs`

# Comment this line to disable address check on login,
# if you use the auto exchange feature...
CFLAGS += -DNO_EXCHANGE

#CFLAGS=-c -O2 -I /usr/include/mysql
LDFLAGS=-O2 `mysql_config --libs`

LDLIBS=iniparser/libiniparser.a algos/libalgos.a sha3/libhash.a -Isecp256k1/include secp256k1/.libs/libsecp256k1.a -lpthread -lgmp -lm -lstdc++ -lssl -lcrypto 
LDLIBS+=-lmysqlclient

SOURCES=stratum.cpp db.cpp coind.cpp coind_aux.cpp coind_template.cpp coind_submit.cpp util.cpp list.cpp \
	rpc.cpp job.cpp job_send.cpp job_core.cpp merkle.cpp share.cpp socket.cpp coinbase.cpp \
	client.cpp client_submit.cpp client_core.cpp client_difficulty.cpp remote.cpp remote_template.cpp \
	user.cpp object.cpp json.cpp base58.cpp

CFLAGS += -DHAVE_CURL
SOURCES += rpc_curl.cpp
LDCURL = $(shell /usr/bin/pkg-config --static --libs libcurl)
LDFLAGS += $(LDCURL)

OBJECTS=$(SOURCES:.cpp=.o)
OUTPUT=stratum

CODEDIR1=algos
CODEDIR2=sha3
CODEDIR3=iniparser
CODEDIR4=secp256k1


.PHONY: projectcode1 projectcode2 projectcode3 projectcode4

all: projectcode1 projectcode2 projectcode3 projectcode4 $(SOURCES) $(OUTPUT)

projectcode1:
	git submodule init && git submodule update && $(MAKE) -C $(CODEDIR1)

projectcode2:
	$(MAKE) -C $(CODEDIR2)
	
projectcode3:
	$(MAKE) -C $(CODEDIR3)

projectcode4:
	cd $(CODEDIR4) && chmod +x autogen.sh && ./autogen.sh && ./configure --enable-experimental --enable-module-ecdh --with-bignum=no --enable-endomorphism && $(MAKE)

$(SOURCES): stratum.h util.h

$(OUTPUT): $(OBJECTS)
	$(CC) $(OBJECTS) $(LDLIBS) $(LDFLAGS) -o $@

.cpp.o:
	$(CC) $(CFLAGS) $(SQLFLAGS) -c $<

.c.o:
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.o
	rm -f algos/*.o
	rm -f algos/*.a
	rm -f sha3/*.o
	rm -f sha3/*.a
	rm -f algos/ar2/*.o

install: clean all
	strip -s stratum
	cp stratum /usr/local/bin/
	cp stratum ../bin/

