# Oracle Enterprise Manager monitored by O&M Services

This solution helps in monitoring all the components of the Enterprise Manager using Observability and Management Services.
To enable the monitoring we can follow the below steps,

### Management Agent

Management Agent is a service that provides communication and data collection between OCI and any other targets. The Management Agent will get installed on the OEM server(s) and the EM Repository DB server(s). It is used to collect OMS, EM Agent, WebLogic, Database and system logs and application, DB and system metrics. If desired, it can be used to run SQL queries against the EM Repo DB for custom metric extensions or SQL based log sources. 

To setup Managent Agents ...

(some ideas for content to cover: pointer to official docs with installation details. If OEM or EM repo DB is running in an OCI VM, we have to mention that the Mgmt Agent can be enabled as a plugin of the Oracle Cloud Agent (OCA). How to enable plugins for O&M services from OCI Mgmt Agent page.)

<img width="1427" alt="image" src="https://github.com/user-attachments/assets/4fd884ba-3003-478b-b46a-12eeddfe2b10">

![image](https://github.com/user-attachments/assets/ece7975e-a522-481a-b0cd-ceee968dd99b)

<img width="1424" alt="image" src="https://github.com/user-attachments/assets/d96bec9a-43f4-4b96-9e42-68ed8c01f2b0">




### Application Performance Monitoring

APM service allows to monitor the performance and availability of the OEM application.It instruments the application and collects the traces and spans which give more insights into OEM.
To setup APM , we need to install APM Java agent.It can be downloaded from below,
Observability & Management --> Application Performance Monitoring --> Administration --> Download APM agents --> Select JAVA agent
<img width="1314" alt="image" src="https://github.com/user-attachments/assets/77e2b7bc-876f-4c11-8096-8afbdc48c08a">

Once downloaded , follow the steps to provision the APM agent.
* Connect to the host where the OMS server is installed and copy the APM Java Agent software file that you downloaded to any preferred location.
* Ensure to login as the same user as the OMS server and that the OMS server user has read and write permissions to the directory to which the APM Java agent is downloaded or copied.
* Review the following mandatory arguments that must be specified to provision an APM Java Agent.
-service-name: The name of the service being monitored. This argument enables you to filter by service and view traces in the Trace Explorer user interface.
-destination: The destination directory in which the APM Java Agent will be provisioned.We can use the value $OMS_HOME 
-private-data-key: The agent installation key used by APM Java agents (private dataKey), which is generated when the APM domain is created.
-data-upload-endpoint: The dataUploadEndpoint URL that is generated when the APM domain is created.
* To view the help information for the provision-agent argument, run the following:        
  java -jar ./apm-java-agent-installer-<version>.jar provision-agent -help
* Provision the agent by specifying the mandatory arguments described in the previous step and running the following java command:
  Example:
  java -jar ./apm-java-agent-installer-1.1.jar provision-agent -service-name=apm_service -destination=$OMS_HOME -private-data-key=IMWJ5UN2C6YOLQSUZ5Q7IGN3QACF4AZD -data-upload-endpoint=https://dataUploadEndpoint.com
* On running the java command, if the APM Java agent is provisioned successfully


### Logging Analytics




### Stack monitoring
(I would go first with Stack Monitoring since it provides an additional value which OEM cannot deliver: Anomaly Detection in metrics and alarms based on it, where OEM needs given fixed threshold values.)


### Database Management
(we may name these 'optional' services, since it will be hard to show something which OEM does not provide)


### Ops Insights
(same here, the value for the EM Repo DB is not there yet, we might describe probably using a Cloud Bridge to forward target data into Ops Insights)
