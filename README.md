# Finnhub data streaming pipeline for real-time Bitcoin trades analysis
A real-time dashboard to visualize Bitcoin trades as they happen, including key metrics like trades count, the count and average trade price over 1 minute time window, trade volume over time and much more.
The main goal was to leaverage the architecture of streaming data pipelines using well suited tools and technologies for reliability and low latency.  

## Repository layout
The repository is organized into two branches:

1. ***main*** : Code for cloud deployment.

2. ***localDeployment*** : Code for local deployment using docker.

## Architecture overview
![Arch image here](arch.drawio.png)

- **Data ingestion** : Data is collected from the Finnhub websocket, by a containerized Python script, which is also a Kafka producer, which serializes data into an Avro format and then push it into a Kafka topic called 'Market'.

- **Event streaming** : A Kafka broker managed by zookeeper, which recieves data from the producer and stores it for later consumption.
Kafdrop is also used to monitor the Kafka broker.

- **Stream processing** : A spark structured streaming job is implmented using PySpark, which consumes and deserializes Avro data consumed from the 'Market' topic, and then process it. The job is running in a cluster of 3 nodes, one being the master, and the rest are worker nodes.
The streaming job performs two continous queries:
    - *Trades query* : Deserializes and transforms data into a suitable form, and then loads it into a cassandra table ('Trades' table). 
    - *Minute trades query* : Groups data into windows of 1 minute to calculate aggregate summaries (count and average), and then loads processed windows into a cassandra table ('Minute trades' table). 

- **Data storage** : Processed data is stored into cassandra, within the 'Market' keyspace, containing two tables, 'Trades' and 'Minute trades'.

- **Data visualization** : A grafana dashboard is used to query the data from the cassandra database, in regular interavals of 1s.

## Dashboard
![Dashboard git here](arch.drawio.png)

The Dashboard displays the following pieces of information:

    - A real-time line chart of Bitcoin trade price over time.
    - A real-time bar chart of Bitcoin trade volume over time.
    - A real-time metric for trades count.
    - The Average trade price over the past minute.
    - The count of trades happened in the past minute.
    - A table recording entries for past minutes.

## Deployment

The project is deployed on Google Cloud Platform (GCP) in a highly available, on-premises Kubernetes cluster. The cloud infrastructure is provisioned using Infrastructure as Code (IaC) principles with Terraform for resource creation and Ansible for configuration management.

### Cloud Architecture

- **Terraform** is used to create and manage GCP resources, primarily Virtual Machines (VMs).
- The architecture consists of:
  - One or more Kubernetes master nodes
  - One or more Kubernetes worker nodes
  - A "gateway-server" VM

#### Gateway Server
- The only VM with an external IP (randomly assigned for cost efficiency)
- Runs HAProxy as a reverse proxy and load balancer to:
  - Distribute traffic among Kubernetes master nodes
  - Expose necessary applications externally (Spark UI, Kafdrop UI, Grafana)
- Serves as the entry point for Ansible configuration

### Configuration Management

- **Ansible** playbooks and configurations are copied to the gateway server.
- Cluster configuration is executed from within the network using private IPs for enhanced security.
- Key Ansible tasks:
  1. Configure VMs to provision a Kubernetes cluster using kubeadm
  2. Deploy applications to the Kubernetes cluster
  3. Configure HAProxy for external access ([haproxy.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/scripts/haproxy.sh))

### Kubernetes Architecture

The project architecture within Kubernetes is organized as follows:

1. **Ingestion Namespace**
   - Producer deployment

2. **Kafka Namespace**
   - [Strimzi Kafka Operator](https://github.com/strimzi/strimzi-kafka-operator)
   - Kafka cluster deployment
   - Market topic creation
   - [Kafdrop](https://github.com/obsidiandynamics/kafdrop) deployment for topic monitoring

3. **Spark Namespace**
   - [Kubeflow Spark Operator](https://github.com/kubeflow/spark-operator)
   - Spark Streaming job (deployed in 'spark-apps' namespace)

4. **Cassandra Deployment**
   - StatefulSet with local persistent volume

5. **Monitoring Namespace**
   - [Kube-Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
     - Prometheus for metric collection
     - Grafana for metric visualization
   - Pre-configured Grafana dashboards for cluster monitoring
   - Automated Cassandra datasource configuration and Bitcoin dashboard setup

### External Access

- Grafana, Kafdrop UI, and Spark UI are exposed using Kubernetes NodePort services.
- HAProxy on the gateway server acts as a reverse proxy to expose these services externally.

### Environment Configuration

The number of master and worker nodes, along with other configurations such as region, zone, machine type, and OS image, are defined in the [env.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/scripts/env.sh) script.

### Note on Production Deployment

While NodePort services are used in this setup for simplicity, they are generally not recommended for production environments. In a managed Kubernetes service like Google Kubernetes Engine (GKE), it's preferable to use LoadBalancer services or Ingress resources for external access.

## How to Run

You can deploy the project on Google Cloud Platform (GCP) by following these steps:

1. Create a new project in GCP.

2. Update the necessary configurations in the [env.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/scripts/env.sh) script:
   - Project ID
   - Zone
   - Region
   - Number of worker VMs
   - Number of master VMs
   - Other relevant settings

3. Generate a service account with the required permissions in the Google Cloud Console.

4. Download the service account JSON file and rename it to "bigdata-project-sa.json".

5. Move the JSON file to the "infra" directory, placing it alongside the [deploy.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/deploy.sh) and [destroy.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/destroy.sh) scripts.

6. Ensure the bash scripts have execute permissions.

7. Deploy the project by running the [deploy.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/deploy.sh) script.

8. After deployment, access the following UIs using the gateway server's external IP (found in the VM section of Google Cloud Console):
   - Grafana UI: Port 8080
     - Default credentials: admin:prom-operator (as defined in [Kube-Prometheus Stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack))
   - Kafdrop UI: Port 8082
   - Spark UI: Port 8081

9. To tear down the entire provisioned infrastructure, use the [destroy.sh](https://gitlab.com/pipelineplumbers/BigDataProject/-/blob/8bc5f434e86d3a8c476844baf37abb5dc007d7e0/infra/destroy.sh) script.