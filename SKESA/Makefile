# ===========================================================================
#
#                            PUBLIC DOMAIN NOTICE
#               National Center for Biotechnology Information
#
#  This software/database is a "United States Government Work" under the
#  terms of the United States Copyright Act.  It was written as part of
#  the author's official duties as a United States Government employee and
#  thus cannot be copyrighted.  This software/database is freely available
#  to the public for use. The National Library of Medicine and the U.S.
#  Government have not placed any restriction on its use or reproduction.
#
#  Although all reasonable efforts have been taken to ensure the accuracy
#  and reliability of the software and data, the NLM and the U.S.
#  Government do not and cannot warrant the performance or results that
#  may be obtained by using this software or data. The NLM and the U.S.
#  Government disclaim all warranties, express or implied, including
#  warranties of performance, merchantability or fitness for any particular
#  purpose.
#
#  Please cite the author in any work or product based on this material.
#
# ===========================================================================

# BOOST_PATH := /netopt/ncbi_tools64/boost-1.62.0-ncbi1
# VDB_PATH := /net/snowman/vol/projects/trace_software/vdb/vdb-versions/2.10.5
# NGS_PATH := /net/snowman/vol/projects/trace_software/ngs/ngs-versions/2.10.5

GCC_VERSION := 7.3.0
GCC_BIN := /opt/ncbi/gcc/$(GCC_VERSION)/bin
BOOST_TAG := -gcc73-mt
GCC := $(GCC_BIN)/gcc

ifdef BOOST_PATH
BOOST_INCPATH := -I$(BOOST_PATH)/include
BOOST_LIBPATH := -L$(BOOST_PATH)/lib
endif

VDB_INCPATH := -I$(VDB_PATH)/interfaces
VDB_LIBPATH := -L$(VDB_PATH)/linux/release/x86_64/lib

NGS_INCPATH := -I$(NGS_PATH)/include
NGS_LIBPATH := -L$(NGS_PATH)/linux/release/x86_64/lib


CC = $(GCC_BIN)/g++ -std=c++11 -fdiagnostics-color=never
CFLAGS = -Wall -Wno-format-y2k  -pthread -fPIC -O3 -finline-functions -fstrict-aliasing \
         -fomit-frame-pointer -msse4.2 $(BOOST_INCPATH) $(NGS_INCPATH) $(VDB_INCPATH)

PLATFORM=$(shell uname -s)

ifeq ($(PLATFORM),Linux)

LIBS = $(VDB_LIBPATH) -lncbi-ngs-c++ -lncbi-vdb \
       $(NGS_LIBPATH) -lngs-c++ \
       -Wl,-Bstatic $(BOOST_LIBPATH) \
       -lboost_program_options$(BOOST_TAG) \
       -lboost_iostreams$(BOOST_TAG) \
       -lboost_regex$(BOOST_TAG) \
       -lboost_timer$(BOOST_TAG) \
       -lboost_chrono$(BOOST_TAG) \
       -lboost_system$(BOOST_TAG) \
       -Wl,-Bdynamic -lrt -ldl -lm  -lpthread -lz

else

LIBS = $(BOOST_LIBPATH) \
       -lboost_program_options$(BOOST_TAG) \
       -lboost_iostreams$(BOOST_TAG) \
       -lboost_regex$(BOOST_TAG) \
       -lboost_timer$(BOOST_TAG) \
       -lboost_chrono$(BOOST_TAG) \
       -lboost_system$(BOOST_TAG) \
       -ldl -lm -lpthread -lz

endif

%.o: %.cpp
	$(CC) -c -o $@ $< $(CFLAGS)

.DEFAULT_GOAL := binaries
.PHONY: binaries clean

binaries: skesa gfa_connector kmercounter

clean: 
	rm -f $(binaries) *.o

glb_align.o: glb_align.hpp Makefile

skesa.o: common_util.hpp concurrenthash.hpp readsgetter.hpp ngs_includes.hpp counter.hpp graphdigger.hpp assembler.hpp KmerInit.hpp DBGraph.hpp Integer.hpp LargeInt.hpp LargeInt1.hpp LargeInt2.hpp Model.hpp config.hpp glb_align.hpp Makefile
skesa: skesa.o glb_align.o
	$(CC) -o $@ $^ $(LIBS)

gfa_connector.o: gfa.hpp glb_align.hpp common_util.hpp concurrenthash.hpp readsgetter.hpp ngs_includes.hpp graphdigger.hpp KmerInit.hpp  DBGraph.hpp Integer.hpp LargeInt.hpp LargeInt1.hpp LargeInt2.hpp Model.hpp config.hpp Makefile
gfa_connector: gfa_connector.o glb_align.o
	$(CC) -o $@ $^ $(LIBS)

kmercounter.o: common_util.hpp concurrenthash.hpp readsgetter.hpp ngs_includes.hpp counter.hpp graphdigger.hpp assembler.hpp KmerInit.hpp DBGraph.hpp Integer.hpp LargeInt.hpp LargeInt1.hpp LargeInt2.hpp Model.hpp config.hpp glb_align.hpp Makefile
kmercounter: kmercounter.o glb_align.o
	$(CC) -o $@ $^ $(LIBS)

