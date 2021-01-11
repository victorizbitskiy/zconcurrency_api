CLASS zcl_capi_spta_gateway DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA mo_tasks TYPE REF TO zif_capi_collection .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
    DATA mo_results TYPE REF TO zif_capi_collection .

    METHODS constructor
      IMPORTING
        !io_tasks                    TYPE REF TO zif_capi_collection
        !iv_no_resubmission_on_error TYPE boole_d
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler
        !io_results                  TYPE REF TO zif_capi_collection .
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
