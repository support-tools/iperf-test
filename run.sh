#!/bin/bash
set -euf -o pipefail

#Prerequistes
## OC is logged into cluster
## user can create namespaces.

#This script with run an iperf on each node betweent the client and server pod, then test between the nodes [if two nodes are set]

#Test 1
## node1 -> node1
## node2 -> node2

#Test 2
## node1 -> node2

# The idea is to check the performence of each nodes ovs/packet forwarding performence, and then test between nodes for a real world example also.

## variables ##
# udp / bitrate 10M / bitrate 100M / bitrate 1Gbit
# tcp / bitrate unlimited / inital windows size 1

#TEST SETTTINGS
TESTTIME=10

TEST_CASES=(
""
"-u -b 10M"
"-u -b 100M"
"-u -b 1G"
)


function listnodes
{
    oc get nodes -o jsonpath='{range .items[*].metadata.labels}{.kubernetes\.io/hostname}{"\n"}'
}

function checknodename 
{
    echo checking node \"$1\" is valid
    if [ $(oc get nodes -l kubernetes.io/hostname="$1" -o name | wc -l ) -ne 1 ]
    then
        echo node name \"$1\" invalid below are valid names
        listnodes
        exit 1
    fi
}

if [[ $# -ne 1 ]] && [[ $# -ne 2 ]]
then
 echo "Invalid Arguments"
 echo "Syntax: $0 node1 [node2]"
 exit 1
fi

#SN == single node used to mask commands using "||"" if SN=true the second operand is skipped.
if [ $# -eq 2 ]
then
 SN=false
 echo "Running double node test"
else
 SN=true
 echo "Running single node test"
fi

#TODO: check usage ^
RUNDIR=$(dirname $0)
NAMESPACE=iperftest-$RANDOM

#check nodes
NODEA="$1"
checknodename "$NODEA"
$SN || NODEB="$2"
$SN || checknodename "$NODEB"

#Create Namespace for this test
function cleanup() 
{  
    echo "!! CLEANING UP !!"
    oc delete namespace "$NAMESPACE"
}
trap cleanup EXIT

oc create namespace "$NAMESPACE"

#Deploy daemonsets
oc apply -n "$NAMESPACE" -f "$RUNDIR"/manifest.yaml

#wait for all the pods to be ready
echo "Waiting for all pods to be ready"
sleep 5 #Give DS time to make pods
oc get pods -n "$NAMESPACE" -o wide
echo ""
oc wait pods -n "$NAMESPACE" --all --for=condition=Ready  --timeout=60s

#Pass node and get pod name of client pod
function getclientpod
{
  oc get -n "$NAMESPACE" pod -o name --field-selector=spec.nodeName="$1" -l app=iperf3-client
}

#Pass node and get pod name of server pod
function getserverpod
{
  oc get -n "$NAMESPACE" pod -o name --field-selector=spec.nodeName="$1" -l app=iperf3-server
}

#pass pod/name and get pod ipaddr
function getpodip
{
  oc get -n "$NAMESPACE" "$1" -o jsonpath="{.status.podIP}"
}

#TODO: create folder for test results


#Run iperfs
function runiperf
{
  local NODEA="$1"
  local NODEB="$2"
  echo Running test between "$NODEA" "$NODEB"
  CPOD=$(getclientpod "$NODEA")
  SPOD=$(getserverpod "$NODEB")
  SPOD_IP=$(getpodip "$SPOD")
  CPOD_IP=$(getpodip "$CPOD")  

  #Exec iperf
  
  #TODO: add for-loop with different test cases
  #TODO: output as json info a folder

  for ((i = 0; i < ${#TEST_CASES[@]}; i++))
  do
    echo "TEST:" "${TEST_CASES[$i]}"
    set -x
    oc -n "$NAMESPACE" exec -it "$CPOD" -- iperf3 -c "$SPOD_IP" -t "$TESTTIME" ${TEST_CASES[$i]}
    set +x
  done
 
}


runiperf "$NODEA" "$NODEA"
$SN || runiperf "$NODEB" "$NODEB"

#Internode
$SN || runiperf "$NODEA" "$NODEB"
