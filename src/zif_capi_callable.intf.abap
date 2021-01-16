INTERFACE zif_capi_callable
  PUBLIC .

  TYPE-POOLS abap .

  METHODS call
    RETURNING
      VALUE(ro_result) TYPE REF TO if_serializable_object .
ENDINTERFACE.
