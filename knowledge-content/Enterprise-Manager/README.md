# Oracle Enterprise Manager monitored by O&M Services

This solution helps in monitoring all the components of the Enterprise Manager using Observability and Management Services.
To enable the monitoring we can follow the below steps,

## Management Agent

Management Agent is a service that provides communication and data collection between OCI and any other targets. The Management Agent will get installed on the OEM server(s) and the EM Repository DB server(s). It is used to collect OMS, EM Agent, WebLogic, Database and system logs and application, DB and system metrics. If desired, it can be used to run SQL queries against the EM Repo DB for custom metric extensions or SQL based log sources. 

To setup Management Agent we need to follow this [document](https://docs.oracle.com/en-us/iaas/management-agents/doc/install-management-agent-chapter.html#OCIAG-GUID-92777625-6549-4D8E-A27D-C1C5583071CA)


If the OMS server and EM repository database are running on OCI VM, we can just enable the Management Agent plugin available as part of Oracle Cloud Agent (OCA)
![image](https://github.com/user-attachments/assets/ece7975e-a522-481a-b0cd-ceee968dd99b)

Once the agent is successfully installed , we need to enable the plugins for utilizing the O&M services. Steps for this is available [here](https://docs.oracle.com/en-us/iaas/management-agents/doc/management-agents-administration-tasks.html#OCIAG-GUID-4D3F3DC5-4ACF-48C6-B624-F74700D0C73F)

<img width="1424" alt="image" src="https://github.com/user-attachments/assets/d96bec9a-43f4-4b96-9e42-68ed8c01f2b0">




## Application Performance Monitoring

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


## Logging Analytics
Logging Analytics service helps to analyse the logs from EM application, EM agents, EM repository DB and system logs to give insights into the application and infrastructure health. This can be used for normal day to day monitoring or in case of issues for root cause analysis. 

To get started with Logging Analytics (LA), follow [these steps](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/quick-start.html) from the documentation.

### Defining custom entity types

After enabling Logging Analytics service the initial task will be to create entities for all components of the EM environment. Since there are not yet OOB entity types for the EM OMS and EM Agent components, we will create two custom entity types (_oem_oms_ and _oem_agent_) upfront using the OCI CLI e.g. from a Cloud Shell:
```
   Getting the namespace used by a tenant (required by the next commands):
   $ oci os ns get
   {
     "data": "<NameSpace>"
   }
        
   Creating custom entity type "oem_oms":
   $ oci log-analytics entity-type create --name oem_oms --category Application --namespace-name <NameSpace>

   Creating custom entity type "oem_agent":
   $ oci log-analytics entity-type create --name oem_agent --category Application --namespace-name <NameSpace>
```
With that we are ready using the OCI Console to create all needed entities from  `Logging Analytics / Administration / Entities / Create Entity`:

* EM OMS Entity:
  - Entity Type: oem_oms
  - Name: e.g. _OEM-Prod_ 
  - Management Agent Compartment: `pick compartment`
  - Management Agent: `pick management agent`
  - Add property:
    - Property Name: InstanceHome
    - Property Value: e.g. _/u01/app/gc_inst/em/EMGC_OMS1_         

* EM Agent Entities:
  - Entity Type: oem_agent
  - Name: e.g. _Agent_OEM-Server_ or _Agent_DB-Server_  
  - Add property:
    - Property Name: AgentState
    - Property Value: e.g. _/u01/app/em_agent/agent_inst_   

* WebLogic Domain Entity:
  - Entity Type: WebLogic Domain
  - Name: e.g. _GCDomain_  
  - Add property:
    - Property Name: domain_home
    - Property Value: e.g. _/u01/app/gcinst/user_projects/domains/GCDomain_   

* WebLogic Server Entities:
  - Entity Type: WebLogic Server
  - Name: e.g. _EMGC_OMS1_ or _EMGC_ADMINSERVER_
  - Add property:
    - Property Name: domain_home
    - Property Value: e.g. _/u01/app/gcinst/user_projects/domains/GCDomain_
    - Property Name: server_names
    - Property Value: e.g. _EMGC_OMS1_ or _EMGC_ADMINSERVER_

* Oracle HTTP Server Entity:
  - Entity Type: Oracle HTTP Server
  - Name: e.g. _EMGC_OHS1_
  - Add property:
    - Property Name: ohs_home
    - Property Value: e.g. _/u01/app/gcinst/user_projects/domains/GCDomain_
    - Property Name: component_name
    - Property Value: e.g. _ohs1_

Alternatively, the above WebLogic related entities can be created by [discovering the WebLogic domain](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/auto-discovery-entities-and-log-collection.html). 

Similar, the feature ```Discover New Resource``` can be used to discover the EM Repository DB and Listener. This process will create all needed entities. Otherwise, they can get created manually like shown above for the other entities.

The host entities have already been auto-created as part of the Management Agent installation. 
  
### Create entity associations

To make use of the very useful and valueable [_Topology View_](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/view-topology-your-entities.html) feature of Logging Analytics we will now create associations between all created or discovered entities.

For this we will use again OCI CLI commands run in the Cloud Shell. To create the associations we need the `<NameSpace>` value again together with the Entity OCID values which can be easily copied from the Entity page: 
  ```
    # define parameters
    NS=<NameSpace>
    OEM_ID=ocid1.loganalyticsentity.oc1.........
    Agent_OMS_ID=ocid1.loganalyticsentity.oc1.........
    Agent_REPO_ID=ocid1.loganalyticsentity.oc1.........
    GCDomain_ID=ocid1.loganalyticsentity.oc1.........
    Admin_ID=ocid1.loganalyticsentity.oc1.........
    OMS1_ID=ocid1.loganalyticsentity.oc1.........
    OHS_ID=ocid1.loganalyticsentity.oc1.........
    DB_ID=ocid1.loganalyticsentity.oc1.........
    LSNR_ID=ocid1.loganalyticsentity.oc1.........
    OEM_Host_ID=ocid1.loganalyticsentity.oc1.........
    EMREPO_Host_ID=ocid1.loganalyticsentity.oc1.........

    # run oci cli commands to add associations
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$Agent_OMS_ID'"]' --entity-id $OEM_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$Agent_REPO_ID'"]' --entity-id $OEM_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$GCDomain_ID'"]' --entity-id $OEM_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$Admin_ID'"]' --entity-id $GCDomain_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OHS_ID'"]' --entity-id $GCDomain_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OMS1_ID'"]' --entity-id $GCDomain_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OEM_Host_ID'"]' --entity-id $OMS1_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OEM_Host_ID'"]' --entity-id $OHS_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OEM_Host_ID'"]' --entity-id $Admin_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$DB_ID'"]' --entity-id $OEM_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$LSNR_ID'"]' ---entity-id $DB_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$EMREPO_Host_ID'"]' --entity-id $DB_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$EMREPO_Host_ID'"]' --entity-id $LSNR_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$EMREPO_Host_ID'"]' --entity-id $Agent_REPO_ID
    oci log-analytics entity add-associations -ns $NS --association-entities '["'$OEM_Host_ID'"]' --entity-id $Agent_OMS_ID

    # oci cli commands to check the topology
    oci log-analytics entity-topology list --entity-id $OEM_ID -ns $NS --all
    oci log-analytics entity-topology list --entity-id $OEM_ID -ns $NS --all | grep -c '"id": '
  ```

With these associations in place, we will be able to get all the logs from all related components by entering just the EM OMS Entity name e.g. _OEM-Prod_ in the Entity filter from Log Explorer. From there, we will be able to correlate and view topology-wise log collection for the whole EM application:

<img width="993" alt="image" src="https://github.com/user-attachments/assets/68936f56-2f42-4ab5-acfa-399c7d9971ac">

### Import EM specific Log Sources

To be able to properly parse the EM OMS and EM Agent logs, we have provided several custom [log sources](log-sources) which are not yet available OOB in LA. To make them available as sources, download all the provided zip files and upload them using the action `Import Configuration Content` from `Logging Analytics -> Administration`. 

### Associate Log Sources to Entities

Before we can start collecting application, database or system logs, we have to ensure that the Management Agent user is allowed to access all the desired files. The Management Agent user will either be `mgmt_agent` or in case of an OCI VM `oracle-cloud-agent` due to the Management being a plugin of the Oracle Cloud Agent (OCA). There are now different approaches to give this user access to the various log files depending on the location and who is owning them.

* Adding the Management Agent user to the group of the application owner
  * This is the easiest solution for EM, WebLogic, OHS or database logs.
  * Verify that all directories in the whole path to the logs and the log files itselves are group readable.
* Use `setfacl` command to give Management Agent user access to system logs
  * Example commands to be run as root user or via sudo:
    *  `setfacl -m u:mgmt_agent:rx /var/log`
    *  `setfacl -m u:mgmt_agent:r /var/log/messages*`
    *  `setfacl -m u:mgmt_agent:r /var/log/secure*`   

Now that we ensured readability by the Management Agent user you can follow the [offical docs](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/manage-source-entity-association.html#LOGAN-GUID-C4604513-1D68-4F19-9352-8DE60C5788A5) to associate log sources to the entities.

  
  

## Stack monitoring
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

## Management Dashboard
Once all the services are enabled we can create dashboard and customise it. Here we are giving a sample [dashboard](dashboards) which can be imported to your tenancy. To import this you can ,
Go to Observability and Management --> Logging Analytics --> Dashboards --> Click on Import Dashboard.
<img width="1371" alt="image" src="https://github.com/user-attachments/assets/0a929077-c466-4c74-89d8-97159f87fa33">


## Optional Services
### Database Management 
[Database Management](https://docs.oracle.com/en-us/iaas/database-management/home.htm) provides a comprehensive set of database performance monitoring and management features.
SQL Watch in the Oracle Cloud Infrastructure Database Management service proactively predict and prevent the SQL execution performance issues caused by system modifications or environmental changes, and ensure optimal database health.

### Ops Insights
[Ops Insights](https://docs.oracle.com/en-us/iaas/operations-insights/home.htm) provides comprehensive information about the resource use and capacity of databases and hosts. 
