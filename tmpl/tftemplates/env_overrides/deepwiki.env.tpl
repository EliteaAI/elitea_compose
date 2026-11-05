
SERVICE_LOCATION_URL="http://pylon_deepwiki:8080"
AI_RUN_PLATFORM_URL="http://pylon_main:8080/api/v2/elitea_core/register_descriptor/${PLUGINS_INITIAL_PROJECT}"
AI_RUN_PLATFORM_TOKEN=${PLUGINS_INITIAL_TOKEN}

AI_RUN_PLATFORM_VERIFY=${AI_RUN_PLATFORM_VERIFY}
AI_RUN_PLATFORM_TIMEOUT=${AI_RUN_PLATFORM_TIMEOUT}
AI_RUN_PLATFORM_DELAY=${AI_RUN_PLATFORM_DELAY}

ELITEA_RELEASE=main
GEVENT_SUPPORT=True
PYLON_WEB_RUNTIME=gevent
NAME=pylon_deepwiki
PYLON_CONFIG_SEED="file:/data/pylon.yml"

DEEPWIKI_ENABLE_FTS5=1              # FTS5 full-text search index
DEEPWIKI_SMART_EXPANSION=1          # Graph-aware expansion: inheritance, composition, creates, alias chains
DEEPWIKI_HYBRID_FUSION=1            # RRF hybrid fusion in search_codebase (FTS5 + vector store)
DEEPWIKI_ASK_AGENTIC=1              # Agentic ask tool with tool-calling

DEEPWIKI_ORPHAN_CASCADE_V2=1            # Pass1 explicit refs → Pass2 hybrid RRF → tiered FTS → directory
DEEPWIKI_ORPHAN_REUSE_EMBEDDINGS=1      # Reuse persisted vectors instead of re-embedding orphans
DEEPWIKI_ORPHAN_HYBRID_SEARCH=1         # FTS5+Vec RRF fusion in orphan resolution Pass 2
DEEPWIKI_ORPHAN_RRF_K=60                # RRF k constant for orphan hybrid fusion
DEEPWIKI_ORPHAN_RRF_THRESHOLD=0.02      # Minimum RRF score for an orphan→target edge
DEEPWIKI_FTS_MIN_SCORE_NORM=0.15        # Min normalized FTS score for orphan/lexical edges
DEEPWIKI_NODE_ID_STYLE=rel_path         # Stable rel_path-derived collision suffix
DEEPWIKI_QUALIFIED_NAME_INDEX=1         # Build _qualified_name_index + _fqn_index on graphs
DEEPWIKI_CROSS_LANGUAGE_LINKING=1       # L0–L3 cross-language linker in Phase 1c
DEEPWIKI_API_SURFACE_EXTRACTION=1       # Extract REST/gRPC/GraphQL/FFI/CLI surfaces per node
DEEPWIKI_TEST_LINKER=0                  # Off by default — pair test↔production via heuristics
DEEPWIKI_FTS_STOPWORD_GATE=1            # Skip FTS lookups for short / generic tokens (init/main/api/...)
DEEPWIKI_ORPHAN_LEXICAL_TIERED=1        # Tiered lexical T1–T4 cascade with directory + ARCH filtering
DEEPWIKI_ORPHAN_LEXICAL_IDF_GATE=1      # Gate eligible tiers by symbol IDF
DEEPWIKI_ORPHAN_REST_DISAMBIG=1         # Rewrite generic REST class queries to "<file_stem> <symbol>"

DEEPWIKI_SKIP_REPO_CONTEXT_FOR_PAGES=1
DEEPWIKI_USE_STRUCTURED_REPO_ANALYSIS=1
DEEPWIKI_ASK_USE_OPTIMIZED_CONTEXT=1
DEEPWIKI_DOC_SEPARATE_INDEX=1
DEEPWIKI_DOC_SEMANTIC_RETRIEVAL=1
DEEPWIKI_AUTO_TARGET_DOCS=1
DEEPWIKI_UNIFIED_DB=1
DEEPWIKI_UNIFIED_RETRIEVER=1
DEEPWIKI_LEGACY_INDEXES=0
