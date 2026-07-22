#!/usr/bin/env zsh
set -euo pipefail
umask 077

SCRIPT_DIR="${0:A:h}"

usage() {
  cat <<'EOF'
Run the Fusion ESSHealthRPT BI Publisher report through the ReportService SOAP API.

Credentials:
  Run interactively for a hidden password prompt.
  For non-interactive use, BIP_PASSWORD must be supplied through a protected
  execution environment. The generated SOAP request is always redacted.

Required environment:
  BIP_BASE_URL       Fusion base URL, for example https://example.fa.oraclecloud.com
  BIP_USER           Fusion service-account username
  P_FROM_TIMESTAMP   Report start timestamp in YYYY-MM-DDTHH:MM:SS.SSS
  P_TO_TIMESTAMP     Report end timestamp in YYYY-MM-DDTHH:MM:SS.SSS

Optional environment:
  BIP_PASSWORD       Fusion password
  ENV_FILE           Explicit environment file to load; not enabled by default
  OUTPUT_DIR         Output directory

Example:
  BIP_BASE_URL='https://example.fa.oraclecloud.com' \
  BIP_USER='fusion-monitor' \
  P_FROM_TIMESTAMP='2026-07-15T18:00:00.000' \
  P_TO_TIMESTAMP='2026-07-15T19:00:00.000' \
  ./scripts/run_ess_health_rpt.sh
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

param_xml() {
  local name="$(xml_escape "$1")"
  local value="$(xml_escape "$2")"
  cat <<XML
<pub:item>
  <pub:UIType xsi:nil="true"/>
  <pub:dataType xsi:nil="true"/>
  <pub:dateFormatString xsi:nil="true"/>
  <pub:dateFrom xsi:nil="true"/>
  <pub:dateTo xsi:nil="true"/>
  <pub:defaultValue xsi:nil="true"/>
  <pub:fieldSize xsi:nil="true"/>
  <pub:label xsi:nil="true"/>
  <pub:lovLabels xsi:nil="true"/>
  <pub:multiValuesAllowed>false</pub:multiValuesAllowed>
  <pub:name>${name}</pub:name>
  <pub:refreshParamOnChange>false</pub:refreshParamOnChange>
  <pub:selectAll>false</pub:selectAll>
  <pub:templateParam>false</pub:templateParam>
  <pub:useNullForAll>false</pub:useNullForAll>
  <pub:values><pub:item>${value}</pub:item></pub:values>
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

for command in curl sed perl base64 xmllint; do
  require_cmd "$command"
done

if [[ -n "${ENV_FILE:-}" ]]; then
  load_env_file "$ENV_FILE"
fi

if [[ -z "${BIP_BASE_URL:-}" ]]; then
  print -u2 "BIP_BASE_URL is required."
  exit 2
fi
if [[ -z "${BIP_USER:-}" ]]; then
  print -u2 "BIP_USER is required."
  exit 2
fi
if [[ -z "${P_FROM_TIMESTAMP:-}" ]]; then
  print -u2 "P_FROM_TIMESTAMP is required."
  exit 2
fi
if [[ -z "${P_TO_TIMESTAMP:-}" ]]; then
  print -u2 "P_TO_TIMESTAMP is required."
  exit 2
fi

BIP_SERVICE_URL="${BIP_BASE_URL%/}/xmlpserver/services/v2/ReportService"
BIP_REPORT_PATH="/Custom/ESSHealth/ESSHealthRPT.xdo"
OUTPUT_DIR="${OUTPUT_DIR:-${SCRIPT_DIR}/output/esshealthrpt}"

timestamp_pattern='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}$'
if [[ ! "$P_FROM_TIMESTAMP" =~ "$timestamp_pattern" ]]; then
  print -u2 "P_FROM_TIMESTAMP must use YYYY-MM-DDTHH:MM:SS.SSS"
  exit 2
fi
if [[ ! "$P_TO_TIMESTAMP" =~ "$timestamp_pattern" ]]; then
  print -u2 "P_TO_TIMESTAMP must use YYYY-MM-DDTHH:MM:SS.SSS"
  exit 2
fi
if [[ "$P_FROM_TIMESTAMP" > "$P_TO_TIMESTAMP" || "$P_FROM_TIMESTAMP" == "$P_TO_TIMESTAMP" ]]; then
  print -u2 "P_FROM_TIMESTAMP must be earlier than P_TO_TIMESTAMP"
  exit 2
fi

if [[ -z "${BIP_PASSWORD:-}" ]]; then
  if [[ -t 0 ]]; then
    read -rs "?BIP password for ${BIP_USER}: " BIP_PASSWORD
    print
  else
    print -u2 "BIP_PASSWORD is required when not running interactively."
    exit 2
  fi
fi

soap_payload() {
  local password="$1"
  cat <<SOAP
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:pub="http://xmlns.oracle.com/oxp/service/v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <soapenv:Header/>
  <soapenv:Body>
    <pub:runReport>
      <pub:reportRequest>
        <pub:XDOPropertyList xsi:nil="true"/>
        <pub:attributeCalendar xsi:nil="true"/>
        <pub:attributeFormat>txml</pub:attributeFormat>
        <pub:attributeLocale xsi:nil="true"/>
        <pub:attributeTemplate xsi:nil="true"/>
        <pub:attributeTimezone xsi:nil="true"/>
        <pub:attributeUILocale xsi:nil="true"/>
        <pub:byPassCache>true</pub:byPassCache>
        <pub:dynamicDataSource xsi:nil="true"/>
        <pub:flattenXML>false</pub:flattenXML>
        <pub:parameterNameValues>
          <pub:listOfParamNameValues>
            $(param_xml "P_FROM_TIMESTAMP" "$P_FROM_TIMESTAMP")
            $(param_xml "P_TO_TIMESTAMP" "$P_TO_TIMESTAMP")
          </pub:listOfParamNameValues>
        </pub:parameterNameValues>
        <pub:reportAbsolutePath>$(xml_escape "$BIP_REPORT_PATH")</pub:reportAbsolutePath>
        <pub:reportData xsi:nil="true"/>
        <pub:reportOutputPath xsi:nil="true"/>
        <pub:reportRawData xsi:nil="true"/>
        <pub:sizeOfDataChunkDownload>-1</pub:sizeOfDataChunkDownload>
      </pub:reportRequest>
      <pub:userID>$(xml_escape "$BIP_USER")</pub:userID>
      <pub:password>$(xml_escape "$password")</pub:password>
    </pub:runReport>
  </soapenv:Body>
</soapenv:Envelope>
SOAP
}

mkdir -p "$OUTPUT_DIR"
timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
redacted_request="${OUTPUT_DIR}/esshealthrpt-runReport-${timestamp}-request-redacted.xml"
soap_response="${OUTPUT_DIR}/esshealthrpt-runReport-${timestamp}-response.xml"
decoded_output="${OUTPUT_DIR}/esshealthrpt-runReport-${timestamp}-decoded.xml"

soap_payload "REDACTED" > "$redacted_request"
print "Calling runReport at ${BIP_SERVICE_URL}"
print "Report path: ${BIP_REPORT_PATH}"
print "Window: ${P_FROM_TIMESTAMP} to ${P_TO_TIMESTAMP}"

http_status="$(
  soap_payload "$BIP_PASSWORD" |
  curl -sS \
    --connect-timeout 30 \
    --max-time 300 \
    -o "$soap_response" \
    -w '%{http_code}' \
    -X POST "$BIP_SERVICE_URL" \
    -H 'Content-Type: text/xml; charset=utf-8' \
    -H 'SOAPAction: ""' \
    --data-binary @-
)"

print "HTTP status: ${http_status}"
print "Redacted request: ${redacted_request}"
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

xmllint --noout "$decoded_output"
root_name="$(xmllint --xpath 'local-name(/*)' "$decoded_output")"
if [[ "$root_name" != "DATA_DS" ]]; then
  print -u2 "Unexpected decoded XML root: ${root_name}"
  exit 5
fi

record_count="$(xmllint --xpath "count(/*[local-name()='DATA_DS']/*[local-name()='ROWS']/*[local-name()='G1'])" "$decoded_output")"
if (( record_count < 1 )); then
  print -u2 "Decoded report contains no DATA_DS/ROWS/G1 records."
  exit 5
fi

meta_count="$(xmllint --xpath "string(/*[local-name()='DATA_DS']/*[local-name()='HEADER']/*[local-name()='META_RECORD_COUNT'])" "$decoded_output")"
print "Decoded output: ${decoded_output}"
print "Parsed G1 records: ${record_count}; report metadata count: ${meta_count:-not supplied}"
