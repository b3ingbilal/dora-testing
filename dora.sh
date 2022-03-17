#!/bin/bash

if [[ $# -eq 1 ]]; then
    new_release_tag=$1
    new_release_tag_base=$(echo ${new_release_tag} | head -n1 | cut -d "-" -f1)
    user_name=$(git config -l | grep user.name | sed 's/^..........\(.*\).*/\1/')
    token=$(gcloud secrets versions access 1 --secret="DORA_EVENT_CALLER")
    
    old_release_tag=$(curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/git/refs/tags | \
        python3 -c "import sys, json; output=json.load(sys.stdin); a=[obj['url'][63:] for obj in output  if '${new_release_tag_base}' in obj['url']  and '${new_release_tag}' not in obj['url']]; a.sort(); print(a[len(a)-1])")
    new_release_label=$(echo ${new_release_tag} | head -n2 | cut -d "-" -f2)


    echo "new_release_label = ${new_release_label}"
    echo "new_release_tag = ${new_release_tag}"
    echo "old_release_tag = ${old_release_tag}"


    sha1=$(curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/git/refs/tags/${new_release_tag} | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['object']['sha'])")

    sha2=$(curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/git/refs/tags/${old_release_tag} | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['object']['sha'])")


    shas1=$(curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/commits?sha=${sha1} | \
        python3 -c "import sys, json; output=json.load(sys.stdin); a=[obj['sha'] for obj in output]; print('\n'.join(a))")

    shas2=$(curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/commits?sha=${sha2} | \
        python3 -c "import sys, json; output=json.load(sys.stdin); a=[obj['sha'] for obj in output]; print('\n'.join(a))")


    echo "${shas1}" | sort > one.txt
    echo "${shas2}" | sort > two.txt


    shas=$(comm -23 one.txt two.txt)

    echo "Final shas: ${shas}"

    sha_list=""
    for var in ${shas}
    do
        sha_list+="${var}, "
    done

    #Still need to add check if label is not rb
    gcloud functions call "dora-insights" --data '{"changes": "'"$sha_list"'", "script-call" : "true", "release-tag": "'"$new_release_tag"'", "label": "'"$new_release_label"'"}'
else
    echo "Invalid Command line arguments."
    echo "Usage: ./dora_event_caller.sh <RELEASE_VERSION> <USER_NAME> <ACCESS_TOKEN>"
fi