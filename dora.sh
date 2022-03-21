#!/bin/bash

if [[ $# -eq 1 ]]; then
    new_release_tag=$1
    new_release_tag_base=$(echo ${new_release_tag} | head -n1 | cut -d "-" -f1)
    user_name=$(git config -l | grep user.name | sed 's/^..........\(.*\).*/\1/')
    token=$(gcloud secrets versions access 1 --secret="DORA_EVENT_CALLER")
    
    source $(dirname "$0")/dora_use.sh
    old_release_tag=$(get_old_release_tag $user_name $token $new_release_tag_base $new_release_tag)
    new_release_label=$(echo ${new_release_tag} | head -n2 | cut -d "-" -f2)

    echo "new_release_label = ${new_release_label}"
    echo "new_release_tag = ${new_release_tag}"
    echo "old_release_tag = ${old_release_tag}"

    new_release_sha=$(get_release_sha $user_name $token $new_release_tag)
    old_release_sha=$(get_release_sha $user_name $token $old_release_tag)
    new_release_commits=$(get_release_commits $user_name $token $new_release_sha)
    old_release_commits=$(get_release_commits $user_name $token $old_release_sha)

    echo "${new_release_commits}" | sort > one.txt
    echo "${old_release_commits}" | sort > two.txt

    commit_diff=$(comm -23 one.txt two.txt)

    echo "Final shas: ${commit_diff}"

    commit_list=""
    for var in ${commit_diff}
    do
        commit_list+="${var}, "
    done

    rm -rf one.txt two.txt

    gcloud functions call "dora-insights" --data '{"changes": "'"$commit_list"'", "script-call" : "true", "release-tag": "'"$new_release_tag"'", "label": "'"$new_release_label"'"}'
else
    echo "Invalid Command line arguments."
    echo "Usage: ./dora_event_caller.sh <RELEASE_VERSION> <USER_NAME> <ACCESS_TOKEN>"
fi