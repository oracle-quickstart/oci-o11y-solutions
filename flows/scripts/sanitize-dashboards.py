# Copyright (c) 2024, Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl.

# script to read a json file from path, replace value of key "compartmentId" with "${compartment_ocid}"
# if present, remove createdBy, timeCreated, freeformTags, definedTags, 
# replace all values matching "ocid1*" with the value's md5 hash

import json
import hashlib
import argparse
import logging
import os

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)

# Read json file from path
def read_json(path):
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except Exception as e:
        logger.error("Error reading file: {}".format(e))
        exit(1)

# Write json file to path

def write_json(path, data):
    try:
        if os.path.exists(path):
            if os.access(path, os.W_OK):
                with open(path, 'w') as f:
                    json.dump(data, f, indent=2)
            else:
                logger.error("File {} is not writable".format(path))
                exit(1)
        else:
            if os.access(os.path.dirname(path), os.W_OK):
                with open(path, 'w') as f:
                    json.dump(data, f, indent=2)
            else:
                logger.error("Path {} is not writable".format(os.path.dirname(path)))
                exit(1)
    except Exception as e:
        logger.error("Error writing file: {}".format(e))
        exit(1)

# Replace value of key "compartmentId" with "${compartment_ocid}"

def replace_compartment_id(data):
    if 'dashboards' in data:
        for dashboard in data['dashboards']:
            if 'compartmentId' in dashboard:
                dashboard['compartmentId'] = "${compartment_ocid}"
            else:
                logger.info("compartmentId not found")
    return data

# Remove createdBy, timeCreated, freeformTags, definedTags

def remove_keys(data):
    if "createdBy" in data:
        del data["createdBy"]
    if "timeCreated" in data:
        del data["timeCreated"]
    if "freeformTags" in data:
        del data["freeformTags"]
    if "definedTags" in data:
        del data["definedTags"]
    return data

# Replace all values matching "ocid1*" with the value's md5 hash

def replace_ocid(data):
    for key in data:
        if isinstance(data[key], str):
            if data[key].startswith("ocid1"):
                data[key] = hashlib.md5(data[key].encode()).hexdigest()
        elif isinstance(data[key], dict):
            replace_ocid(data[key])
        elif isinstance(data[key], list):
            for item in data[key]:
                if isinstance(item, dict):
                    replace_ocid(item)
    return data


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--path", help="path to json file")
    args = parser.parse_args()
    if args.path:
        if os.path.exists(args.path):
            return args.path
        else:
            logger.error("File {} does not exist".format(args.path))
            exit(1)
    else:
        logger.error("Path not specified")
        exit(1)

# main function

def main():
    path = parse_args()
    data = read_json(path)
    data = replace_compartment_id(data)
    data = remove_keys(data)
    data = replace_ocid(data)
    write_json(path, data)

if __name__ == "__main__":
    main()

def Usage():
    print("Usage: python3 sanitize.py --path <path_to_json_file>")
    exit(1)
