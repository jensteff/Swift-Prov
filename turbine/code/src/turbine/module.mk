
DIR := src/turbine

TURBINE_SRC += $(DIR)/turbine.c
TURBINE_SRC += $(DIR)/cache.c
TURBINE_SRC += $(DIR)/run.c
TURBINE_SRC += $(DIR)/worker.c
TURBINE_SRC += $(DIR)/services.c
TURBINE_SRC += $(DIR)/async_exec.c
TURBINE_SRC += $(DIR)/sync_exec.c
TURBINE_SRC += $(DIR)/executors/noop_executor.c
TURBINE_SRC += $(DIR)/io.c
TURBINE_SRC += $(DIR)/prov.c
TURBINE_SRC += $(DIR)/prov_wrap.c

ifeq ($(HAVE_COASTER),1)
  TURBINE_SRC += $(DIR)/executors/coaster_executor.c
endif
