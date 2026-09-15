# Fusion APM RUM Assistant for Fusion Redwood Pages

This folder packages the **Fusion APM RUM Assistant** for deploying OCI
Application Performance Monitoring (APM) Real User Monitoring (RUM) to
selected Oracle Fusion Redwood App UIs. It is the administrator-facing,
export-transform-import approach for Part 2, *Adding RUM Agent to Fusion
Redwood Pages*, of the [A-Team implementation article](https://www.ateam-oracle.com/real-user-monitoring-for-oracle-fusion-saas-cloud-apps-using-oci-apm-browser-agent).

The Assistant generates a reviewable Visual Builder Studio import archive from
an export of the target workspace. It avoids directly editing the Redwood
PageModule, Unified Module, JavaScript, or JSON in Visual Builder Studio.

> **Deployment boundary:** Run this procedure in a non-production Visual
> Builder Studio workspace first. Do not put a public data key, data-upload
> endpoint, Fusion export, generated archive, catalog, or browser-capture data
> into source control unless that storage and sharing has been approved for the
> target environment.

## What is included

| Artifact | Purpose |
| --- | --- |
| `fusion-apm-rum-assistant.zip` | The macOS/Windows Assistant, generator, packaged browser-agent library, reference material, and Visual Builder Studio import guidance. |
| `README.md` | This deployment runbook. |

Extract the archive to a private working directory. The archive contains its
own `README.md`, `docs/PHASED-APPROACH.md`, and technical reference for
operators who need the detailed generator behavior.

## Prerequisites

Before starting, ensure that the deployment team has:

1. An active OCI APM domain in the selected compartment.
2. The APM domain **Public Data Key** from **APM Domain > Resources > Data
   Keys**.
3. The APM domain **Data Upload Endpoint** from the domain details. It has the
   form `https://<domain-id>.apm-agt.<region>.oci.oraclecloud.com`.
4. Fusion access to the Redwood App UI to be monitored.
5. Visual Builder Studio project access. A Fusion role alone is not sufficient:
   the operator also needs an appropriate Visual Builder Studio role in the
   Identity Domain (for example, a synchronized developer/administrator role
   or its equivalent local VB Studio role).
6. Permission to export, import, preview, and publish the target Visual Builder
   Studio workspace.
7. Python 3 on the workstation running the Assistant. If the launcher reports
   that Python is unavailable, have local IT install it before continuing.
8. An approved privacy and security review for the target environment.

Keep `trackScreenText` and `trackPlainUserId` disabled for the initial rollout.
Screen text and plain user names can contain sensitive or personal data; APM
hashes user identifiers by default.

## Part 2: Add RUM to Fusion Redwood pages

### 1. Create a safe baseline in Visual Builder Studio

1. Sign in to Fusion and open a known Redwood page (a URL containing
   `/redwood/`).
2. From the profile menu, select **Edit the Page in Visual Builder Studio**.
   On first use, Fusion can create the project Git repository or App Extension
   project; allow that one-time setup to complete.
3. Select the target environment, sandbox, extension, and workspace. Confirm
   they correspond to the Fusion pod being instrumented.
4. In the Visual Builder Studio workspace menu, choose **Export** and save the
   full workspace archive locally.
5. Preserve an untouched copy of that export. This is the rollback artifact and
   the source of truth for the Assistant run. Do not start from an older
   generated archive.

### 2. Prepare the Assistant

1. Extract `fusion-apm-rum-assistant.zip` into a private local directory; do
   not run it in place inside a source-controlled checkout.
2. Copy the current Visual Builder Studio export into the extracted
   `downloads/` directory.
3. Start the launcher:

   - **macOS:** double-click `Fusion APM RUM Assistant.command`.
   - **Windows:** double-click `Fusion APM RUM Assistant.bat`.

4. On the first run, enter the approved OCI region, APM Public Data Key, and
   APM Data Upload Endpoint. The Assistant writes these deployment settings to
   its local configuration file; do not commit or share that file without the
   required review.
5. Leave screen-text capture and plain-user-name reporting disabled unless a
   separate privacy and security approval explicitly authorizes them.

### 3. Scope the App UIs deliberately

The initial rollout should remain limited to one functional pillar and reviewed
App UIs rather than enabling every advertised Fusion application.

1. When prompted, choose whether to refresh the App UI catalog. If it is
   required, enter the host name of the Fusion pod that matches the exported
   workspace.
2. If the catalog request requires an authenticated Fusion session, obtain the
   catalog through an approved authenticated browser workflow. Do not retain or
   share copied commands, browser cookies, authorization headers, or HAR files
   containing session material.
3. Keep the default **No** when asked to add all eligible App UIs unless the
   deployment scope has been reviewed.
4. If adding a pillar, choose only the approved pillar (HCM, CX, ERP, or SCM)
   and review the selected extensible App UIs and provider dependencies.
5. If several exports are present, select the current baseline export copied in
   step 2. The Assistant preserves the compatible Visual Builder manifest format
   and unrelated extension dependencies.

### 4. Generate and review the import archive

1. Allow the Assistant to create the transformed archive under `output/`.
2. Keep the baseline export, optional App UI catalog, local configuration, and
   generated archive together as the deployment record.
3. Verify that the generated archive targets the expected extension and uses
   the approved APM endpoint, service name (`Fusion`), and web application name
   (`RedwoodPage`).
4. Do not patch a previously generated ZIP in place. For updates, export the
   current workspace again and generate a new archive from that export.

The generated archive packages the RUM resources and uses declarative App UI
configuration. It does not require hand-editing Unified Module JavaScript or
loading a browser-agent script from `static.oracle.com`.

### 5. Import, propagate, and preview

1. In the same non-production Visual Builder Studio workspace, use the
   workspace **Import** action and choose the generated archive from `output/`.
2. Allow **5–10 minutes** for Visual Builder Studio and Fusion to build and
   propagate the App UI overrides before treating a Preview error as a failure.
3. Preview the extension and test several of the selected Redwood App UIs.
4. If an immediate 404 occurs, wait for propagation first. For a persistent
   result, use the environment's **Clear Client Cache** option, reload the
   environment, wait for it to be ready, and retry before changing the archive
   or reimporting it.
5. Review Visual Builder Studio build logs and the browser console for errors,
   including Content Security Policy (CSP) failures.

### 6. Verify RUM telemetry

1. Generate representative navigation activity in each tested Redwood App UI.
2. Open browser developer tools and use the **Network** tab to filter for
   `observations/public-span`.
3. Confirm the APM collector request reaches the approved data-upload endpoint
   and returns HTTP `200` or `204`.
4. In OCI, open the APM domain's Trace Explorer or Real User Monitoring view and
   confirm new telemetry for `ServiceName = Fusion` and
   `WebApplication = RedwoodPage`.
5. Enable the Oracle-provided **FUS** span enrichment rule in **APM Domain >
   Administration > Span Rules** if Fusion-specific dimensions such as
   `RwApplication`, `RwContainer`, `RwPath`, and `FusFamily` are required.
6. Confirm that revisiting an App UI does not duplicate browser-agent loading
   or telemetry initialization.

Do not publish until the selected App UIs, browser upload, APM telemetry,
privacy controls, and CSP behavior have passed review in the non-production
workspace.

### 7. Publish and retain rollback evidence

1. Record the tested workspace, selected pillar and App UIs, APM domain,
   validation date, and approver in the deployment record.
2. Publish the Visual Builder Studio change only after the acceptance checks
   pass and the normal change process approves it.
3. Retain the untouched export until production validation is complete. To
   roll back, import or restore that original workspace export using the
   approved Visual Builder Studio process.

## Operations and updates

Repeat discovery after a quarterly Fusion update, an additional Fusion offering
is enabled, or business usage changes. Compare the latest App UI catalog with
the approved selection, propose additions for review, and create a new archive
from a fresh Visual Builder Studio export. Never activate all newly discovered
App UIs automatically.

For a browser-agent or configuration update, use a fresh workspace export,
regenerate the full archive, validate in non-production, and then follow the
same publish gate.

## References

- [A-Team: Real User Monitoring for Oracle Fusion SaaS Cloud Apps using OCI APM Browser Agent](https://www.ateam-oracle.com/real-user-monitoring-for-oracle-fusion-saas-cloud-apps-using-oci-apm-browser-agent)
- [OCI APM: Configure the APM Browser Agent for Real User Monitoring](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/configure-browser-agent-real-user-monitoring.html)
- [OCI APM: Verify APM Browser Agent Deployment](https://docs.oracle.com/en-us/iaas/application-performance-monitoring/doc/verify-browser-agent-deployment.html)
- [Visual Builder Studio: Export Your Workspace as an Archive](https://docs.oracle.com/en/cloud/paas/visual-builder/visualbuilder-building-appui/export-your-workspace-archive.html)
- [Visual Builder Studio: Import Resources to Your Workspace](https://docs.oracle.com/en/cloud/paas/visual-builder/visualbuilder-building-appui/import-resources-your-workspace.html)
