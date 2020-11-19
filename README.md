# Hybrid Multi Cloud Task 6

The problem statement that has been catered here is to deploy a WordPress application with database backend using Infrastructure As A Code.

1. For the database, Amazon RDS has been used to deploy a MySQL instance which can be accessible only by WordPress frontend server.

2. The WordPress server has been launched as a deployment-service on the top of Kubernetes using Minikube and connected to the RDS instance. This application is accessible by the workstation (minikube IP). 

3. Whole deployment is being done using terraform using appropriate providers for AWS RDS and Kubernetes respectively. Running the code will result in deployment of the whole architecture and opening of the browser at proper IP and port number.

For further reference to the resources used, visit the official documentation: https://www.terraform.io/docs/index.html
