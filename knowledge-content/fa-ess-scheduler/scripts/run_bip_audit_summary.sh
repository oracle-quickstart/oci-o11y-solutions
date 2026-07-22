#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Run the Fusion BIP Audit Report Summary data model through BI Publisher SOAP.

Credentials:
  Put BIP_PASSWORD in .env.local, export it before running, or run in an interactive terminal to be prompted.
  The password is never written to disk by this script.

Environment overrides:
  BIP_BASE_URL       Fusion host base URL
  BIP_USER           Fusion username, default "bala.gupta"
  BIP_PASSWORD       Fusion password
  BIP_OPERATION      runDataModel or runReport
  BIP_CATALOG_PATH   Catalog object path
  START_DT           P_START_DT value, default "05-28-2026 17:50:21"
  END_DT             P_END_DT value, default "06-02-2026 17:50:21"
  REPORT_NAME        P_REPORT_NAME value, default "--All--"
  NUM_ROWS           P_NUM_ROWS value, default 50
  OUTPUT_DIR         Output directory, default ./output

Examples:
  BIP_PASSWORD='...' ./scripts/run_bip_audit_summary.sh
  START_DT='06-02-2026 00:00:00' END_DT='06-02-2026 23:59:59' NUM_ROWS=100 ./scripts/run_bip_audit_summary.sh
  BIP_OPERATION=runReport BIP_CATALOG_PATH='/Custom/Audit/BIP Audit Report Summary.xdo' ./scripts/run_bip_audit_summary.sh
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    print -u2 "Missing required command: $1"
    exit 1
  fi
}

load_env_file() {
  local env_file="$1"
  local line key value

  [[ -f "$env_file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" == \#* || "$line" != *=* ]] && continue

    key="${line%%=*}"
    value="${line#*=}"
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    [[ "$key" == export\ * ]] && key="${key#export }"
    [[ ! "$key" =~ '^[A-Za-z_][A-Za-z0-9_]*$' ]] && continue

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    if [[ "${value[1]:-}" == '"' && "${value[-1]:-}" == '"' ]]; then
      value="${value[2,-2]}"
    elif [[ "${value[1]:-}" == "'" && "${value[-1]:-}" == "'" ]]; then
      value="${value[2,-2]}"
    fi

    # Preserve explicit environment variables over .env.local defaults.
    if [[ -z "${(P)key:-}" ]]; then
      typeset -gx "${key}=${value}"
    fi
  done < "$env_file"
}

xml_escape() {
  printf '%s' "$1" \
    | sed -e 's/&/\&amp;/g' \
          -e 's/</\&lt;/g' \
          -e 's/>/\&gt;/g' \
          -e 's/"/\&quot;/g' \
          -e "s/'/\&apos;/g"
}

nil_string() {
  local element_name="$1"
  printf '<pub:%s xsi:nil="true"/>\n' "$element_name"
}

param_xml() {
  local name="$(xml_escape "$1")"
  local value="$(xml_escape "$2")"

  cat <<XML
<pub:item>
  $(nil_string UIType)
  $(nil_string dataType)
  $(nil_string dateFormatString)
  $(nil_string dateFrom)
  $(nil_string dateTo)
  $(nil_string defaultValue)
  $(nil_string fieldSize)
  $(nil_string label)
  $(nil_string lovLabels)
  <pub:multiValuesAllowed>false</pub:multiValuesAllowed>
  <pub:name>${name}</pub:name>
  <pub:refreshParamOnChange>false</pub:refreshParamOnChange>
  <pub:selectAll>false</pub:selectAll>
  <pub:templateParam>false</pub:templateParam>
  <pub:useNullForAll>false</pub:useNullForAll>
  <pub:values>
    <pub:item>${value}</pub:item>
  </pub:values>
</pub:item>
XML
}

extract_xml_element() {
  local element_name="$1"
  local file_path="$2"

  perl -0777 -e '
    my ($element, $file) = @ARGV;
    open my $fh, "<", $file or die "Cannot open $file: $!";
    local $/;
    my $xml = <$fh>;
    if ($xml =~ m{<(?:(?:\w+):)?\Q$element\E\b[^>]*>(.*?)</(?:(?:\w+):)?\Q$element\E>}s) {
      my $value = $1;
      $value =~ s/^\s+|\s+$//g;
      print $value;
      exit 0;
    }
    exit 2;
  ' "$element_name" "$file_path"
}

extract_base64_element() {
  local element_name="$1"
  local file_path="$2"

  perl -0777 -e '
    my ($element, $file) = @ARGV;
    open my $fh, "<", $file or die "Cannot open $file: $!";
    local $/;
    my $xml = <$fh>;
    if ($xml =~ m{<(?:(?:\w+):)?\Q$element\E\b[^>]*>(.*?)</(?:(?:\w+):)?\Q$element\E>}s) {
      my $value = $1;
      $value =~ s/\s+//g;
      print $value;
      exit 0;
    }
    exit 2;
  ' "$element_name" "$file_path"
}

require_cmd curl
require_cmd sed
require_cmd perl
require_cmd base64

load_env_file ".env.local"

BIP_BASE_URL="${BIP_BASE_URL:-https://fa-eqgj-dev11-saasfademo1.ds-fa.oraclepdemos.com}"
BIP_SERVICE_URL="${BIP_BASE_URL%/}/xmlpserver/services/v2/ReportService"
BIP_USER="${BIP_USER:-bala.gupta}"
BIP_OPERATION="${BIP_OPERATION:-runDataModel}"
if [[ -z "${BIP_CATALOG_PATH:-}" ]]; then
  if [[ "$BIP_OPERATION" == "runReport" ]]; then
    BIP_CATALOG_PATH="/Custom/Audit/BIP Audit Report Summary.xdo"
  else
    BIP_CATALOG_PATH="/Custom/Audit/Data Models/BIP Audit Report DM.xdm"
  fi
fi
START_DT="${START_DT:-05-28-2026 17:50:21}"
END_DT="${END_DT:-06-02-2026 17:50:21}"
REPORT_NAME="${REPORT_NAME:---All--}"
NUM_ROWS="${NUM_ROWS:-50}"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

if [[ "$BIP_OPERATION" != "runDataModel" && "$BIP_OPERATION" != "runReport" ]]; then
  print -u2 "BIP_OPERATION must be runDataModel or runReport, got: $BIP_OPERATION"
  exit 1
fi

if [[ -z "${BIP_PASSWORD:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rs "?BIP password for ${BIP_USER}: " BIP_PASSWORD
    print
  else
    print -u2 "BIP_PASSWORD is required when not running in an interactive terminal."
    print -u2 "Run: BIP_PASSWORD='<password>' $0"
    exit 2
  fi
fi

mkdir -p "$OUTPUT_DIR"

timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
redacted_request="${OUTPUT_DIR}/bip-audit-${BIP_OPERATION}-${timestamp}-request-redacted.xml"
soap_response="${OUTPUT_DIR}/bip-audit-${BIP_OPERATION}-${timestamp}-response.xml"
decoded_output="${OUTPUT_DIR}/bip-audit-${BIP_OPERATION}-${timestamp}-decoded.xml"

attribute_format_xml() {
  if [[ "$BIP_OPERATION" == "runReport" ]]; then
    print "<pub:attributeFormat>xml</pub:attributeFormat>"
  else
    print '<pub:attributeFormat xsi:nil="true"/>'
  fi
}

soap_payload() {
  local password="$1"
  cat <<SOAP
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:pub="http://xmlns.oracle.com/oxp/service/v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Header/>
  <soapenv:Body>
    <pub:${BIP_OPERATION}>
      <pub:reportRequest>
        <pub:XDOPropertyList xsi:nil="true"/>
        <pub:attributeCalendar xsi:nil="true"/>
        $(attribute_format_xml)
        <pub:attributeLocale xsi:nil="true"/>
        <pub:attributeTemplate xsi:nil="true"/>
        <pub:attributeTimezone xsi:nil="true"/>
        <pub:attributeUILocale xsi:nil="true"/>
        <pub:byPassCache>true</pub:byPassCache>
        <pub:dynamicDataSource xsi:nil="true"/>
        <pub:flattenXML>false</pub:flattenXML>
        <pub:parameterNameValues>
          <pub:listOfParamNameValues>
            $(param_xml "P_START_DT" "$START_DT")
            $(param_xml "P_END_DT" "$END_DT")
            $(param_xml "P_REPORT_NAME" "$REPORT_NAME")
            $(param_xml "P_NUM_ROWS" "$NUM_ROWS")
          </pub:listOfParamNameValues>
        </pub:parameterNameValues>
        <pub:reportAbsolutePath>$(xml_escape "$BIP_CATALOG_PATH")</pub:reportAbsolutePath>
        <pub:reportData xsi:nil="true"/>
        <pub:reportOutputPath xsi:nil="true"/>
        <pub:reportRawData xsi:nil="true"/>
        <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
      </pub:reportRequest>
      <pub:userID>$(xml_escape "$BIP_USER")</pub:userID>
      <pub:password>$(xml_escape "$password")</pub:password>
    </pub:${BIP_OPERATION}>
  </soapenv:Body>
</soapenv:Envelope>
SOAP
}

soap_payload "REDACTED" > "$redacted_request"

print "Calling ${BIP_OPERATION} at ${BIP_SERVICE_URL}"
print "Catalog path: ${BIP_CATALOG_PATH}"
print "Parameters: P_START_DT='${START_DT}', P_END_DT='${END_DT}', P_REPORT_NAME='${REPORT_NAME}', P_NUM_ROWS='${NUM_ROWS}'"

http_status="$(
  soap_payload "$BIP_PASSWORD" |
  curl -sS \
    -o "$soap_response" \
    -w '%{http_code}' \
    -X POST "$BIP_SERVICE_URL" \
    -H 'Content-Type: text/xml; charset=utf-8' \
    -H 'SOAPAction: ""' \
    --data-binary @-
)"

print "HTTP status: ${http_status}"
print "Redacted SOAP request: ${redacted_request}"
print "SOAP response: ${soap_response}"

if [[ "$http_status" != 2* ]]; then
  fault="$(extract_xml_element faultstring "$soap_response" 2>/dev/null || true)"
  [[ -n "$fault" ]] && print -u2 "SOAP fault: ${fault}"
  exit 3
fi

report_bytes="$(extract_base64_element reportBytes "$soap_response" 2>/dev/null || true)"
if [[ -z "$report_bytes" ]]; then
  fault="$(extract_xml_element faultstring "$soap_response" 2>/dev/null || true)"
  [[ -n "$fault" ]] && print -u2 "SOAP fault: ${fault}"
  print -u2 "No reportBytes element found in SOAP response."
  exit 4
fi

if printf '' | base64 --decode >/dev/null 2>&1; then
  printf '%s' "$report_bytes" | base64 --decode > "$decoded_output"
else
  printf '%s' "$report_bytes" | base64 -D > "$decoded_output"
fi

print "Decoded output: ${decoded_output}"
print "First lines:"
sed -n '1,40p' "$decoded_output"
