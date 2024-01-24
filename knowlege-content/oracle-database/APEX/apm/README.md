# Set up a Real User Monitor for an APEX application with OCI Application Performance Monitoring

OCI [Application Performance Monitoring (APM)](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/home.htm) provides [Real User Monitoring (RUM)](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-browser-agent-real-user-monitoring.html) for browser based applications. You can use this monitor to create alerts for performance and availability problems, to diagnose performance issues, and to analyze the end user's behavior. It works for internal or external facing apps deployed on Oracle Cloud or other cloud providers.

Real User Monitoring tracks user sessions, page views, page load times and identifies ajax calls response times for all users, all the time. It uses a dedicated JavaScript agent that's OpenTelemetry compliant to collect out-of-the-box and customized metrics and dimensions, to provide a detailed analysis of any performance and availability issues. The monitoring collected data is available for alerts, analysis, and dynamic dashboards using a powerful query language with a rich set of widgets to present your real-time end user data.

[Oracle APEX application](https://apex.oracle.com/en/learn/videos/) is a low-code platform that enables developers to build enterprise scalable, secure websites and mobile applications that can run on-premises and in Oracle Cloud.

In this video, you will learn how to set up an Application Performance Real User Monitor for an APEX application. 

<a href="https://www.youtube.com/watch?v=VUYjIYqDAVc"><img width="999" alt="YouTube thumbnail" src="https://github.com/oracle-quickstart/oci-o11y-solutions/assets/106996346/e3e4c387-ee4e-48f0-a1e1-5450b404a894"></a>

## Install the Browser Agent
Add this JavaScript code snippet to your APEX application's global page to collect real user data from your website developed on APEX. Now, your dashboards can display the APEX version, the session ID, the page id, and the user name of each end user of your APEX application.
```
<script>
    window.apmrum = (window.apmrum || {}); 
    window.apmrum.serviceName='<APM Browser>';
    window.apmrum.webApplication='<Web App Name>';
    window.apmrum.ociDataUploadEndpoint='<ociDataUploadEndpoint>';
    window.apmrum.OracleAPMPublicDataKey='<APM_Public_Datakey>';
    window.apmrum.udfAttributes = [
        { name: 'UserName', value: () => apex.env.APP_USER },
        { name: 'APEXSessionId', value: () => apex.env.APP_SESSION },
        { name: 'APEXPageId', value: () => apex.env.APP_PAGE_ID },
        { name: 'APEXVersion', value: () => apex.env.APEX_VERSION },
        { name: 'APEXPageName', value: () => document.location.pathname.split('/').pop()},
        { name: 'APEXDBClientId', value: () => (apex.env.APP_USER + ':' + apex.env.APP_SESSION) }
    ];   
</script>
<script async crossorigin="anonymous" src="<ociDataUploadEndpoint>/static/jslib/apmrum.min.js"></script>

```
## Create a Custom APEX Dashboard 
Download this [JSON file](https://github.com/oracle-quickstart/oci-o11y-solutions/blob/0de0d63f61782f04a204e57ea929a313fb1770d2/knowlege-content/oracle-database/APEX/dashboards/apm-rum-apex-dashboard.json) to import this custom dashboard to your Oracle Cloud instance to monitor your APEX application. The video posted above demonstrates how to import your dashboard.

![dashboard-apex](https://github.com/oracle-quickstart/oci-o11y-solutions/assets/106996346/b952ce8c-f920-435b-a14f-c8a8258c5fc3)

## Integrate with the Database Management Service on Oracle Cloud

If you have the Database Management service installed, then you can use this code to set up your Database Management Performance Hub in Application Performance Monitoring. The steps are demonstrated in the video above. 

```
/dbmgmt-ui/perfhub?ocid=<DB OCID>&perfhubContext={"dateTime":{"startDate":<APMStartTimeMs>,"endDate":<APMEndTimeMs>},"selectedTab":{"name":"activityTab","filters": [{"key":"filter_list","value":"{\"client_id\":{\"value\":\"<UserName>:<APEXSessionId>\"}}"}]}}
```
For more information you can view the Application Performance Monitoring related documentation topics and videos: 

* [Configure browser agent Real User Monitoring](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-browser-agent-real-user-monitoring.html)

* [Configure open source tracing systems using Open Telemetry](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-open-source-tracing-systems.html)

* [Configure Attributes for Real User Monitoring](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-attributes-real-user-monitoring.html) 

* [Configure drilldown configurations](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-drilldown-configurations.html)

* [Export and import dashboards](https://docs.oracle.com/en-us/iaas/Content/doc/export-and-import-dashboards.html)

* [Database Management Documentation](https://docs.oracle.com/en-us/iaas/database-management/home.htm)

* [Use On-Premise Vantage Points](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/use-onpremise-vantage-points.html)

* [Record a script and create a monitor](https://www.youtube.com/watch?v=rImVleiCsYo)

* [Application Performance Monitoring Documentation](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/)
 
* [Application Performance Monitoring Video Playlist](https://www.youtube.com/playlist?list=PLiuPvpy8QsiV0dnG-YYaJ83FJOG_Q4eIl)
  
Sign up for a [free Oracle Cloud account](https://www.oracle.com/cloud/free/) to try this feature. 
