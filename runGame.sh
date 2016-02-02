#!/bin/sh
# Source function library.
if [ -f /etc/rc.d/init.d/functions ];then
    . /etc/rc.d/init.d/functions
elif [ -f /lib/lsb/init-functions ];then
    . /lib/lsb/init-functions  
    alias success=log_success_msg
    alias failure=log_failure_msg
fi
export JAVA_HOME=/usr/java/default
export JRE_HOME=/usr/java/default/jre
export ORACLE_HOME=/tmp/oracle/solarisstudio12.4/bin
export PATH=$ORACLE_HOME:$PATH
export PATH=$JAVA_HOME/bin:$PATH
# define
s_sid=260000000
s_root=/AEGame/PalaceM3_cn_cn/S${s_sid}
appRoot=${s_root}/WebRoot/WEB-INF
scripts_root=${s_root}/Scripts/
type='game.GameServer'
server_path='com.agileeagle.webgame.'${type}
#GC
gc=-XX:+PrintGCDetails
gcroot=-Xloggc:$appRoot/gclog.gclog
#jmx
jmx="-Dcom.sun.management.jmxremote.port=8005 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=192.168.0.28"
#analyzer
analyzer_root="${appRoot}/analyzer/`date '+%Y/%m/%d'`"
analyzer="collect -d ${analyzer_root} -j on "
#export PALACE_KEY=$1
function check_key()
{
if [ -z $1 ];then
    failure;echo 'Start failed, Need key'
 	exit 1
fi
}
function check_pid()
{
    local pid
    pid=$1
    if [ -z ${pid} ];then
        return 1
    fi
    if [ -d /proc/${pid} ]; then
        return 0
    else
        return 1
    fi

}
tailpids=`ps axuww|grep "$appRoot/${type}.nohup"|grep -v grep|awk '{print $2}'`
if [ ! -z "$tailpids" ] ;then
	echo "kill all tail id $tailpids"
	kill -9 $tailpids
fi

#check_key ${PALACE_KEY}
pids=`ps auxww|grep $appRoot|grep $server_path|grep -v grep|awk '{print $2}'|head -n 1`
#echo "ps auxww|grep ${appRoot}|grep ${server_path}|grep -v grep|awk '{print $2}'|head -n 1"
#echo $pids
if  [ -z $pids ] ;then
	cd ${appRoot}
	mkdir -p ${analyzer_root}
	${analyzer} java -Xms256M -Xmx512M ${gc} ${gcroot} ${jmx} -cp ${appRoot}/classes:lib/* com.agileeagle.webgame.$type > $appRoot/${type}.nohup  2>&1 &
	echo "$type server start success;"
	sleep 2
	for i in {1..20};do
		sleep 1
	        if [ -f $appRoot/${type}.nohup ];then
			tail -f $appRoot/${type}.nohup -n 500&
			exit 0;
         	fi
               
        done
else
    echo "already running $server_path ,pid is $pids, please stop it first.";failure;
	exit 1
fi


