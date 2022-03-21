#!/bin/bash

function get_old_release_tag {
   user_name=$1
   token=$2
   new_release_tag_base=$3
   new_release_tag=$4
   curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/git/refs/tags | \
        python3 -c "import sys, json; output=json.load(sys.stdin); a=[obj['url'][63:] for obj in output if '${new_release_tag_base}' in obj['url'] and '${new_release_tag}' not in obj['url']]; a.sort(); print(a[len(a)-1])"
}

function get_release_sha {
   user_name=$1
   token=$2
   release_tag=$3
   curl -u ${user_name}:${token} https://api.github.com/repos/educative/educative/git/refs/tags/${release_tag} | \
        python3 -c "import sys, json; print(json.load(sys.stdin)['object']['sha'])"
}




