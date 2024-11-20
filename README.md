# vRA code and sniplets

## Enable Configuration Properties
https://cloudblogger.co.in/2024/11/15/aria-automation-configuration-properties-the-chamber-of-secrets/

In Assembler -> Infrastructure -> Replace settings with configurationProperties in URL

https://<VRA-FQDN>/automation/#/service/automation-ui/provisioning-ui;ash=%2FconfigurationProperties


## Via API
curl -k -s -H "Content-Type: application/json" -H "Authorization: Bearer $access_token" \
$url/iaas/api/configuration-properties?apiVersion=2021-07-15 -X PATCH \
-d '{"key":"SESSION_TIMEOUT_DURATION_MINUTES", "value":"360"}'
