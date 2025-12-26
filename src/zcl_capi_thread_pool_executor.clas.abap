CLASS zcl_capi_thread_pool_executor DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_executor_service .

    METHODS constructor
      IMPORTING
        !iv_server_group             TYPE rfcgr
        !iv_n_threads                TYPE i DEFAULT 10
        !iv_no_resubmission_on_error TYPE boole_d DEFAULT abap_true
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler OPTIONAL .
    CLASS-METHODS max_no_of_tasks
      IMPORTING
        !iv_server_group TYPE rfcgr
      RETURNING
        VALUE(rv_result) TYPE i .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mv_server_group TYPE rfcgr .
    DATA mv_n_threads TYPE i .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .

    METHODS rfc_connection_close .
ENDCLASS.



CLASS ZCL_CAPI_THREAD_POOL_EXECUTOR IMPLEMENTATION.


  METHOD constructor.

    mv_server_group = iv_server_group.
    mv_n_threads = iv_n_threads.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.

    IF io_capi_message_handler IS BOUND.
      mo_capi_message_handler = io_capi_message_handler.
    ELSE.
      CREATE OBJECT mo_capi_message_handler TYPE zcl_capi_message_handler.
    ENDIF.

  ENDMETHOD.


  METHOD max_no_of_tasks.

    DATA lv_free_pbt_wps TYPE i.

    CALL FUNCTION 'SPBT_INITIALIZE'
      EXPORTING
        group_name                     = iv_server_group
      IMPORTING
        free_pbt_wps                   = lv_free_pbt_wps
      EXCEPTIONS
        invalid_group_name             = 1
        internal_error                 = 2
        pbt_env_already_initialized    = 3
        currently_no_resources_avail   = 4
        no_pbt_resources_found         = 5
        cant_init_different_pbt_groups = 6
        OTHERS                         = 7.
    IF sy-subrc = 0.
      " We do not use all available dialog processes.
      " Only 40% are reserved for parallel tasks to avoid overloading the system.
      " This percentage was determined empirically to balance performance and system stability.
      rv_result = lv_free_pbt_wps * 40 / 100.
    ELSE.
      rv_result = 5.
    ENDIF.

  ENDMETHOD.


  METHOD rfc_connection_close.

    DATA lt_serverlist TYPE STANDARD TABLE OF msxxlist.
    DATA lt_irfcdes    TYPE STANDARD TABLE OF rfcdest.
    DATA lv_irfcdest   TYPE string.

    FIELD-SYMBOLS <lv_irfcdest> TYPE rfcdest.

    CALL FUNCTION 'TH_SERVER_LIST'
      TABLES
        list           = lt_serverlist
      EXCEPTIONS
        no_server_list = 1
        OTHERS         = 2.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CONCATENATE '%\_' sy-sysid '\_%' INTO lv_irfcdest.

    SELECT rfcdest FROM rfcdes INTO TABLE lt_irfcdes
      WHERE rfctype = 'I'
      AND rfcdest LIKE lv_irfcdest
      ESCAPE '\'.

    LOOP AT lt_irfcdes ASSIGNING <lv_irfcdest>.
      CALL FUNCTION 'RFC_CONNECTION_CLOSE'
        EXPORTING
          destination = <lv_irfcdest>
        EXCEPTIONS
          OTHERS      = 0.
    ENDLOOP.

  ENDMETHOD.


  METHOD zif_capi_executor_service~invoke_all.

    DATA lo_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway.
    DATA lo_tasks             TYPE REF TO zcl_capi_collection.

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
      ro_result ?= lo_capi_spta_gateway->mo_results.

      " We explicitly close the RFC connections opened by the TH_WPINFO function module.
      " Without this, they are only closed when exiting the report/transaction.
      " https://github.com/victorizbitskiy/zconcurrency_api/issues/12
      rfc_connection_close( ).

    ELSE.
      RAISE EXCEPTION TYPE zcx_capi_tasks_invocation
        EXPORTING
          textid       = zcx_capi_tasks_invocation=>error_message
          server_group = mv_server_group.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
