class ZCL_CAPI_EXECUTORS definition
  public
  create public .

public section.

  class-methods NEW_FIXED_THREAD_POOL
    importing
      !IV_SERVER_GROUP type RFCGR
      !IV_N_THREADS type I default 10
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D default ABAP_FALSE
      !IO_CAPI_MESSAGE_HANDLER type ref to ZIF_CAPI_MESSAGE_HANDLER
    returning
      value(RO_CAPI_THREAD_POOL_EXECUTOR) type ref to ZCL_CAPI_THREAD_POOL_EXECUTOR .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_EXECUTORS IMPLEMENTATION.


  METHOD new_fixed_thread_pool.

    CREATE OBJECT ro_capi_thread_pool_executor
      EXPORTING
        iv_server_group             = iv_server_group
        iv_n_threads                = iv_n_threads
        iv_no_resubmission_on_error = iv_no_resubmission_on_error
        io_capi_message_handler     = io_capi_message_handler.

  ENDMETHOD.
ENDCLASS.
