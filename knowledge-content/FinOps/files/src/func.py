{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 import io\
import json\
import logging\
import oci\
from datetime import datetime, timedelta\
from fdk import response\
def handler(ctx, data: io.BytesIO = None):\
    try:\
        \
        reporting_namespace = 'bling'\
        reporting_bucket = \'91<Tenant OCID>\'92 \
        yesterday = datetime.now() - timedelta(days=3)\
        prefix_file = f"FOCUS Reports/\{yesterday.year\}/\{yesterday.strftime('%m')\}/\{yesterday.strftime('%d')\}"\
        print(f"prefix is \{prefix_file\}")\
        destination_path = '/tmp'\
\
        dest_namespace=\'91<bucket namespace>\'92\
        upload_bucket_name = 'Cost_Usage_Reports'  # Replace with your target bucket for uploads\
\
\
\
        Signer = oci.auth.signers.get_resource_principals_signer()\
        object_storage = oci.object_storage.ObjectStorageClient(config=\{\}, signer=Signer)\
        report_bucket_objects = oci.pagination.list_call_get_all_results(object_storage.list_objects, reporting_namespace, reporting_bucket, prefix=prefix_file)\
\
        for o in report_bucket_objects.data.objects:\
            object_details = object_storage.get_object(reporting_namespace, reporting_bucket, o.name)\
            filename = o.name.rsplit('/', 1)[-1]\
            local_file_path = destination_path+'/'+filename\
            with open(local_file_path, 'wb') as f:\
                for chunk in object_details.data.raw.stream(1024 * 1024, decode_content=False):\
                    f.write(chunk)\
            with open(local_file_path, 'rb') as file_content:\
                object_storage.put_object(\
                    namespace_name=dest_namespace,\
                    bucket_name=upload_bucket_name,\
                    object_name=filename,\
                    put_object_body=file_content\
                )\
    except (Exception, ValueError) as ex:\
        logging.getLogger().info('error parsing payload: ' + str(ex))\
    return response.Response(\
        ctx, response_data=json.dumps(\
            \{"message": "Processed Files successfully"\})\
    )}