class ZCL_CAPI_EXECUTOR_SERVICE definition
  public
  create public .

public section.

  interfaces ZIF_CAPI_EXECUTOR_SERVICE .

  methods CONSTRUCTOR
    importing
      !IV_SERVER_GROUP type RFCGR
      !IV_MAX_NO_OF_TASKS type I default 10
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D default ABAP_FALSE
      !IO_CAPI_MESSAGE_HANDLER type ref to ZIF_CAPI_MESSAGE_HANDLER .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mo_capi_spta_wrapper TYPE REF TO zcl_capi_spta_wrapper .
    DATA mv_server_group TYPE rfcgr .
    DATA mv_max_no_of_tasks TYPE i .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
ENDCLASS.



CLASS ZCL_CAPI_EXECUTOR_SERVICE IMPLEMENTATION.


  METHOD constructor.

    mv_server_group = iv_server_group.
    mv_max_no_of_tasks = iv_max_no_of_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.

  ENDMETHOD.


  METHOD zif_capi_executor_service~invoke_all.

    CREATE OBJECT mo_capi_spta_wrapper
      EXPORTING
        iv_server_group             = mv_server_group
        iv_max_no_of_tasks          = mv_max_no_of_tasks
        iv_no_resubmission_on_error = mv_no_resubmission_on_error
        io_capi_message_handler     = mo_capi_message_handler.

    ro_results = mo_capi_spta_wrapper->start( io_tasks ).

  ENDMETHOD.
ENDCLASS.
