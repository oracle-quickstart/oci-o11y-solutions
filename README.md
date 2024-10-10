# Knowledge Content for OCI Observability and Management Services (O&M) :tada:

OCI O&M advanced services provide a lot of knowledge content related to telemetry data collection, enrichment, analytics,dashboards, alarms etc that enable faster troubleshooting, analysis, and monitoring of infrastructre, applications, services, databases etc.

This is a community maintained repository of knowledge content created by subject matter experts for sharing best practices, recommendation, examples etc with anyone using OCI O&M Services.

Logging Analytics knowledge content consists of one or more of the following:

* [Dashboards](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/create-dashboards.html)
* [Log Sources](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/logging-analytics-terms-and-concepts.html#GUID-9B74BCD1-48BE-4A80-97E5-1C6CE9AA5EC2__SECTION_U2J_SNG_M5B) and [Parsers](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/logging-analytics-terms-and-concepts.html#GUID-9B74BCD1-48BE-4A80-97E5-1C6CE9AA5EC2__SECTION_NVT_TNG_M5B)
* [Saved Searches or Queries](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/and-share-log-searches.html)
* [Lookups](https://docs.oracle.com/en-us/iaas/logging-analytics/doc/manage-lookups.html)
* Alarms (Coming soon!)

## Browser Content

| Monitoring Target | Type | Dashboards | Log Sources | Lookups | Detection Rules 
| ---| ---| :---:| :---:| :---:| :---:
| :arrow_double_down: Oracle E-Business Suite  | Packaged App       | :heavy_check_mark:  | :heavy_check_mark:  | :heavy_check_mark: | :soon:
| :arrow_double_down: Oracle Integration Cloud | OCI Cloud Service | :heavy_check_mark:  | :gift:              | :raising_hand: |:raising_hand:|  :no_entry_sign:  
| :arrow_double_down: Security Fundamentals Dashboards | OCI Cloud Service | :heavy_check_mark:  | :gift:              | :raising_hand: |:raising_hand:|  :no_entry_sign: 
| :arrow_double_down: APEX Monitoring | OCI Cloud Service | :heavy_check_mark:  | :gift:              | :raising_hand: |:raising_hand:|  :no_entry_sign: 

Legend

|:gift: Available in-product OOTB |:heavy_check_mark: Available in this repo 
|---|---|
|:soon: Coming soon |   :raising_hand: SMEs needed
|:no_entry_sign: Not Applicable | :arrow_double_down: Click to import

<details>
  <summary> Expand to view content organization directory structure </summary> 

Knowledge content files in [knowldge-content](./knowlege-content/) folder are organized as descrived below, using e-business-suite as an example:

|Monitoring Target | Content Type | Content File  | Description
|---|---|---|---|
|[e-business-suite/](./knowlege-content/e-business-suite/)|-|-| Monitoring target system's common name is used as folder name. Contains sub-folders for different Content Types.|
||[/dashboards/](./knowlege-content/e-business-suite/dashboards/)|[/ebs-logan-1.json](./knowlege-content/e-business-suite/dashboards/EBS-Dashboards.json) | Dashboard JSON files. Nomenclature: "descriptive-string"-logan-#.json
||/[logan-lookups/](./knowlege-content/e-business-suite/logan-lookups)| [/ebs-product-map.csv](./knowlege-content/e-business-suite/logan-lookups/EBS_Lookup.csv) | csv files for query or ingest time logs enrichment
||/[log-sources](./knowlege-content/e-business-suite/log-sources)[/Oracle Cost Management/](./knowlege-content/e-business-suite/log-sources/Oracle%20Cost%20Management/)| [/ME\$EBS_MFG_DM_CST_SLA_ERROR.xml](./knowlege-content/e-business-suite/log-sources/Oracle%20Cost%20Management/ME%24EBS_MFG_DM_CST_SLA_ERROR.xml) | Log log-sources folder has sub-folders based on source category (e.g. product area, domain). Source XML Files are category folder.

</details>

## :arrow_double_down: I want to use this knowledge content

* Instructions for importing content from this repo to your OCI tenancy here

## :raising_hand: I am a subject matter expert

* Instruction for contributing to this repository.

## License

Copyright (c) 2023, Oracle and/or its affiliates.
Licensed under the Universal Permissive License v1.0 as shown at <https://oss.oracle.com/licenses/upl>.
