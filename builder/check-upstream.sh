#!/bin/bash

git -C /app/Enzyme fetch
git -C /app/Enzyme-JaX fetch

declare -a branches=("main")

for branch in ${branches[@]}; do
   HEADHASH=$(git -C /app/Enzyme rev-parse $branch)
   UPSTREAMHASH=$(git -C /app/Enzyme rev-parse $branch@{upstream})

   commit="None"
   ejaxcommit="None"
   if [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      commit=$(git -C /app/Enzyme rev-parse --short=7 HEAD)
      echo -e ${FINISHED}Updating Enzyme, old was $HEADHASH new was $UPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme checkout $branch
      git -C /app/Enzyme fetch
      git -C /app/Enzyme reset --hard origin/$branch
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   JHEADHASH=$(git -C /app/Enzyme-JaX rev-parse $branch)
   JUPSTREAMHASH=$(git -C /app/Enzyme-JaX rev-parse $branch@{upstream})

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] 
   then
      ejaxcommit=$(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD)
      echo -e ${FINISHED}Updating Enzyme-JaX, old was $JHEADHASH new was $JUPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme-JaX checkout $branch
      git -C /app/Enzyme-JaX fetch
      git -C /app/Enzyme-JaX reset --hard origin/$branch
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] || [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      python3 /app/scripts/update-versions.py /app/data /app/template_files/etc/config /app/compiler-explorer/etc/config $commit $ejaxcommit
      source /app/update-explorer.sh
   fi
done
