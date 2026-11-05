---
nltk_data: /data/cache/nltk
parallel_subagent_dispatch: true
tasknode_tmp: /data/cache/tasknode

env_vars:
  SANDBOX_TIMEOUT_SECONDS: "$${SANDBOX_TIMEOUT_SECONDS}"

agent_memory_config:
  type: postgres
  connection_string: postgresql://$${POSTGRES_USER}:$${POSTGRES_PASSWORD}@$${POSTGRES_HOST}:$${POSTGRES_PORT}/agentstate
  connection_kwargs:
    autocommit: true

%{if PG_CLOUD }
pgvector_create_extension: false
%{ endif }

reasoning_in_body_for:
   -global.openai.gpt-5.6
   -global.openai.gpt-6
