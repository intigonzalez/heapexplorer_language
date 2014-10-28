
#Objects
OBJS:=$(SRCS:%.c=%.o)

JAJA:=$(shell pwd)

installplugins: plugin
	@echo "Installing plugins"
	@echo $(JAJA)
	@echo "$(JAJA)/$(ANALYSIS_LIB)" | tr " " "\n" > config.ini

plugin: $(ANALYSIS_LIB)
	@echo "Done $<"

$(ANALYSIS_LIB): $(OBJS)
	$(CC) $(CFLAGS) -Wl,-soname=$@ -static-libgcc -L. $(LDFLAGS) -shared -o $@ $^ -lc -l${LIBNAME}

%.o: %.c
	@echo "Building $@"
	$(CC) $(CFLAGS) -std=c99 -c -o $@ $<

# Cleanup the built bits
clean:
	rm -f $(ANALYSIS_LIB)
	rm -f $(OBJS)
