# Oracle Enterprise Manager monitored by O&M Services

This solution helps in monitoring all the components of the Enterprise Manager using Observability and Management Services.
To enable the monitoring we can follow the below steps,

### Management Agent

Management Agent is a service that provides communication and data collection between OCI and any other targets. The Management Agent will get installed on the OEM server(s) and the EM Repository DB server(s). It is used to collect OMS, EM Agent, WebLogic, Database and system logs and application, DB and system metrics. If desired, it can be used to run SQL queries against the EM Repo DB for custom metric extensions or SQL based log sources. 

To setup Managent Agents ...



### Application Performance Monitoring





### Logging Analytics




### Stack monitoring
(I would go first with Stack Monitoring since it provides an additional value which OEM cannot deliver: Anomaly Detection in metrics and alarms based on it, where OEM needs given threshold values.)


### Database Management
(we may name these 'optional' services, since it will be hard to show something which OEM does not provide)


### Ops Insights
(same here, the value for the EM Repo DB is not there yet, we might describe probably using a Cloud Bridge to forward target data into Ops Insights)
