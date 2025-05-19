---
title: Enable Package Metadata Database synchronization
---

The SBOM-based security scanning and license compliance features rely on a data synchronization process that is disabled
by default on the KDK. To develop these features, you must:

1. Enable the Package Metadata Database (PMDB) synchronization features.
1. Populate the local PMDB.

## Enable PMDB synchronization features on your KDK

1. Add `export PM_SYNC_IN_DEV=true` to your KDK [`env.runit` file](../runit.md#modify-service-configuration).

## Populate local PMDB

Package metadata is synchronized from PMDB to your local KhulnaSoft database. While this data is
normally updated through CRON jobs, you can populate your local database immediately using the following commands.
Run each of these commands from the root directory of your KDK instance.

### Synchronize license compliance data

To synchronize the license compliance data:

1. Import the SPDX license catalog:

   ```shell
   ./bin/rails runner 'ImportSoftwareLicensesWorker.new.perform'
   ```

1. Configure the synchronization options
   in [the Admin panel](https://docs.khulnasoft.com/ee/administration/settings/security_and_compliance.html#choose-package-registry-metadata-to-sync).

1. Synchronize package license data from PMDB:

   ```shell
   ./bin/rails runner 'PackageMetadata::LicensesSyncWorker.perform_async'
   ```

### Synchronize security advisory data

To synchronize security advisory data:

```shell
./bin/rails runner 'PackageMetadata::AdvisoriesSyncWorker.perform_async'
```

### Synchronize CVE enrichment data

To synchronize vulnerability information enrichment:

```shell
./bin/rails runner 'PackageMetadata::CveEnrichmentSyncWorker.perform_async'
```

### Verify synchronization is enabled

You can verify that the package metadata synchronization worker is running in the background
by inspecting the application logs.

```shell
# Filter application logs for advisory ingestion events.
grep -F 'Evaluating data for advisories' log/application_json.log

# Filter application logs for license ingestion events.
grep -F 'Evaluating data for licenses' log/application_json.log 

# Filter application logs for cve_enrichment ingestion events.
grep -F 'Evaluating data for cve_enrichment' log/application_json.log
```

If working correctly, you will see output that looks similar to the one below.

```json
{"severity":"DEBUG","time":"2025-01-09T17:00:12.894Z","meta.caller_id":"PackageMetadata::CveEnrichmentSyncWorker","correlation_id":"a1ed5404cfcf0861d60583ea54a8089c","meta.root_caller_id":"Cronjob","meta.feature_category":"software_composition_analysis","meta.client_id":"ip/","class":"PackageMetadata::SyncService","message":"Evaluating data for cve_enrichment:gcp/prod-export-cve-enrichment-bucket-1a6c642fc4de57d4/v2//0/0.ndjson"}
{"severity":"DEBUG","time":"2025-01-09T18:00:06.875Z","meta.caller_id":"PackageMetadata::CveEnrichmentSyncWorker","correlation_id":"dbda0e749481157c4ade8f58ba673100","meta.root_caller_id":"Cronjob","meta.feature_category":"software_composition_analysis","meta.client_id":"ip/","class":"PackageMetadata::SyncService","message":"Evaluating data for cve_enrichment:gcp/prod-export-cve-enrichment-bucket-1a6c642fc4de57d4/v2//0/0.ndjson"}
{"severity":"DEBUG","time":"2025-01-09T19:00:11.610Z","meta.caller_id":"PackageMetadata::CveEnrichmentSyncWorker","correlation_id":"901b6d4e6d72f245b19aa0ad33a5903b","meta.root_caller_id":"Cronjob","meta.feature_category":"software_composition_analysis","meta.client_id":"ip/","class":"PackageMetadata::SyncService","message":"Evaluating data for cve_enrichment:gcp/prod-export-cve-enrichment-bucket-1a6c642fc4de57d4/v2//0/0.ndjson"}
```

You can also view the synchronization progress by inspecting the synchronization checkpoints.

```ruby
# Find latest advisory sync checkpoint.
=> [#<PackageMetadata::Checkpoint:0x0000000154093850 sequence: 1736413372, created_at: Thu, 24 Oct 2024 20:33:56.822935000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:41:56.953823000 UTC +00:00, purl_type: "rpm", chunk: 0, data_type: "advisories", version_format: "v2", id: 16>,
 #<PackageMetadata::Checkpoint:0x0000000154093490
  sequence: 1736413369,
  created_at: Tue, 10 Dec 2024 17:57:36.335017000 UTC +00:00,
  updated_at: Thu, 09 Jan 2025 15:42:25.780825000 UTC +00:00,
  purl_type: "cbl-mariner",
  chunk: 0,
  data_type: "advisories",
  version_format: "v2",
  id: 21>,
 #<PackageMetadata::Checkpoint:0x0000000154091f50 sequence: 1736413377, created_at: Tue, 10 Dec 2024 09:31:32.675092000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:42:25.988332000 UTC +00:00, purl_type: "deb", chunk: 0, data_type: "advisories", version_format: "v2", id: 20>,
 #<PackageMetadata::Checkpoint:0x000000015405a780 sequence: 1736409757, created_at: Tue, 10 Dec 2024 20:12:55.697912000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:42:32.007787000 UTC +00:00, purl_type: "cargo", chunk: 0, data_type: "advisories", version_format: "v2", id: 23>,
 #<PackageMetadata::Checkpoint:0x0000000154059380 sequence: 1736413352, created_at: Tue, 10 Dec 2024 18:20:42.567914000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:42:34.696931000 UTC +00:00, purl_type: "wolfi", chunk: 0, data_type: "advisories", version_format: "v2", id: 22>,
 #<PackageMetadata::Checkpoint:0x0000000154058c00 sequence: 1736323360, created_at: Thu, 24 Oct 2024 15:10:54.208552000 UTC +00:00, updated_at: Wed, 08 Jan 2025 08:05:07.849653000 UTC +00:00, purl_type: "gem", chunk: 0, data_type: "advisories", version_format: "v2", id: 4>,
 #<PackageMetadata::Checkpoint:0x0000000154057580 sequence: 1736323355, created_at: Thu, 24 Oct 2024 15:37:30.031660000 UTC +00:00, updated_at: Wed, 08 Jan 2025 08:05:09.542168000 UTC +00:00, purl_type: "npm", chunk: 0, data_type: "advisories", version_format: "v2", id: 9>,
 #<PackageMetadata::Checkpoint:0x0000000154055fa0 sequence: 1736323366, created_at: Thu, 24 Oct 2024 15:47:16.198572000 UTC +00:00, updated_at: Wed, 08 Jan 2025 08:05:09.773544000 UTC +00:00, purl_type: "nuget", chunk: 0, data_type: "advisories", version_format: "v2", id: 11>,
 #<PackageMetadata::Checkpoint:0x00000001540553c0 sequence: 1736409747, created_at: Thu, 24 Oct 2024 14:56:24.716960000 UTC +00:00, updated_at: Thu, 09 Jan 2025 14:35:22.110284000 UTC +00:00, purl_type: "composer", chunk: 0, data_type: "advisories", version_format: "v2", id: 2>,
 #<PackageMetadata::Checkpoint:0x00000001540544c0 sequence: 1736409754, created_at: Thu, 24 Oct 2024 15:13:09.744446000 UTC +00:00, updated_at: Thu, 09 Jan 2025 14:35:25.690423000 UTC +00:00, purl_type: "golang", chunk: 0, data_type: "advisories", version_format: "v2", id: 5>,
 #<PackageMetadata::Checkpoint:0x0000000154052ee0 sequence: 1736409742, created_at: Thu, 24 Oct 2024 15:22:12.346645000 UTC +00:00, updated_at: Thu, 09 Jan 2025 14:35:26.355283000 UTC +00:00, purl_type: "maven", chunk: 0, data_type: "advisories", version_format: "v2", id: 6>,
 #<PackageMetadata::Checkpoint:0x0000000154052800 sequence: 1736409748, created_at: Thu, 24 Oct 2024 15:53:11.288556000 UTC +00:00, updated_at: Thu, 09 Jan 2025 14:35:27.388194000 UTC +00:00, purl_type: "pypi", chunk: 0, data_type: "advisories", version_format: "v2", id: 12>,
 #<PackageMetadata::Checkpoint:0x00000001540510e0 sequence: 1736413366, created_at: Thu, 24 Oct 2024 16:09:01.177944000 UTC +00:00, updated_at: Thu, 09 Jan 2025 14:40:45.255896000 UTC +00:00, purl_type: "apk", chunk: 0, data_type: "advisories", version_format: "v2", id: 13>,
 #<PackageMetadata::Checkpoint:0x000000015403d540 sequence: 1735200162, created_at: Thu, 24 Oct 2024 15:07:23.688195000 UTC +00:00, updated_at: Mon, 06 Jan 2025 15:11:04.656488000 UTC +00:00, purl_type: "conan", chunk: 0, data_type: "advisories", version_format: "v2", id: 3>]
```

```ruby
# Find latest license sync checkpoint.
[2] pry(main)> PackageMetadata::Checkpoint.where(data_type: "licenses")
=> [#<PackageMetadata::Checkpoint:0x000000016ee97068 sequence: 1736089351, created_at: Thu, 24 Oct 2024 19:37:14.354816000 UTC +00:00, updated_at: Mon, 06 Jan 2025 15:15:50.095142000 UTC +00:00, purl_type: "npm", chunk: 3, data_type: "licenses", version_format: "v2", id: 15>,
 #<PackageMetadata::Checkpoint:0x0000000154450b50 sequence: 1736177018, created_at: Fri, 25 Oct 2024 04:00:50.792159000 UTC +00:00, updated_at: Mon, 06 Jan 2025 15:25:17.806779000 UTC +00:00, purl_type: "cargo", chunk: 0, data_type: "licenses", version_format: "v2", id: 19>,
 #<PackageMetadata::Checkpoint:0x0000000154450ab0 sequence: 1736435051, created_at: Thu, 24 Oct 2024 14:55:19.596813000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:31.914640000 UTC +00:00, purl_type: "composer", chunk: 0, data_type: "licenses", version_format: "v2", id: 1>,
 #<PackageMetadata::Checkpoint:0x0000000154450a10 sequence: 1736435088, created_at: Thu, 24 Oct 2024 15:22:58.081210000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:32.484363000 UTC +00:00, purl_type: "conan", chunk: 0, data_type: "licenses", version_format: "v2", id: 7>,
 #<PackageMetadata::Checkpoint:0x0000000154450970 sequence: 1736435083, created_at: Thu, 24 Oct 2024 15:25:59.639101000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:33.809488000 UTC +00:00, purl_type: "gem", chunk: 0, data_type: "licenses", version_format: "v2", id: 8>,
 #<PackageMetadata::Checkpoint:0x00000001544506f0 sequence: 1736435090, created_at: Thu, 24 Oct 2024 15:41:12.105929000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:44.881207000 UTC +00:00, purl_type: "golang", chunk: 1, data_type: "licenses", version_format: "v2", id: 10>,
 #<PackageMetadata::Checkpoint:0x0000000154450650 sequence: 1736434918, created_at: Thu, 24 Oct 2024 18:11:28.239878000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:51.655464000 UTC +00:00, purl_type: "maven", chunk: 0, data_type: "licenses", version_format: "v2", id: 14>,
 #<PackageMetadata::Checkpoint:0x00000001544505b0 sequence: 1736435518, created_at: Fri, 25 Oct 2024 00:06:49.268974000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:40:58.029370000 UTC +00:00, purl_type: "nuget", chunk: 1, data_type: "licenses", version_format: "v2", id: 17>,
 #<PackageMetadata::Checkpoint:0x0000000154450510 sequence: 1736435064, created_at: Fri, 25 Oct 2024 02:48:23.433725000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:41:00.271158000 UTC +00:00, purl_type: "pypi", chunk: 0, data_type: "licenses", version_format: "v2", id: 18>,
 #<PackageMetadata::Checkpoint:0x0000000154450470 sequence: 1736435559, created_at: Mon, 06 Jan 2025 15:17:10.966876000 UTC +00:00, updated_at: Thu, 09 Jan 2025 15:41:02.564915000 UTC +00:00, purl_type: "swift", chunk: 0, data_type: "licenses", version_format: "v2", id: 24>]

# Find latest cve enrichment checkpoint.
PackageMetadata::Checkpoint.where(data_type: "cve_enrichment")
```
