Boundary Ping Check Plugin
--------------------------

Pings a set of hosts and reports on the response time. The plugin allows multiple hosts to be ping'd and each of those hosts to set their own Poll interval. See video [walkthrough](https://help.boundary.com/hc/articles/201383932).
Note: Currently does not support SmartOS.

## Prerequisites

### Supported OS

|     OS    | Linux | Windows | SmartOS | OS X |
|:----------|:-----:|:-------:|:-------:|:----:|
| Supported |   v   |    v    |    -    |  v   |

#### Boundary Meter Versions V4.0 Or Greater

To get the new meter:

    curl -fsS \
        -d "{\"token\":\"<your API token here>\"}" \
        -H "Content-Type: application/json" \
        "https://meter.boundary.com/setup_meter" > setup_meter.sh
    chmod +x setup_meter.sh
    ./setup_meter.sh

#### Boundary Meter Versions Less Than V4.0

|  Runtime | node.js | Python | Java |
|:---------|:-------:|:------:|:----:|
| Required |    +    |        |      |

- [How to install node.js?](https://help.boundary.com/hc/articles/202360701)

### Plugin Setup
None

#### Plugin Configuration Fields

|Field Name     |Description                                                                       |
|:--------------|:---------------------------------------------------------------------------------|
|Source         |The source to display in the legend for the host. Ex. google                      |
|Host           |The Hostname or IP Address to ping.  For example, www.google.com or 173.194.33.112|
|Poll Time (sec)|The Poll Interval to send a ping to the host in seconds. Ex. 5                    |

### Metrics Collected

|Metric Name       |Description                            |
|:-----------------|:--------------------------------------|
|Ping Response Time|The response time from the ping command|
