
# EXM C UTILS

# Usage notes:
# make V=1 turns on verbose output

# Useful targets: all, install, tests, test_results

USE_MAC = yes

# Shared object suffix is .so on Linux, .dylib on Mac
# GCC shared library creation argument:
#            Linux: -shared; Mac: -dynamiclib
ifeq ($(USE_MAC),no)
	MAC_NAME =
	SO_SUFFIX = so
	USE_XLC = 0
	ifeq ($(USE_XLC),0)
#       	Not XLC: GCC/Linux
		PIC_FLAG = -fPIC
		STD = -std=gnu99
		SHARED = -shared
		WARNS = -Wall
	else
#       	Using XLC
		PIC_FLAG = -qpic
		STD =
		SHARED = -qmkshrobj -qnostaticlink -qnostaticlink=libgcc
		WARNS =
	endif
else
  MAC_NAME = -install_name $(INSTALL_LIB)/libexmcutils.dylib
  SO_SUFFIX = dylib
  SHARED = -dynamiclib -flat_namespace
endif

ENABLE_SHARED = 1
ENABLE_STATIC = 1

# Name the main products:
EXM_CUTILS_SO = lib/libexmcutils.$(SO_SUFFIX)
EXM_CUTILS_A = lib/libexmcutils.a

EXM_CUTILS_LIBS =
ifeq ($(ENABLE_SHARED),1)
	EXM_CUTILS_LIBS += $(EXM_CUTILS_SO)
endif

ifeq ($(ENABLE_STATIC),1)
	EXM_CUTILS_LIBS += $(EXM_CUTILS_A)
endif

all: exmcutils

exmcutils: $(EXM_CUTILS_LIBS)

### Autoconf sanity:

configure: bootstrap
	@echo
	@echo "Configuration is not up to date (bootstrap)!"
	@echo "Run ./bootstrap and ./configure again."
	@echo
	@exit 1

Makefile: configure.ac Makefile.in
	@echo
	@echo "Configuration is not up to date (Makefile)!"
	@echo "Run ./bootstrap and ./configure again."
	@echo
	@exit 1

srcdir = .

# Support GNU DESTDIR for Debian, etc.
# Cf. http://www.gnu.org/prep/standards/html_node/DESTDIR.html
ifeq ($(DESTDIR),)
  INSTALL_PREFIX  = /tmp/exm-install/c-utils
  INSTALL_ETC     = $(INSTALL_PREFIX)/etc
  INSTALL_INCLUDE = $(INSTALL_PREFIX)/include
  INSTALL_LIB     = $(INSTALL_PREFIX)/lib
else
  INSTALL_PREFIX  = $(DESTDIR)
  INSTALL_ETC     = $(DESTDIR)/etc
  INSTALL_INCLUDE = $(DESTDIR)/include
  INSTALL_LIB     = $(DESTDIR)/lib
endif

ifeq ($(V),1)
	QUIET_COMPILE = 0
else
	QUIET_COMPILE = 1
endif

ifeq ($(QUIET_COMPILE),1)
  # Prints a short description of the action, does not show command
  Q=@echo
  E=@
else
  # Just echo the entire command
  Q=@echo >/dev/null
  E=
endif

# INCLUDES

SRCS :=
DEPS :=
OBJS :=
include src/module.mk

dirname = $(patsubst %/,%,$(dir $(1)))

### FLAGS

CC = mpicc
CFLAGS := -g -O2
LDFLAGS := 
CFLAGS += -I $(srcdir) -I $(srcdir)/src $(STD) $(WARNS)
ifeq ($(ENABLE_SHARED),1)
	PIC = $(PIC_FLAG)
	CFLAGS += $(PIC)
endif

RPATH = -Wl,-rpath -Wl,$(INSTALL_LIB)

AR      = ar
ARFLAGS = cr
RANLIB  = ranlib

### DEPENDENCIES

deps: $(DEPS)

# default rule for generating dependency files (deps)
%.d: %.c
	$(Q) "  DEP		$@"
	$(E) CC="$(CC)" $(srcdir)/maint/depend.sh \
             $(call dirname, $*) $(CFLAGS) $< > $@

ifeq (,$(filter clean deps,$(MAKECMDGOALS)))
  -include $(DEPS)
endif

# Check existing *.d files for files that do not exist
# Useful when dependency file generation is failing
# Must "make clean" to re-check correctly
EXISTING_D = $(shell find . -name *.d)

check_includes: deps_contents.txt
	$(Q) "  CHECK.SH"
	$(E) $(srcdir)/maint/check.sh deps_contents.txt

deps_contents.txt:
	$(Q) "  SH		$(@)"
	$(E) $(srcdir)/maint/collect.sh $(@) $(EXISTING_D)

### COMPILE

%.o: %.c
	$(Q) "  CC		$@"
#       This line causes a false autoscan warning on token 'CC' (C++)
	$(E) $(CC) $(CFLAGS) -c $(<) -o $(@)

### LINK

$(EXM_CUTILS_SO): $(OBJS)
	$(Q) "  LINK		$@"
#       This line causes a false autoscan warning on token 'install'
	$(E) install -d lib
	$(E) $(CC) $(SHARED) $(PIC) $(MAC_NAME) -o $(@) $(OBJS) -lm
#       Touch this so re-installation has the correct source directory
	$(E) touch source.txt

$(EXM_CUTILS_A): $(OBJS)
	$(Q) "  AR		$@"
	$(E) install -d lib
	$(E) $(AR) $(ARFLAGS) $(@) $(OBJS)
	$(E) $(RANLIB) $(@)

### TEST

TEST_SRC :=
include tests/module.mk
TEST_DEPS = $(patsubst %.c, %.d, $(TEST_SRC))
TEST_OBJS = $(patsubst %.c, %.o, $(TEST_SRC))
TESTS     = $(patsubst %.c, %.x, $(TEST_SRC))
# Test case results
TEST_SCRIPTS = $(patsubst %.c,  %.sh, $(TEST_SRC))
# Test case outputs
TEST_OUTPUT  = $(patsubst %.c, %.out, $(TEST_SRC))
# Test case results
TEST_RESULTS = $(patsubst %.c, %.result, $(TEST_SRC))

# Target to just build all C tests
tests: $(TESTS)

# Run all tests
test_results: $(TEST_RESULTS)

# Test result rule for C tests
%.result: %.sh %.x install.txt
	$(Q) "  SH		$(@)"
	$(E) rm -f $(@)
	$(E) $(<) > $(*).tmp 2>&1
	$(E) mv $(*).tmp $(@) 2>&1

$(TESTS): %.x: %.o $(EXM_CUTILS_LIBS) install.txt
	$(Q) "  LINK		$(@)"
	$(E) $(CC) $(PIC) $(LDFLAGS) $(<) \
                   -L$(INSTALL_LIB) -lexmcutils \
                   -o $(@) \
                   $(RPATH)

### INSTALL

HAVE_CP_U = no
ifeq ($(HAVE_CP_U),yes)
	CP_ARGS = -uv
else
	CP_ARGS = -v
endif

PROVENANCE = version.txt source.txt config.log

# Used to make sure installed headers are up-to-date
HEADERS = $(wildcard src/*.h)

$(INSTALL_PREFIX)/install.txt: $(EXM_CUTILS_LIBS) $(HEADERS)
	@echo
	$(Q) "  INSTALL: $(INSTALL_PREFIX)"
	$(E) touch install.txt
#       Set up directories
	$(E) mkdir -pv $(INSTALL_PREFIX)
	$(E) mkdir -pv $(INSTALL_ETC)
	$(E) mkdir -pv $(INSTALL_INCLUDE)
	$(E) mkdir -pv $(INSTALL_LIB)
	$(E) cp $(CP_ARGS) $(PROVENANCE) $(INSTALL_ETC)
	$(E) cp $(CP_ARGS) install.txt $(INSTALL_ETC)
#       Install the headers and library
	$(E) cp $(CP_ARGS) c-utils-config.h $(INSTALL_INCLUDE)
	$(E) cp $(CP_ARGS) src/*.h $(INSTALL_INCLUDE)
	$(E) cp $(CP_ARGS) $(EXM_CUTILS_LIBS) $(INSTALL_LIB)
#       Finally, copy in the token install.txt file
	$(E) cp $(CP_ARGS) install.txt $(@)

# Maintaining the install.txt file is a simple way to
# create a dependency on the installation
install: $(INSTALL_PREFIX)/install.txt

### CLEAN

clean:
	$(Q) "  CLEAN:"
	$(E) rm -fv $(DEPS) deps_contents.txt
	$(E) rm -fv src/*.o
	$(E) rm -fv $(EXM_CUTILS_SO) $(EXM_CUTILS_A)
	$(E) rm -fv $(TESTS) $(TEST_DEPS) $(TEST_OBJS)

distclean: clean
	@rm -fv Makefile **/*.mk
	@rm -fv src/c-utils.h

.PHONY: clean install

### MAKEFILE DEBUGGING

debug_build:
	@echo DEPS: $(DEPS)
