CLASS zcl_capi_spta_wrapper DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS: serialize_result
      IMPORTING !io_result       TYPE REF TO if_serializable_object
      RETURNING VALUE(rv_result) TYPE xstring .
    CLASS-METHODS serialize_task
      IMPORTING
        !io_task       TYPE REF TO zif_capi_task
      RETURNING
        VALUE(rv_task) TYPE xstring .
    CLASS-METHODS deserialize_result
      IMPORTING
        !iv_result       TYPE xstring
      RETURNING
        VALUE(ro_result) TYPE REF TO if_serializable_object .
    CLASS-METHODS deserialize_task
      IMPORTING
        !iv_task       TYPE xstring
      RETURNING
        VALUE(ro_task) TYPE REF TO zif_capi_task .
    METHODS constructor
      IMPORTING
        !iv_server_group             TYPE rfcgr DEFAULT space
        !iv_max_no_of_tasks          TYPE i DEFAULT 10
        !iv_no_resubmission_on_error TYPE boole_d DEFAULT space
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler .
    METHODS start
      IMPORTING
        !io_tasks         TYPE REF TO zif_capi_collection
      RETURNING
        VALUE(ro_results) TYPE REF TO zif_capi_collection .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mv_server_group TYPE rfcgr .
    DATA mv_max_no_of_tasks TYPE i .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
ENDCLASS.



CLASS ZCL_CAPI_SPTA_WRAPPER IMPLEMENTATION.


  METHOD constructor.

    mv_server_group = iv_server_group.
    mv_max_no_of_tasks = iv_max_no_of_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.

  ENDMETHOD.


  METHOD deserialize_result.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_result
      RESULT obj = ro_result.

  ENDMETHOD.


  METHOD deserialize_task.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_task
      RESULT obj = ro_task.

  ENDMETHOD.


  METHOD serialize_result.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_result
      RESULT XML rv_result.

  ENDMETHOD.


  METHOD serialize_task.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_task
      RESULT XML rv_task.

  ENDMETHOD.


  METHOD start.

    DATA: lo_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway,
          lo_tasks             TYPE REF TO zcl_capi_collection,
          lo_results           TYPE REF TO zcl_capi_collection.

    lo_tasks ?= io_tasks.
    CREATE OBJECT lo_results.

    CREATE OBJECT lo_capi_spta_gateway
      EXPORTING
        io_tasks                    = lo_tasks
        iv_no_resubmission_on_error = mv_no_resubmission_on_error
        io_capi_message_handler     = mo_capi_message_handler
        io_results                  = lo_results.

    CALL FUNCTION 'SPTA_PARA_PROCESS_START_2'
      EXPORTING
        server_group             = mv_server_group
        max_no_of_tasks          = mv_max_no_of_tasks
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
    ENDIF.

  ENDMETHOD.
ENDCLASS.
