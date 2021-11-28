O = .
S = lang/c
ODPI_REPO = https://github.com/oracle/odpi

SRCS = $(wildcard $(S)/*.c)
ODPIROOT = $(S)/odpi
ODPI_LIB_DIR = $(S)/odpi/lib

TARGET = $(O)/OraBench

INCLUDEDIRS = -I$(S) -I"$(S)/odpi/include"
CFLAGS = $(INCLUDEDIRS) -O2 -ggdb -Wall -fPIC -std=gnu11
LDFLAGS = -lpthread

ifdef LINKODPI
LDFLAGS += -L$(ODPI_LIB_DIR) -lodpic
else
CFLAGS += -DEMBED -D_GNU_SOURCE
LDFLAGS += -ldl 
endif

ifeq ($(shell uname -s), Darwin)
	CFLAGS += -dynamiclib 
	LDFLAGS += -flat_namespace -undefined suppress
endif

all: priv odpi $(TARGET)

$(TARGET): $(SRCS)
	gcc -o $@ $(CFLAGS) $(SRCS) $(LDFLAGS)

priv:
	mkdir -p $(O)

odpi:
	@if [ ! -d "$(ODPIROOT)" ]; then \
		cd $(S) && (git clone -b v4.3.0 --single-branch $(ODPI_REPO)) \
	fi
	@if [ ! -z "${LINKODPI}" -a ! -d "$(ODPI_LIB_DIR)" ]; then \
		cd $(ODPIROOT) && (make) \
	fi

clean:
	rm -rf $(O)/*.obj
	rm -rf $(TARGET)

clean_all: clean
	rm -rf $(ODPIROOT)
