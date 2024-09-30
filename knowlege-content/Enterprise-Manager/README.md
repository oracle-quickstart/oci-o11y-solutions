# Oracle Enterprise Manager monitored by O&M Services

This solution helps in monitoring all the components of the Enterprise Manager using Observability and Management Services.
To enable the monitoring we can follow the below steps,

### Management Agent

Management Agent is a service that provides communication and data collection between OCI and any other targets. The Management Agent will get installed on the OEM server(s) and the EM Repository DB server(s). It is used to collect OMS, EM Agent, WebLogic, Database and system logs and application, DB and system metrics. If desired, it can be used to run SQL queries against the EM Repo DB for custom metric extensions or SQL based log sources. 

To setup Management Agent we need to follow this [document](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#OCIAG-GUID-92777625-6549-4D8E-A27D-C1C5583071CA)


If the OMS server and EM repository database are running on OCI VM, we can just enable the Management Agent plugin available as part of Oracle Cloud Agent (OCA)
![image](https://github.com/user-attachments/assets/ece7975e-a522-481a-b0cd-ceee968dd99b)

Once the agent is successfully installed , we need to enable the plugins for utilizing the O&M services. Steps for this is available [here](https://docs.oracle.com/en-us/iaas/management-agents/doc/management-agents-administration-tasks.html#OCIAG-GUID-4D3F3DC5-4ACF-48C6-B624-F74700D0C73F)

<img width="1424" alt="image" src="https://github.com/user-attachments/assets/d96bec9a-43f4-4b96-9e42-68ed8c01f2b0">




### Application Performance Monitoring

APM service allows to monitor the performance and availability of the OEM application.It instruments the application and collects the traces and spans which give more insights into OEM.
To setup APM, we need to install APM Java agent.It can be downloaded from below,
Observability & Management --> Application Performance Monitoring --> Administration --> Download APM agents --> Select JAVA agent
<img width="1314" alt="image" src="https://github.com/user-attachments/assets/77e2b7bc-876f-4c11-8096-8afbdc48c08a">

Once downloaded, follow the steps to provision the APM agent.
* Connect to the host where the OMS server is installed and copy the APM Java Agent software file that you downloaded to any preferred location.
* Ensure to login as the same user as the OMS server and that the OMS server user has read and write permissions to the directory to which the APM Java agent is downloaded or copied.
* Ensure that WebLogic variable DOMAIN_HOME is set, example "DOMAIN_HOME=/u01/app/gc_inst/user_projects/domains/GCDomain". 
* Review the following mandatory arguments that must be specified to provision an APM Java Agent.
    * -service-name: The name of the service being monitored. This argument enables you to filter by service and view traces in the Trace Explorer user interface.
    * -destination: The destination directory in which the APM Java Agent will be provisioned. We will use the value of WebLogic $DOMAIN_HOME for this.
    * -private-data-key: The agent installation key used by APM Java agents (private dataKey), which is generated when the APM domain is created.
    * -data-upload-endpoint: The dataUploadEndpoint URL that is generated when the APM domain is created.
* To view the help information for the provision-agent argument, run the following:
    * java -jar ./apm-java-agent-installer-\<version\>.jar provision-agent -help
* Provision the agent by specifying the mandatory arguments described in the previous step and running the following java command:
    * Example:
      java -jar ./apm-java-agent-installer-1.1.jar provision-agent -service-name=apm_service -destination=$DOMAIN_HOME -private-data-key=IMWJ5UN2C6YOLQSUZ5Q7IGN3QACF4AZD -data-upload-endpoint=https://dataUploadEndpoint.com
* On running the java command, if the APM Java agent is provisioned successfully.

Next step is to modify the WebLogic startup command to include the APM Agent. For this, edit file $DOMAIN_HOME/bin/startWebLogic.sh, locate the line
<pre>. ${DOMAIN_HOME}/bin/setDomainEnv.sh $*</pre>
and add this line after it:
<pre>JAVA_OPTIONS="${JAVA_OPTIONS} -javaagent:$DOMAIN_HOME/oracle-apm-agent/bootstrap/ApmAgent.jar"</pre>

Once the APM agent is successfully installed and OEM got fully restarted (including the WebLogic AdminServer), we can start seeing the traces and spans from the application.
<img width="1385" alt="image" src="https://github.com/user-attachments/assets/c4357c24-d71d-4abe-9604-1322708eb5be">

We can also instrument the Real User monitoring using the Browser agent which helps us understand how the user is experiencing the EM application.We can install the RUM monitoring using the steps below,
* Open the AgentConfig.properties file from the location $DOMAIN_HOME/oracle-apm-agent/
* Uncomment the below parameters, update their values and save the file.
<pre>
com.oracle.apm.agent.rum.enable.injection=true
com.oracle.apm.agent.public.data.key="Public_Data_Key"
com.oracle.apm.agent.rum.service.name="EM_APM_Browser"
</pre>
   * The value of the Public_Data_Key can be obtained from the APM Domain details page.

<img width="1363" alt="image" src="https://github.com/user-attachments/assets/fd202d88-ce29-4099-9e8e-5d9224acadda">

We can also enable Synthetic Monitoring. That lets the user to monitor the EM application and detect potential availability and performance issues before the end user experiences it. It enables proactive monitoring that helps developers and operators prevent issues before users are impacted.
Follow the steps from the document to setup [Synthetic monitoring](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/set-synthetic-monitoring.html).
Based on the OMS environment we can select the type of vantage point needed to setup the monitor.
If its an on-prem OMS server we can use the [On-premise vantage point](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/use-onpremise-vantage-points.html#APMGN-GUID-BA93F27B-E0BB-4891-885D-FEB2FDB00041) .
If its behind a firewall and not exposed to the outside network we can use [Dedicated vantage point](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/use-dedicated-vantage-points.html#APMGN-GUID-B2BD78B1-ACFD-4D6B-8397-C8DBBD744603) .
Once the monitors are setup it collects details such as HAR file and network data which should be useful to understand the customer experience with application.

<img width="1368" alt="image" src="https://github.com/user-attachments/assets/5303a82d-a7e8-48b0-a10b-07f0ecb47500">


### Logging Analytics
Logging Analytics service helps to analyse the logs from EM application, EM agents, EM repository DB and system logs to give insights into the application and infrastructure health. This can be used for normal day to day monitoring or in case of issues for root cause analysis. 

To get started with Logging Analytics, follow [these steps](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/quick-start.html).

After enabling Logging Analytics service we will create now entities for all components of the EM environment. 

* define entity types oem_oms and oem_agent

For the EM OMS and EM Agent components we will create upfront two new entity types, "oem_oms" and "oem_agent", using the OCI CLI e.g. from a Cloud Shell:
<pre>
   Getting the namespace used by a tenant (required by the further coomands):
   $ oci os ns get
   {
     "data": "\<NameSpace\>"
   }
        
   Creating custom entity type "oem_oms":
   oci log-analytics entity-type create --name oem_oms --category Application --namespace-name <NameSpace>

   Creating custom entity type "oem_agent":
   oci log-analytics entity-type create --name oem_agent --category Application --namespace-name <NameSpace>
</pre>

We can follow the steps below for the setup,

* define entity types oem_oms and oem_agent

* create entities
  
* create entity associations
  <pre>
     oci log-analytics entity add-associations --association-entities '["'$Agent_OMS'"]' --namespace-name $NS --entity-id $OEM_ID
     oci log-analytics entity add-associations --association-entities '["'$Agent_REPO'"]' --namespace-name $NS --entity-id $OEM_ID
     oci log-analytics entity add-associations --association-entities '["'$Domain_ID'"]' --namespace-name $NS --entity-id $OEM_ID
     oci log-analytics entity add-associations --association-entities '["'$Admin_ID'"]' --namespace-name $NS --entity-id $Domain_ID
     oci log-analytics entity add-associations --association-entities '["'$OHS_ID'"]' --namespace-name $NS --entity-id $Domain_ID
     oci log-analytics entity add-associations --association-entities '["'$OMS1_ID'"]' --namespace-name $NS --entity-id $Domain_ID
     oci log-analytics entity add-associations --association-entities '["'$OEM_Server'"]' --namespace-name $NS --entity-id $OMS1_ID
     oci log-analytics entity add-associations --association-entities '["'$OEM_Server'"]' --namespace-name $NS --entity-id $OHS_ID
     oci log-analytics entity add-associations --association-entities '["'$OEM_Server'"]' --namespace-name $NS --entity-id $Admin_ID
     oci log-analytics entity add-associations --association-entities '["'$DB_ID'"]' --namespace-name $NS --entity-id $OEM_ID
     oci log-analytics entity add-associations --association-entities '["'$LSNR_ID'"]' --namespace-name $NS --entity-id $DB_ID
     oci log-analytics entity add-associations --association-entities '["'$EMREPO_Server'"]' --namespace-name $NS --entity-id $DB_ID
     oci log-analytics entity add-associations --association-entities '["'$EMREPO_Server'"]' --namespace-name $NS --entity-id $LSNR_ID
     oci log-analytics entity add-associations --association-entities '["'$EMREPO_Server'"]' --namespace-name $NS --entity-id $Agent_REPO
     oci log-analytics entity add-associations --association-entities '["'$OEM_Server'"]' --namespace-name $NS --entity-id $Agent_OMS
  </pre>
* give mgmt_agent the needed permissions to access logs from system, OMS and DB/Listener
  
* Need to associate the log sources to entities using [this](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/manage-source-entity-association.html#LOGAN-GUID-C4604513-1D68-4F19-9352-8DE60C5788A5)
* We will be able to corelate and view topology-wise log collection for the EM application.
  <img width="993" alt="image" src="https://github.com/user-attachments/assets/68936f56-2f42-4ab5-acfa-399c7d9971ac">

  
  

### Stack monitoring
Stack Monitoring lets you proactively monitor the EM application and its underlying application stack, including OMS servers and databases. Once discovered, it automatically collects status, load, response, error, and utilization metrics for all application components.
With anomoly detection built with the metrics collected it helps in understanding the environment abnormalities.
This [document](https://docs.oracle.com/en-us/iaas/stack-monitoring/doc/promotion-and-discovery.html#STMON-GUID-DA187C14-8317-41E8-97B1-3AC8DC660458) has the details on the resouce discovery for the components of the EM.
To discover any resource in Stack monitoring , go to Resource management --> Discover resources
<img width="1384" alt="image" src="https://github.com/user-attachments/assets/c8a1fb3c-9dbf-4200-8514-5a1b49db260d">
Click on Discover New Resource and select the Resource Type that is needed.
<img width="1188" alt="image" src="https://github.com/user-attachments/assets/cad84cd3-98ef-4e37-89a8-099706079aea">
Fill in the details related to the Resource that need to be discovered and click on Discover New Resource to submit the job.
<img width="587" alt="image" src="https://github.com/user-attachments/assets/afc52e35-27d0-4ada-9f29-9cd5d715db21">
Once discovered , the resource home shows all the components related.
<img width="1361" alt="image" src="https://github.com/user-attachments/assets/746875a6-d9cc-4f86-a94a-823d848f5189">
It also starts collecting basic metrics along with enabling baseline and anomoly detection.

## Optional Services
### Database Management 
[Database Management](https://docs.oracle.com/en-us/iaas/database-management/home.htm) provides a comprehensive set of database performance monitoring and management features.
SQL Watch in the Oracle Cloud Infrastructure Database Management service proactively predict and prevent the SQL execution performance issues caused by system modifications or environmental changes, and ensure optimal database health.

### Ops Insights
[Ops Insights](https://docs.oracle.com/en-us/iaas/operations-insights/home.htm) provides comprehensive information about the resource use and capacity of databases and hosts. 
