
########################################################################
#
# Sample GNU Makefile for building JVMTI Demo heapViewer
#
#  Example uses:    
#       gnumake JDK=<java_home> OSNAME=linux   [OPT=true]
#
########################################################################

# Source lists
LIBNAME=heapViewer

# Linux GNU C Compiler
ifeq ($(OSNAME), linux)
    # GNU Compiler options needed to build it
    COMMON_FLAGS=-fno-strict-aliasing -fPIC -fno-omit-frame-pointer
    # Options that help find errors
    COMMON_FLAGS+= -W  -Wno-parentheses # -Wall -Wunused-parameter
    ifeq ($(OPT), true)
        CFLAGS=-O2 $(COMMON_FLAGS) 
    else
        CFLAGS=-g $(COMMON_FLAGS) 
    endif
    # Libraries we are dependent on
    LIBRARIES=-lc -ldl
    # Building a shared library
    LINK_SHARED=$(LINK.c) -shared -o $@
endif

# Common -I options
CFLAGS += -I.
CFLAGS += -I$(JDK)/include -I$(JDK)/include/$(OSNAME)

LDFLAGS:=

ANALYSIS_LIB:=

OBJS_FILES:=

SRCS:=

# Source list, common part
SRCS+=../core/list.c ../core/common.c ../core/from_dsl0.c ../core/RuntimeObjects.c
