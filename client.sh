#!/bin/bash
PID=0
sigterm_handler() {
  echo "Hazelcast Term Handler received shutdown signal. Signaling hazelcast instance on PID: ${PID}"
  if [ ${PID} -ne 0 ]; then
    kill "${PID}"
  fi
}

PRG="$0"
PRGDIR=`dirname "$PRG"`
HAZELCAST_HOME=`cd "$PRGDIR/.." >/dev/null; pwd`/hazelcast
PID_FILE=$HAZELCAST_HOME/hazelcast_instance.pid

if [ "x$MIN_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [ "x$MAX_HEAP_SIZE" != "x" ]; then
	JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

# if we receive SIGTERM (from docker stop) or SIGINT (ctrl+c if not running as daemon)
# trap the signal and delegate to sigterm_handler function, which will notify hazelcast instance process
trap sigterm_handler SIGTERM SIGINT

export CLASSPATH=$HAZELCAST_HOME/hazelcast-all-$HZ_VERSION.jar:$HAZELCAST_HOME/cache-api-1.0.0.jar:$CLASSPATH/*

echo "########################################"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# CLASSPATH=$CLASSPATH"
echo "# starting now...."
echo "########################################"

if [ -z ${GROUP_NAME} ]; then
	echo "GROUP_NAME is required"
	exit 1
fi
if [ -z ${GROUP_PASSWD} ]; then
	echo "GROUP_PASSWD is required"
	exit 1
fi
if [ -z ${MEMBER_ADDRESS} ]; then
	echo "MEMBER_ADDRESS is required"
	exit 1
fi

cat > $HAZELCAST_HOME/hazelcast-client.xml <<EOF
<hazelcast-client xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  xsi:schemaLocation="http://www.hazelcast.com/schema/client-config
                               http://www.hazelcast.com/schema/client-config/hazelcast-client-config-3.9.xsd"
                  xmlns="http://www.hazelcast.com/schema/client-config">
    <group>
        <name>${GROUP_NAME}</name>
        <password>${GROUP_PASSWD}</password>
    </group>
    <network>
        <cluster-members>
            <address>${MEMBER_ADDRESS}</address>
        </cluster-members>
    </network>
</hazelcast-client>
EOF

java -server $JAVA_OPTS com.hazelcast.client.console.ClientConsoleApp
PID="$!"
echo "Process id ${PID} for hazelcast instance is written to location: " $PID_FILE
echo ${PID} > ${PID_FILE}

# wait on hazelcast instance process
wait ${PID}
# if a signal came up, remove previous traps on signals and wait again (noop if process stopped already)
trap - SIGTERM SIGINT
wait ${PID}
