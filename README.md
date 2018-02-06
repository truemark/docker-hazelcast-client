# docker-hazelcast-client

This project is a simple overlay on top of the official Hazelcat docker image located at
https://hub.docker.com/r/hazelcast/hazelcast/ and https://github.com/hazelcast/hazelcast-docker


Examples:

~~~~
docker run -ti -e GROUP_NAME=<name> -e GROUP_PASSWD=<password> -e MEMBER_ADDRESS=<address:port> truemark/docker-hazelcast-client:latest
~~~~

~~~~
docker run -ti -e GROUP_NAME=<name> -e GROUP_PASSWD=<password> -e MEMBER_ADDRESS=<address:port> truemark/docker-hazelcast-client:latest /bin/bash
~~~~

