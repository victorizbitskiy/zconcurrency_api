INTERFACE zif_capi_executor_service
  PUBLIC .


  METHODS invoke_all
    IMPORTING
      !io_tasks        TYPE REF TO zif_capi_collection
    RETURNING
      VALUE(ro_result) TYPE REF TO zif_capi_collection
    RAISING
      zcx_capi_tasks_invocation .
ENDINTERFACE.
