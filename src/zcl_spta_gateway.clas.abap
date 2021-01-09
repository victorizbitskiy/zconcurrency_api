class ZCL_SPTA_GATEWAY definition
  public
  create public .

public section.

  data MO_TASKS type ref to ZIF_COLLECTION .
  data MV_NO_RESUBMISSION_ON_ERROR type BOOLE_D .
  data MO_MESSAGE_HANDLER type ref to ZIF_MESSAGE_HANDLER .
  data MO_RESULTS type ref to ZIF_COLLECTION .

  methods CONSTRUCTOR
    importing
      !IO_TASKS type ref to ZIF_COLLECTION
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D
      !IO_MESSAGE_HANDLER type ref to ZIF_MESSAGE_HANDLER
      !IO_RESULTS type ref to ZIF_COLLECTION .
protected section.
private section.
ENDCLASS.



CLASS ZCL_SPTA_GATEWAY IMPLEMENTATION.


  method CONSTRUCTOR.

    mo_tasks = io_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_message_handler = io_message_handler.
    mo_results = io_results.

  endmethod.
ENDCLASS.
