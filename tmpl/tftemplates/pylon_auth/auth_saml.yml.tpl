---

%{~ if lower(SSO_MODE) == "saml" ~}
authn_destination: "${SAML_AUTHN_DESTINATION}"
logout_destination: "${SAML_LOGOUT_DESTINATION}"
saml_issuer: "${SAML_ISSUER}"
sp_key:  ${jsonencode(SAML_SP_KEY)}
sp_cert: ${jsonencode(SAML_SP_CERT)}
%{~ endif ~}

%{~ if length(trimspace(SAML_IDP_METADATA)) > 0 ~}
idp_metadata: ${jsonencode(SAML_IDP_METADATA)}
%{~ else ~}
idp_cert: ${jsonencode(SAML_IDP_CERT)}
%{~ endif ~}
