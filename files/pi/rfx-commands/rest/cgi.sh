
# Any post data ?

[ "$REQUEST_METHOD" = "POST" ] && [ ! -z "$CONTENT_LENGTH" ] && read -r -n $CONTENT_LENGTH POST_STRING

#-------------------------------------------------------------------------------
#
#       Function get_post_string
#
#-------------------------------------------------------------------------------

get_post_string () {
    local p="${POST_STRING}"
    while IFS="=" read -r key value ; do
        eval "$1+=([$key]=${value})"
    done < <(echo "${p}" | jq -r "to_entries|map(\"\(.key)=\(.value)\")|.[]")
}

#-------------------------------------------------------------------------------
#
#       Function get_query_string
#
#-------------------------------------------------------------------------------

get_query_string() {
  local q="${QUERY_STRING}"
  local re1='^(\w+=\w+)&?'
  local re2='^(\w+)=(\w+)$'
  while [[ $q =~ $re1 ]]; do
    q=${q##*${BASH_REMATCH[0]}}
    [[ ${BASH_REMATCH[1]} =~ $re2 ]] && eval "$1+=([${BASH_REMATCH[1]}]=${BASH_REMATCH[2]})"
  done
}
