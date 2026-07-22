#!/usr/bin/env zsh
set -euo pipefail

usage() {
  cat <<'EOF'
Run the Fusion ESS Long Running Jobs data model through BI Publisher SOAP.

Credentials:
  Put BIP_PASSWORD in .env.local, export it before running, or run in an
  interactive terminal to be prompted. The password is never written to disk.

Environment overrides:
  BIP_BASE_URL       Fusion host base URL
  BIP_USER           Fusion username, default "bala.gupta"
  BIP_PASSWORD       Fusion password
  BIP_OPERATION      runDataModel or runReport, default "runDataModel"
  BIP_CATALOG_PATH   Catalog path, default "/Custom/ESS Long Running Jobs.xdm"
  OUTPUT_FORMAT      runReport output format, default "xml"
  OUTPUT_DIR         Output directory, default ./output/ess-long-running-jobs

Example:
  ./scripts/run_ess_long_running_jobs.sh
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
    BIP_CATALOG_PATH="/Custom/ESS_Long_Running_Jobs_Report.xdo"
  else
    BIP_CATALOG_PATH="/Custom/ESS Long Running Jobs.xdm"
  fi
fi
OUTPUT_FORMAT="${OUTPUT_FORMAT:-xml}"
OUTPUT_DIR="${OUTPUT_DIR:-output/ess-long-running-jobs}"

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
    exit 2
  fi
fi

mkdir -p "$OUTPUT_DIR"

timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"
redacted_request="${OUTPUT_DIR}/ess-long-running-jobs-${BIP_OPERATION}-${timestamp}-request-redacted.xml"
soap_response="${OUTPUT_DIR}/ess-long-running-jobs-${BIP_OPERATION}-${timestamp}-response.xml"
decoded_output="${OUTPUT_DIR}/ess-long-running-jobs-${BIP_OPERATION}-${timestamp}-decoded.xml"

attribute_format_xml() {
  if [[ "$BIP_OPERATION" == "runReport" ]]; then
    print "<pub:attributeFormat>$(xml_escape "$OUTPUT_FORMAT")</pub:attributeFormat>"
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
        <pub:parameterNameValues xsi:nil="true"/>
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
[[ "$BIP_OPERATION" == "runReport" ]] && print "Output format: ${OUTPUT_FORMAT}"

http_status="$(
  soap_payload "$BIP_PASSWORD" |
  curl -sS \
    --compressed \
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

row_count="$(perl -0777 -ne 'print scalar(() = /<G_1>/g)' "$decoded_output")"
print "Decoded output: ${decoded_output}"
if [[ "$BIP_OPERATION" == "runDataModel" || "$OUTPUT_FORMAT" == "xml" ]]; then
  print "Decoded G_1 rows: ${row_count}"
else
  print "Decoded lines: $(wc -l < "$decoded_output" | tr -d ' ')"
fi
print "First lines:"
sed -n '1,80p' "$decoded_output"
