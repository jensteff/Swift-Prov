
# MODULE TCL-PYTHON

DIR := src/tcl/python

TCL_PYTHON_SRC := $(DIR)/tcl-python.c

PY_VERSION_MAJOR  = 2
PY_VERSION_MINOR  = 7
PY_VERSION_SUFFIX = 
PYTHON_VERSION = \
	$(PY_VERSION_MAJOR).$(PY_VERSION_MINOR)$(PY_VERSION_SUFFIX)

$(DIR)/turbine-python-version.h: $(DIR)/turbine-python-version.h.m4 \
                                 config.h
	$(Q) "  M4		$(@)"
	$(E) m4 -D PYTHON_VERSION=$(PYTHON_VERSION) $(<) > $(@)
