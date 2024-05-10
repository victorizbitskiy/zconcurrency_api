CLASS zcl_capi_executors DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS new_fixed_thread_pool
      IMPORTING
        !iv_server_group             TYPE rfcgr
        !iv_n_threads                TYPE i DEFAULT 10
        !iv_no_resubmission_on_error TYPE boole_d DEFAULT abap_true
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler OPTIONAL
      RETURNING
        VALUE(ro_result)             TYPE REF TO zcl_capi_thread_pool_executor .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_EXECUTORS IMPLEMENTATION.


  METHOD new_fixed_thread_pool.

    CREATE OBJECT ro_result
      EXPORTING
        iv_server_group             = iv_server_group
        iv_n_threads                = iv_n_threads
        iv_no_resubmission_on_error = iv_no_resubmission_on_error
        io_capi_message_handler     = io_capi_message_handler.

  ENDMETHOD.
ENDCLASS.
