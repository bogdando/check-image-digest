#!/bin/bash

set -eEuo pipefail

for bin in skopeo jq; do
  if [[ ! $(which ${bin}) ]]; then
    echo "required binary ${bin} does not exist on machine, exiting"
    exit 1
  fi
done

if [[ -z "${DIGEST}" ]]; then
  echo "Must provide DIGEST in environment" 1>&2
  exit 1
fi
want_digest=${DIGEST}

ERR_NO_MATCH=2
REGISTRY_AUTH_FILE=$HOME/auth.json

DIGEST_LOOKUP_DEPTH=${DIGEST_LOOKUP_DEPTH:-15}
IMAGE_NAME=${IMAGE_NAME:-'ubuntu'}
echo "Using image name '${IMAGE_NAME}' (modify IMAGE_NAME) to change"
echo "Looking for tags matching digest '${DIGEST}' (modify DIGEST) to change"
echo "Looking for no deeper than '${DIGEST_LOOKUP_DEPTH}' tags (modify DIGEST_LOOKUP_DEPTH) to change"

parsed_images=$(skopeo list-tags docker://$IMAGE_NAME | jq -r '"docker://\(.Repository):\(.Tags[])"' | tail -$DIGEST_LOOKUP_DEPTH)

matching_images=()
IFS=$'\n'
for parsed_image in ${parsed_images}; do
  got_digest=$(skopeo inspect "${parsed_image}" --no-tags --format '{{.Digest}}')
  if [[ "${got_digest}" == "${want_digest}" ]]; then
    matching_images+=( "${parsed_image}" )
    continue
  fi
done

if [[ "${#matching_images[@]}" -eq 0 ]]; then
  echo ' Did not find matches, change any of the flags and try again'
  exit "${ERR_NO_MATCH}"
fi

echo "Found '${#matching_images[@]}' matches"
echo ${matching_images[@]}

