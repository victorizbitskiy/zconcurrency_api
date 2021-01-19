class ZCL_CAPI_SPTA_GATEWAY definition
  public
  create public .

public section.

  data MO_TASKS type ref to ZIF_CAPI_COLLECTION .
  data MV_NO_RESUBMISSION_ON_ERROR type BOOLE_D .
  data MO_CAPI_MESSAGE_HANDLER type ref to ZIF_CAPI_MESSAGE_HANDLER .
  data MO_RESULTS type ref to ZIF_CAPI_COLLECTION .

  methods CONSTRUCTOR
    importing
      !IO_TASKS type ref to ZIF_CAPI_COLLECTION
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D
      !IO_CAPI_MESSAGE_HANDLER type ref to ZIF_CAPI_MESSAGE_HANDLER
      !IO_RESULTS type ref to ZIF_CAPI_COLLECTION .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_SPTA_GATEWAY IMPLEMENTATION.


  METHOD constructor.

    mo_tasks = io_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.
    mo_results = io_results.

  ENDMETHOD.
ENDCLASS.
