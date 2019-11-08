SHELL = /bin/bash

CURDIR := .

JAVA_JAR_DIR = $(CURDIR)/priv/java_jar
JAVA_JAR_OUT ?= $(JAVA_JAR_DIR)/ora_bench.jar
JAVA_SRC_DIR = $(CURDIR)/java_src

JAVAC ?= javac
JAR ?= jar

javac_verbose_0 = @echo " JAVAC     " $(?F);
javac_verbose = $(javac_verbose_$(V))

jar_verbose_0 = @echo " JAR    " $(@F);
jar_verbose = $(jar_verbose_$(V))

SOURCES := $(shell find $(JAVA_SRC_DIR) -type f \( -name "*.java" \))

COMPILE_JAVAC = $(javac_verbose) $(JAVAC) -g -deprecation -Werror \
	-cp ".:$(JAVA_JAR_DIR)/*" \
	-sourcepath $(JAVA_SRC_DIR)

$(JAVA_JAR_OUT): $(SOURCES)
	$(javac_verbose) $(COMPILE_JAVAC) $(SOURCES)
	$(jar_verbose) $(JAR) cf $@ -C $(JAVA_SRC_DIR) ch
	@rm -f $(shell find $(JAVA_SRC_DIR) -type f \( -name "*.class" \))

clean:
	@rm -f $(JAVA_JAR_OUT)
