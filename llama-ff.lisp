(in-package :llama)

(ff:def-foreign-type llama-model (* :void))

(ff:def-foreign-type llama-context (* :void))

(ff:def-foreign-type llama-token :int)

;; llama_log_level

;; llama_vocab_type

;; llama_token_type

;; llama_ftype

(ff:def-foreign-type llama-token-data
    (:struct (id llama-token)
	     (logit :float)
	     (p :float)))

(ff:def-foreign-type llama-token-data-array
    (:struct (data (* llama-token-data))
	     (size :unsigned-long)
	     (sorted :char boolean)))

(ff:def-foreign-type llama-progress-callback (* :void))

(ff:def-foreign-type llama-context-params
    (:struct (seed :int)
	     (n-ctx :int)
	     (n-batch :int)
	     (n-gpu-layers :int)
	     (main-gpu :int)
	     (tensor-split (* :float))
	     (rope-freq-base :float)
	     (rope-freq-scale :float)
	     (progress-callback (* :void))
	     (progress-callback-user-data (* :void))
	     (low-vram :char boolean)
	     (mul-mat :char boolean)
	     (f16-kv :char boolean)
	     (logits-all :char boolean)
	     (vocab-only :char boolean)
	     (use-mmap :char boolean)
	     (use-mlock :char boolean)
	     (embedding :char boolean)))

;; llama_log_callback

;; llama_model_quantize_params

(ff:def-foreign-type llama-grammar (* :void))

;; llama_gretype

(ff:def-foreign-type llama-grammar-element
    (:struct (type :int) ;; enum llama_gretype
	     (value :unsigned-long)))

(ff:def-foreign-type llama-timings
    (:struct (t-start-ms :double)
	     (t-end-ms :double)
	     (t-load-ms :double)
	     (t-sample-ms :double)
	     (t-p-eval-ms :double)
	     (t-eval-ms :double)
	     (n-sample :int)
	     (n-p-eval :int)
	     (n-eval :int)))

(ff:def-foreign-call (llama-context-default-params "llama_context_default_params")
    (:void)
  :returning llama-context-params
  :pass-structs-by-value t)

;; llama_model_quantize_default_params

(ff:def-foreign-call (llama-backend-init "llama_backend_init")
    ((numa :char boolean))
  :returning :void)

(ff:def-foreign-call (llama-backend-free "llama_backend_free")
    (:void)
  :returning :void)

(ff:def-foreign-call (llama-load-model-from-file "llama_load_model_from_file")
    ((path-model (* :char))
     (params (* llama-context-params)))
  :returning llama-model)

(ff:def-foreign-call (llama-free-model "llama_free_model")
    ((model (* llama-model)))
  :returning :void)

(ff:def-foreign-call (llama-new-context-with-model "llama_new_context_with_model")
    ((model (* llama-model))
     (params (* llama-context-params)))
  :returning llama-context)

;; ;; DEPRECATED
;; (ff:def-foreign-call (llama-init-from-file "llama_init_from_file")
;;     ((path-model (* :char))
;;      (params (* llama-context-params)))
;;   :returning llama-context)

(ff:def-foreign-call (llama-free "llama_free")
    ((ctx (* llama-context)))
  :returning :void)

(ff:def-foreign-call (llama-time-us "llama_time_us")
    (:void)
  :returning :unsigned-long)

(ff:def-foreign-call (llama-max-devices "llama_max_devices")
    (:void)
  :returning :int)

(ff:def-foreign-call (llama-mmap-supported "llama_mmap_supported")
    (:void)
  :returning :boolean)

(ff:def-foreign-call (llama-mlock-supported "llama_mlock_supported")
    (:void)
  :returning :boolean)

(ff:def-foreign-call (llama-n-vocab "llama_n_vocab")
    ((ctx (* llama-context)))
  :returning :int)

(ff:def-foreign-call (llama-n-ctx "llama_n_ctx")
    ((ctx (* llama-context)))
  :returning :int)

(ff:def-foreign-call (llama-n-ctx-train "llama_n_ctx_train")
    ((ctx (* llama-context)))
  :returning :int)

(ff:def-foreign-call (llama-n-embd "llama_n_embd")
    ((ctx (* llama-context)))
  :returning :int)

(ff:def-foreign-call (llama-model-n-vocab "llama_model_n_vocab")
    ((model (* llama-model)))
  :returning :int)

(ff:def-foreign-call (llama-model-n-ctx "llama_model_n_ctx")
    ((model (* llama-model)))
  :returning :int)

(ff:def-foreign-call (llama-model-n-ctx-train "llama_model_n_ctx_train")
    ((model (* llama-model)))
  :returning :int)

(ff:def-foreign-call (llama-model-n-embd "llama_model_n_embd")
    ((model (* llama-model)))
  :returning :int)

(ff:def-foreign-call (llama-model-desc "llama_model_desc")
    ((model (* llama-model))
     (buf (* :char))
     (buf-size :unsigned-long))
  :returning :int)

(ff:def-foreign-call (llama-model-n-embd "llama_model_size")
    ((model (* llama-model)))
  :returning :unsigned-long)

(ff:def-foreign-call (llama-model-n-params "llama_model_n_params")
    ((model (* llama-model)))
  :returning :unsigned-long)

;; llama_model_quantize

;; ;; DEPRECATED
;; (ff:def-foreign-call (llama-apply-lora-from-file "llama_apply_lora_from_file")
;;     ((ctx (* llama-context))
;;      (path-lora (* :char))
;;      (path-base-model (* :char))
;;      (n-threads :int))
;;   :returning :int)

(ff:def-foreign-call (llama-model-apply-lora-from-file "llama_model_apply_lora_from_file")
    ((model (* llama-model))
     (path-lora (* :char))
     (path-base-model (* :char))
     (n-threads :int))
  :returning :int)

(ff:def-foreign-call (llama-get-kv-cache-token-count "llama_get_kv_cache_token_count")
    ((ctx (* llama-context)))
  :returning :int)

(ff:def-foreign-call (llama-set-rng-seed "llama_set_rng_seed")
    ((ctx (* llama-context))
     (seed :int))
  :returning :void)

(ff:def-foreign-call (llama-get-state-size "llama_get_state_size")
    ((ctx (* llama-context)))
  :returning :unsigned-long)

;; llama_copy_state_data

;; llama_set_state_data

;; llama_load_session_file

;; llama_save_session_file

(ff:def-foreign-call (llama-eval "llama_eval")
    ((ctx (* llama-context))
     (tokens (* llama-token))
     (n-tokens :int)
     (n-past :int)
     (n-threads :int))
  :returning :int)

(ff:def-foreign-call (llama-eval-embd "llama_eval_embd")
    ((ctx (* llama-context))
     (embd (* :float))
     (n-tokens :int)
     (n-past :int)
     (n-threads :int))
  :returning :int)

;; llama_eval_export

(ff:def-foreign-call (llama-get-logits "llama_get_logits")
    ((ctx (* llama-context)))
  :returning ((* :float)))

(ff:def-foreign-call (llama-get-embeddings "llama_get_embeddings")
    ((ctx (* llama-context)))
  :returning ((* :float)))

(ff:def-foreign-call (llama-token-get-text "llama_token_get_text")
    ((ctx (* llama-context))
     (token llama-token))
  :returning ((* :char)))

(ff:def-foreign-call (llama-token-get-score "llama_token_get_score")
    ((ctx (* llama-context))
     (token llama-token))
  :returning :float)

(ff:def-foreign-call (llama-token-get-type "llama_token_get_type")
    ((ctx (* llama-context))
     (token llama-token))
  :returning :int)

(ff:def-foreign-call (llama-token-bos "llama_token_bos")
    ((ctx (* llama-context)))
  :returning llama-token)

(ff:def-foreign-call (llama-token-eos "llama_token_eos")
    ((ctx (* llama-context)))
  :returning llama-token)

(ff:def-foreign-call (llama-token-nl "llama_token_nl")
    ((ctx (* llama-context)))
  :returning llama-token)

(ff:def-foreign-call (llama-tokenize "llama_tokenize")
    ((ctx (* llama-context))
     (text (* :char))
     (text-len :int)
     (tokens (* llama-token))
     (n-max-tokens :int)
     (add-bos :int boolean))
  :returning :int)

(ff:def-foreign-call (llama-tokenize-with-model "llama_tokenize_with_model")
    ((model (* llama-model))
     (text (* :char))
     (text-len :int)     
     (tokens (* llama-token))
     (n-max-tokens :int)
     (add-bos :int boolean))
  :returning :int)

(ff:def-foreign-call (llama-token-to-piece "llama_token_to_piece")
    ((ctx (* llama-context))
     (token llama-token)
     (buf (* :char))
     (length :int))
  :returning :int)

(ff:def-foreign-call (llama-token-to-piece-with-model "llama_token_to_piece_with_model")
    ((model (* llama-model))
     (token llama-token)
     (buf (* :char))
     (length :int))
  :returning :int)

(ff:def-foreign-call (llama-grammar-init "llama_grammar_init")
    ((grammar (* (* llama-grammar-element)))
     (n-rules :unsigned-long)
     (start-rule-index :unsigned-long))
  :returning ((* llama-grammar)))

(ff:def-foreign-call (llama-grammar-free "llama_grammar_free")
    ((grammar (* llama-grammar)))
  :returning :void)

(ff:def-foreign-call (llama-grammar-copy "llama_grammar_copy")
    ((grammar (* llama-grammar)))
  :returning ((* llama-grammar)))

(ff:def-foreign-call (llama-sample-repetition-penalty "llama_sample_repetition_penalty")
    ((ctx (* llama-context))
     (candidates (* llama-token-data-array))
     (last_tokens (* llama-token))
     (last-tokens-size :unsigned-long)
     (penalty :float))
  :returning :void)

(ff:def-foreign-call (llama-sample-frequency-and-presence-penalties "llama_sample_frequency_and_presence_penalties")
    ((ctx (* llama-context))
     (candidates (* llama-token-data-array))
     (last_tokens (* llama-token))
     (last-tokens-size :unsigned-long)
     (alpha-frequency :float)
     (alpha-presence :float))
  :returning :void)

(ff:def-foreign-call (llama-sample-classifier-free-guidance "llama_sample_classifier_free_guidance")
    ((ctx (* llama-context))
     (candidates (* llama-token-data-array))
     (guidance-ctx (* llama-context))
     (scale :float))
  :returning :void)

(ff:def-foreign-call (llama-sample-softmax "llama_sample_softmax")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array)))
  :returning :void)

(ff:def-foreign-call (llama-sample-top-k "llama_sample_top_k")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (k :int)
   (min-keep :unsigned-long))
  :returning :void)

(ff:def-foreign-call (llama-sample-top-p "llama_sample_top_p")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (p :float)
   (min-keep :unsigned-long))
  :returning :void)

(ff:def-foreign-call (llama-sample-tail-free "llama_sample_tail_free")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (z :float)
   (min-keep :unsigned-long))
  :returning :void)

(ff:def-foreign-call (llama-sample-typical "llama_sample_typical")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (p :float)
   (min-keep :unsigned-long))
  :returning :void)

(ff:def-foreign-call (llama-sample-temperature "llama_sample_temperature")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (temp :float))
  :returning :void)

(ff:def-foreign-call (llama-sample-grammar "llama_sample_grammar")
    ((ctx (* llama-context))
     (candidates (* llama-token-data-array))
     (grammar (* llama-grammar)))
  :returning :void)

(ff:def-foreign-call (llama-sample-token-mirostat "llama_sample_token_mirostat")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (tau :float)
   (eta :float)
   (m :int)
   (mu (* :float)))
  :returning llama-token)

(ff:def-foreign-call (llama-sample-token-mirostat-v2 "llama_sample_token_mirostat_v2")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array))
   (tau :float)
   (eta :float)
   (mu (* :float)))
  :returning llama-token)

(ff:def-foreign-call (llama-sample-token-greedy "llama_sample_token_greedy")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array)))
  :returning llama-token)

(ff:def-foreign-call (llama-sample-token "llama_sample_token")
  ((ctx (* llama-context))
   (candidates (* llama-token-data-array)))
  :returning llama-token)

(ff:def-foreign-call (llama-grammar-accept-token "llama_grammar_accept_token")
    ((ctx (* llama-context))
     (grammar (* llama-grammar))
     (token llama-token))
  :returning :void)

;; llama_beam_view

;; llama_beam_state

;; llama_beam_search_callback_fn_t

;; llama_beam_search

(ff:def-foreign-call (llama-get-timings "llama_get_timings")
    ((ctx (* llama-context)))
  :returning llama-timings
  :pass-structs-by-value t)

(ff:def-foreign-call (llama-print-timings "llama_print_timings")
    ((ctx (* llama-context)))
  :returning :void)

(ff:def-foreign-call (llama-reset-timings "llama_reset_timings")
    ((ctx (* llama-context)))
  :returning :void)

(ff:def-foreign-call (llama-print-system-info "llama_print_system_info")
    (:void)
  :returning ((* :char)))

;; llama_log_set

;; llama_dump_timing_info_yaml
