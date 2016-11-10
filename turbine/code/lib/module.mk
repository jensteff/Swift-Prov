
DIR := lib

# List of Turbine Tcl libraries
# Must be kept in sync with list in make-package.tcl
TCL_SRC := $(DIR)/helpers.tcl             \
           $(DIR)/turbine.tcl             \
           $(DIR)/worker.tcl              \
           $(DIR)/data.tcl                \
           $(DIR)/functions.tcl           \
           $(DIR)/assert.tcl              \
           $(DIR)/logical.tcl             \
           $(DIR)/arith.tcl               \
           $(DIR)/string.tcl              \
           $(DIR)/container.tcl           \
           $(DIR)/rand.tcl                \
           $(DIR)/reductions.tcl          \
           $(DIR)/stats.tcl               \
           $(DIR)/io.tcl                  \
           $(DIR)/updateable.tcl          \
           $(DIR)/sys.tcl                 \
           $(DIR)/blob.tcl                \
           $(DIR)/mpe.tcl		  \
	   $(DIR)/files.tcl               \
	   $(DIR)/location.tcl            \
	   $(DIR)/checkpoint.tcl          \
	   $(DIR)/app.tcl                 \
	   $(DIR)/langs.tcl               \
	   $(DIR)/gemtc_worker.tcl

# Builds the Turbine Tcl package
$(PACKAGE): lib/make-package.tcl $(TCL_TURBINE_SO) \
            $(TCL_SRC)
	$(Q) "  TCL		$(@)"
	$(E) TURBINE_VERSION=$(TURBINE_VERSION) \
	     USE_MPE=0 \
	     USE_MAC=yes \
             $(TCLSH_LOCAL) $(<) > lib/pkgIndex.tcl
