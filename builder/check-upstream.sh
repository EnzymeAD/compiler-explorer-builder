#!/bin/bash

   git -C /app/Enzyme fetch origin "+refs/heads/*:refs/remotes/origin/*"
   git -C /app/Enzyme-JaX fetch origin "+refs/heads/*:refs/remotes/origin/*"
   git -C /app/Reactant fetch origin "+refs/heads/*:refs/remotes/origin/*"
   
   get_upstream_hash() {
      project=$1
      workflow=$2
      python3 -c "import sys, json, urllib.request; req = urllib.request.Request('https://api.github.com/repos/EnzymeAD/'+sys.argv[1]+'/actions/workflows/'+sys.argv[2]+'/runs?status=success&branch=main&per_page=1', headers={'User-Agent': 'Mozilla/5.0'}); res = urllib.request.urlopen(req); data = json.loads(res.read()); print(data['workflow_runs'][0]['head_sha']) if data.get('workflow_runs') else print('')" "$project" "$workflow"
   }

declare -a branches=("main")

for branch in ${branches[@]}; do

   commit="None"
   ejaxcommit="None"
   reactantcommit="None"

   HEADHASH=$(git -C /app/Enzyme rev-parse HEAD)
   UPSTREAMHASH=$(get_upstream_hash Enzyme enzyme-ci.yml)
   if [ "$HEADHASH" != "$UPSTREAMHASH" ] && [ ! -z "$UPSTREAMHASH" ]
   then
      echo -e ${FINISHED}Updating Enzyme, old was $HEADHASH new was $UPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme checkout $branch
      git -C /app/Enzyme reset --hard $UPSTREAMHASH
      commit=$(git -C /app/Enzyme rev-parse --short=7 HEAD)
   else
      commit=$(git -C /app/Enzyme rev-parse --short=7 HEAD)
      echo -e ${FINISHED}Current branch is up to date with origin/nightly.${NOCOLOR}
   fi

   JHEADHASH=$(git -C /app/Enzyme-JaX rev-parse HEAD)
   JUPSTREAMHASH=$(get_upstream_hash Enzyme-JaX build.yml)

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] && [ ! -z "$JUPSTREAMHASH" ]
   then
      echo -e ${FINISHED}Updating Enzyme-JaX, old was $JHEADHASH new was $JUPSTREAMHASH ${NOCOLOR}
      git -C /app/Enzyme-JaX checkout $branch
      git -C /app/Enzyme-JaX reset --hard $JUPSTREAMHASH
      ejaxcommit=$(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD)
   else
      ejaxcommit=$(git -C /app/Enzyme-JaX rev-parse --short=7 HEAD)
      echo -e ${FINISHED}Current branch is up to date with origin/nightly.${NOCOLOR}
   fi

   RHEADHASH=$(git -C /app/Reactant rev-parse HEAD)
   RUPSTREAMHASH=$(get_upstream_hash Reactant reactant-bazel-custom.yml)

   if [ "$RHEADHASH" != "$RUPSTREAMHASH" ] && [ ! -z "$RUPSTREAMHASH" ]
   then
      echo -e ${FINISHED}Updating Reactant, old was $RHEADHASH new was $RUPSTREAMHASH ${NOCOLOR}
      git -C /app/Reactant checkout $branch
      git -C /app/Reactant reset --hard $RUPSTREAMHASH
      reactantcommit=$(git -C /app/Reactant rev-parse --short=7 HEAD)
   else
      reactantcommit=$(git -C /app/Reactant rev-parse --short=7 HEAD)
      echo -e ${FINISHED}Current branch is up to date with origin/nightly.${NOCOLOR}
   fi

   if [ "$JHEADHASH" != "$JUPSTREAMHASH" ] || [ "$RHEADHASH" != "$RUPSTREAMHASH" ]  || [ "$HEADHASH" != "$UPSTREAMHASH" ] 
   then
      python3 /app/scripts/update-versions.py /app/data /app/template_files/etc/config /app/compiler-explorer/etc/config $commit $ejaxcommit $reactantcommit
      source /app/update-explorer.sh
   fi
done
