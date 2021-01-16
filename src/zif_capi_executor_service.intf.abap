INTERFACE zif_capi_executor_service
  PUBLIC .

  TYPE-POOLS abap .

  METHODS invoke_all
    IMPORTING
      !io_tasks         TYPE REF TO zif_capi_collection
    RETURNING
      VALUE(ro_results) TYPE REF TO zif_capi_collection .
ENDINTERFACE.
