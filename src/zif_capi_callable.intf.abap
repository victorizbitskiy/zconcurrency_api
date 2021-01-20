INTERFACE zif_capi_callable
  PUBLIC .


  METHODS call
    RETURNING
      VALUE(ro_result) TYPE REF TO if_serializable_object .
ENDINTERFACE.
