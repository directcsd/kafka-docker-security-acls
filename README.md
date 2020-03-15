# kafka-docker-security-acls

The objective of this repo is to allow the testing of authorization of topics and the behavior of client
when being authorized / not authorized by the broker.

## Environment startup

The environment deploys 1 Zookeeper instance and 1 Kafka instance, to activate it, it is needed to have Docker
installed (it uses docker-compose).

To start the environment run:

`docker-compose up -d`

To stop the environment use:

`docker-compose down`

### Configuration details

The Kafka broker is configured with SASL/Plaintext authentication and Zookeeper is configured with SASL/Digest
authentication (Zookeeper don't support SASL/Plaintext). The brokers are adding ACLs to the Zookeeper nodes when
they write and the broker will not allow access to topics without ACLs set (`allow.everyone.if.no.acl.found=false`).

This is a strict setting and the broker has 3 users configured

* `admin` - configured as super user
* `consumer`
* `producer`

The script `create_topic.sh` creates the topic `first_topic` and set the ACLs for user `producer` to write and the
user `consumer` to read from this topic (in the case of the consumer, from any consumer group id).

The JAAS files used to configure the usernames and passwords, as well as the client credentials used by the broker
are in the directory `security` of the repo (and they are mounted as `/opt/security` in broker and in zookeeper).

The broker will expose the port 9093 as a SASL authenticated port in the localhost.

The `docker-compose.yml` is using Confluent docker images 5.4.1, although older version should work fine (the initial
version of this repo was tested in 5.3.0)

## How to use the environment for testing

### Installing the clients

It is required to have Kafka tools installed to be able to use this environment. The best way to do it in a Mac is:

`brew install kafka`

Another very handy tool is kafkacat that could be conveniently installed by doing:

`brew install kafkacat`

### Producing to the broker

Once the tools are installed, it is possible to produce to the topic by running:

`kafka-console-producer --broker-list localhost:9093 --producer.config client-properties/producer.properties --topic first_topic`

> The command above assumes that the topic first_topic was created and the ACLs for producing were assigned.
> To perform this action just run the script `create_topic.sh`

### Consuming from the broker

Similarly to consumer from the topic:

`kafka-console-consumer.sh --bootstrap-server localhost:9093 --consumer.config client-properties/consumer.properties --group test-consumer-group --topic first_topic`

> The same comment from the previous section applies here regarding the ACLs

## Test results

### Kafka Console CLI

#### Producer tests

##### No authentication configured

| Step | Action |
|---|---|
| Pre-requisites | * None |
| Test Steps | * Execute the producer<br>`kafka-console-producer.sh --broker-list localhost:9093 --topic first_topic`<br>(note that the `producer.config` is not added to cause the authentication mismatch) |
| Expected Results | * Client tries continuously to connect to the broker |

##### No authorization for the topic

| Step | Action |
|---|---|
| Pre-requisites | * Remove the producer ACL |
| Test Steps | * Execute the producer with the proper authentication<br>`kafka-console-producer.sh --broker-list localhost:9093 --producer.config client-properties/producer.properties --topic first_topic` |
| Expected Results | * Client will fail due to authorization error |

##### Remove the authorization from a running producer

| Step | Action |
|---|---|
| Pre-requisites | * Make sure the producer ACL is in place |
| Test Steps | * Execute the producer with the proper authentication<br>`kafka-console-producer.sh --broker-list localhost:9093 --producer.config client-properties/producer.properties --topic first_topic`<br> * Remove the producer ACL |
| Expected Results | * Client start producing normally<br>* Client will generate one error message for each producing attempt after the ACL removal |

#### Consumer tests

##### No authentication configured

| Step | Action |
|---|---|
| Pre-requisites | * None |
| Test Steps | * Execute the consumer<br>`kafka-console-consumer.sh --bootstrap-server localhost:9093 --group test-consumer-group --topic first_topic`<br>(note that the `consumer.config` is not added to cause the authentication mismatch) |
| Expected Results | * Client tries continuously to connect to the broker |

##### No authorization for the topic

| Step | Action |
|---|---|
| Pre-requisites | * Remove the consumer ACL |
| Test Steps | * Execute the consumer with the proper authentication<br>`kafka-console-consumer.sh --bootstrap-server localhost:9093 --consumer.config client-properties/consumer.properties --group test-consumer-group --topic first_topic` |
| Expected Results | * Client will fail due to authorization error |

##### Remove the authorization from a running consumer

| Step | Action |
|---|---|
| Pre-requisites | * Make sure the consumer ACL is in place |
| Test Steps | * Execute the consumer with the proper authentication<br>`kafka-console-consumer.sh --bootstrap-server localhost:9093 --consumer.config client-properties/consumer.properties --group test-consumer-group --topic first_topic`<br> * Remove the consumer ACL |
| Expected Results | * Client start consuming normally<br>* Client will generate one error message once the ACL is removed |

##### No authorization for the consumer group

| Step | Action |
|---|---|
| Pre-requisites | * Change the consumer ACL to authorize only a specific consumer group (different from test-consumer-group) |
| Test Steps | * Execute the consumer with the proper authentication<br>`kafka-console-consumer.sh --bootstrap-server localhost:9093 --consumer.config client-properties/consumer.properties --group test-consumer-group --topic first_topic` |
| Expected Results | * Client will fail due to authorization error |



### Kafka Java app

### Spring Boot app