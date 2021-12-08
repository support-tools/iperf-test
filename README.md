# iperf-test
---
## About
By default this tool test bandwidth between two pods on the same node.
and if a second node is passed to the script the bandwith between the two nodes is also tested

Find some nodes

```
oc get nodes                                                                    
NAME         STATUS   ROLES    AGE   VERSION
master0-49   Ready    master   15d   v1.22.1+d8c4430
master1-49   Ready    master   15d   v1.22.1+d8c4430
master2-49   Ready    master   15d   v1.22.1+d8c4430
worker0-49   Ready    worker   15d   v1.22.1+d8c4430
worker1-49   Ready    worker   15d   v1.22.1+d8c4430
worker2-49   Ready    worker   15d   v1.22.1+d8c4430
```
---

## Usage:

```
./run 4|6 NODE1 [NODE2]
```
---

## example:
Runs on a single node. 

using ipv4 addresses
```
./run 4 worker0-49
```

Using ipv6 addresses
```
./run 6 worker0-49
```

Runs on two nodes, then between the nodes
```
./run 4 worker0-49 worker1-49
```


