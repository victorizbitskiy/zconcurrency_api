class ZCL_CAPI_SPTA_WRAPPER definition
  public
  create public .

public section.

  class-methods SERIALIZE_RESULT
    importing
      !IO_RESULT type ref to IF_SERIALIZABLE_OBJECT
    returning
      value(RV_RESULT) type XSTRING .
  class-methods SERIALIZE_TASK
    importing
      !IO_TASK type ref to ZIF_CAPI_TASK
    returning
      value(RV_TASK) type XSTRING .
  class-methods DESERIALIZE_RESULT
    importing
      !IV_RESULT type XSTRING
    returning
      value(RO_RESULT) type ref to IF_SERIALIZABLE_OBJECT .
  class-methods DESERIALIZE_TASK
    importing
      !IV_TASK type XSTRING
    returning
      value(RO_TASK) type ref to ZIF_CAPI_TASK .
  methods CONSTRUCTOR
    importing
      !IV_SERVER_GROUP type RFCGR default SPACE
      !IV_MAX_NO_OF_TASKS type I default 10
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D default SPACE
      !IO_CAPI_MESSAGE_HANDLER type ref to ZIF_CAPI_MESSAGE_HANDLER .
  methods START
    importing
      !IO_TASKS type ref to ZIF_CAPI_COLLECTION
    returning
      value(RO_RESULTS) type ref to ZIF_CAPI_COLLECTION .
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
