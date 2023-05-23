#!/bin/bash

# abort at error
set -e

# If you think docker images might be corrupt,
# or if the runner server needs to cleaned up.

# house keeping
docker container prune -f
docker image prune -f

# report
docker image ls
docker container ls

# cleanup
docker image ls -q | xargs docker image rm

# final report
docker image ls
docker container ls

#Should have no images except the running docker GHA container 

exit 0
