#!/bin/bash

git -C /app/Enzyme fetch
git -C /app/Enzyme-JaX fetch
git -C /Reactant fetch

declare -a branches=("main")

for branch in ${branches[@]}; do

   commit="None"
   ejaxcommit="None"
   reactantcommit="None"

   HEADHASH=$(git -C /app/Enzyme rev-parse $branch)
   UPSTREAMHASH=$(git -C /app/Enzyme rev-parse $branch@{upstream})
   commit=$(git -C /app/Enzyme rev-parse --short=7 HEAD)
   if [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      echo -e ${FINISHED}Updating Enzyme, old was $HEADHASH new was $UPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme checkout $branch
      git -C /app/Enzyme fetch
      git -C /app/Enzyme reset --hard origin/$branch
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   JHEADHASH=$(git -C /app/Enzyme-JaX rev-parse $branch)
   JUPSTREAMHASH=$(git -C /app/Enzyme-JaX rev-parse $branch@{upstream})
   ejaxcommit=$(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD)

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] 
   then
      echo -e ${FINISHED}Updating Enzyme-JaX, old was $JHEADHASH new was $JUPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme-JaX checkout $branch
      git -C /app/Enzyme-JaX fetch
      git -C /app/Enzyme-JaX reset --hard origin/$branch
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   RHEADHASH=$(git -C /app/Reactant rev-parse $branch)
   RUPSTREAMHASH=$(git -C /app/Reactant rev-parse $branch@{upstream})
   reactantcommit=$(git -C /app/Reactant rev-parse --short=7 HEAD)

   if [ "$RHEADHASH" != "$RUPSTREAMHASH" ] 
   then
      echo -e ${FINISHED}Updating Reactant, old was $RHEADHASH new was $RUPSTREAMHASH ${NOCOLOR}
      git -C /app/Reactant checkout $branch
      git -C /app/Reactant fetch
      git -C /app/Reactant reset --hard origin/$branch
   else
      echo -e ${FINISHED}Current branch is up to date with origin/$branch.${NOCOLOR}
   fi

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] || [ "$RHEADHASH" != "$RUPSTREAMHASH" ]  || [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      python3 /app/scripts/update-versions.py /app/data /app/template_files/etc/config /app/compiler-explorer/etc/config $commit $ejaxcommit $reactantcommit
      source /app/update-explorer.sh
   fi
done
