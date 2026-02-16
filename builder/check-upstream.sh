#!/bin/bash

git -C /app/Enzyme fetch

declare -a branches=("main")


for branch in ${branches[@]}; do

   HEADHASH=$(git -C /app/Enzyme rev-parse $branch)
   UPSTREAMHASH=$(git -C /app/Enzyme rev-parse $branch@{upstream})

   if [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      source /app/build-enzyme.sh
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   JHEADHASH=$(git -C /app/Enzyme-JaX rev-parse $branch)
   JUPSTREAMHASH=$(git -C /app/Enzyme-JaX rev-parse $branch@{upstream})

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] 
   then
      source /app/build-enzyme.sh
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] || [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      source /app/update-explorer.sh
   fi
done
