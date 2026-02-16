#!/bin/bash

old_clang=$(readlink -f /opt/compiler-explorer/clang-assertions-trunk)

/app/infra/bin/ce_install check-installed compilers/c++/nightly/clang assertions-trunk --enable nightly | grep "not installed"
uptodate=$?

   if [ "$uptodate" != 0 ]
   then
      /app/infra/bin/ce_install install compilers/c++/nightly/clang assertions-trunk --enable nightly
      rm -rf $old_clang
      exit 0
   else
      echo -e ${FINISHED}Compilers are up to date.${NOCOLOR}
   fi
