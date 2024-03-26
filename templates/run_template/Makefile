# Makefile for various platforms
# Execute using Build csh-script only!
# Used together with Perl scripts in SRC/SCRIPT
# (C) 2005 Marat Khairoutdinov
#------------------------------------------------------------------
# uncomment to disable timers:
#
#NOTIMERS=-DDISABLE_TIMERS
#-----------------------------------------------------------------

LIB_MPI = ${MPI_LIB}
INC_MPI = ${MPI_INCLUDE}
LIB_NETCDF = ${NETCDF_LIB}
INC_NETCDF = ${NETCDF_INCLUDE}

SAM = SAM_$(ADV_DIR)_$(SGS_DIR)_$(RAD_DIR)_$(MICRO_DIR)

# Determine platform 
PLATFORM := $(shell uname -s)

ifeq ($(PLATFORM),Linux)

MPIF90 = mpiifort
FF77 = ${MPIF90} -c -fixed -extend-source -r8
FF90 = ${MPIF90} -c -r8
CC = mpicc -c -DLINUX

FFLAGS = -O3 -fp-model source
FFLAGS_NOOPT = -O0 -g -ftrapuv -check all -traceback -debug -gen-interfaces -warn interfaces -fp-model source
#FFLAGS = ${FFLAGS_NOOPT}

#FFLAGS += -I${INC_MPI} -I${INC_NETCDF}
FFLAGS += -I${FPATH}
FFLAGS_NOOPT += -I${FPATH}
LD = ${MPIF90}
#LDFLAGS = -L${LIB_NETCDF} -lnetcdf -lnetcdff
LDFLAGS = -L${LIBRARY_PATH} -lnetcdf -lnetcdff

endif

#----------------------------------
#----------------------------------------------
# you dont need to edit below this line

#compute the search path
dirs := . $(shell cat Filepath)
VPATH    := $(foreach dir,$(dirs),$(wildcard $(dir)))

.SUFFIXES:
.SUFFIXES: .f .f90 .c .o

all: $(SAM_DIR)/$(SAM)

SOURCES   := $(shell cat Srcfiles)

Depends: Srcfiles Filepath
        $(SAM_SRC)/SCRIPT/mkDepends Filepath Srcfiles > $@

Srcfiles: Filepath
        $(SAM_SRC)/SCRIPT/mkSrcfiles > $@

OBJS      := $(addsuffix .o, $(basename $(SOURCES)))

$(SAM_DIR)/$(SAM): $(OBJS)
        $(LD) -o $@ $(OBJS) $(LDFLAGS)

rrtmg_lw_k_g.o: $(SAM_SRC)/SRC/RAD_RRTM_CFMIP/rrtmg_lw_k_g.f90
        ${FF90}  ${FFLAGS_NOOPT} $<

rrtmg_sw_k_g.o: $(SAM_SRC)/SRC/RAD_RRTM_CFMIP/rrtmg_sw_k_g.f90
        ${FF90}  ${FFLAGS_NOOPT} $<

.f90.o:
        ${FF90}  ${FFLAGS} $<
.f.o:
        ${FF77}  ${FFLAGS} $<
.c.o:
        ${CC}  ${CFLAGS} -I$(SAM_SRC)/TIMING $(NOTIMERS) $<

include Depends

clean: 
        rm ./OBJ/*
