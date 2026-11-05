---

%{~ if lower(SSO_MODE) == "form" ~}
metadata_endpoint: ""
client_id: ""
client_secret: ""
url_mode: "external"
%{~ else ~}
  %{~ if lower(SSO_MODE) == "oidc" ~}
authorization_endpoint: "${OIDC_AUTHORIZATION_ENDPOINT}"
client_id: "${OIDC_CLIENT_ID}"
client_secret: "${OIDC_CLIENT_SECRET}"
end_session_endpoint: "${OIDC_END_SESSION_ENDPOINT}"
metadata_endpoint: "${OIDC_METADATA_ENDPOINT}"
token_endpoint: "${OIDC_TOKEN_ENDPOINT}"
url_mode: "${OIDC_URL_MODE}"
userinfo_endpoint: "${OIDC_USERINFO_ENDPOINT}"
expiration_override: ${SSO_EXPIRATION_OVERRIDE}
  %{~ else ~}
# Unknown SSO_MODE: "${SSO_MODE}"
  %{~ endif ~}
%{~ endif ~}
