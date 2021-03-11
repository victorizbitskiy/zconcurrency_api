INTERFACE zif_capi_facade_hcm_result
  PUBLIC .


  INTERFACES if_serializable_object .

  METHODS get
    EXPORTING
      VALUE(et_result) TYPE ANY TABLE .
ENDINTERFACE.
