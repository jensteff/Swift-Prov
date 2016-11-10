
DIR := src/tcl

TCL_LIB = -L/Users/jennysteffens/anaconda/lib -ltcl8.5

TCL_LINK_FLAGS = -DUSE_TCL_STUBS -fPIC $(TCL_LIB)

TCL_TURBINE_SRC += $(DIR)/util.c
