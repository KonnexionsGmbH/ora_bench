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

CLASSPATH := ".;$(JAVA_JAR_DIR)/commons-beanutils-1.9.4.jar;$(JAVA_JAR_DIR)/commons-codec-1.13.jar;$(JAVA_JAR_DIR)/commons-configuration2-2.6.jar;$(JAVA_JAR_DIR)/;$(JAVA_JAR_DIR)/commons-csv-1.7.jar;$(JAVA_JAR_DIR)/;$(JAVA_JAR_DIR)/commons-lang3-3.9.jar;$(JAVA_JAR_DIR)/commons-logging-1.2.jar;$(JAVA_JAR_DIR)/commons-text-1.8.jar;$(JAVA_JAR_DIR)/ojdbc10.jar;$(JAVA_JAR_DIR)/ora_bench.jar"
SOURCES := $(shell find $(JAVA_SRC_DIR) -type f \( -name "*.java" \))

COMPILE_JAVAC = $(javac_verbose) $(JAVAC) -g -deprecation -Werror \
	-sourcepath $(JAVA_SRC_DIR)

$(JAVA_JAR_OUT): $(SOURCES)
	@export CLASSPATH=$(CLASSPATH)
	$(javac_verbose) $(COMPILE_JAVAC) $(SOURCES)
	$(jar_verbose) $(JAR) cf $@ -C $(JAVA_SRC_DIR) ch
	@rm -f $(shell find $(JAVA_SRC_DIR) -type f \( -name "*.class" \))

clean:
	@rm -f $(JAVA_JAR_OUT)
