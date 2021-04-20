CLASS zcl_capi_thread_pool_executor DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_executor_service .

    METHODS constructor
      IMPORTING
        !iv_server_group             TYPE rfcgr
        !iv_n_threads                TYPE i DEFAULT 10
        !iv_no_resubmission_on_error TYPE boole_d DEFAULT abap_false
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mv_server_group TYPE rfcgr .
    DATA mv_n_threads TYPE i .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
ENDCLASS.



CLASS ZCL_CAPI_THREAD_POOL_EXECUTOR IMPLEMENTATION.


  METHOD constructor.

    mv_server_group = iv_server_group.
    mv_n_threads = iv_n_threads.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.

  ENDMETHOD.


  METHOD zif_capi_executor_service~invoke_all.
    DATA: lo_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway,
          lo_tasks             TYPE REF TO zcl_capi_collection.

    lo_tasks ?= io_tasks.

    CREATE OBJECT lo_capi_spta_gateway
      EXPORTING
        io_tasks                    = lo_tasks
        iv_no_resubmission_on_error = mv_no_resubmission_on_error
        io_capi_message_handler     = mo_capi_message_handler.

    CALL FUNCTION 'SPTA_PARA_PROCESS_START_2'
      EXPORTING
        server_group             = mv_server_group
        max_no_of_tasks          = mv_n_threads
        before_rfc_callback_form = 'BEFORE_RFC'
        in_rfc_callback_form     = 'IN_RFC'
        after_rfc_callback_form  = 'AFTER_RFC'
        callback_prog            = 'ZCONCURRENCY_API'
      CHANGING
        user_param               = lo_capi_spta_gateway
      EXCEPTIONS
        invalid_server_group     = 1
        no_resources_available   = 2
        OTHERS                   = 3.
    IF sy-subrc = 0.
      ro_results ?= lo_capi_spta_gateway->mo_results.
    ELSE.
      RAISE EXCEPTION TYPE zcx_capi_tasks_invocation
        EXPORTING
          textid       = zcx_capi_tasks_invocation=>error_message
          server_group = mv_server_group.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
