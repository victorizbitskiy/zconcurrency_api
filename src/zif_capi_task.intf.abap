INTERFACE zif_capi_task
  PUBLIC .


  INTERFACES if_serializable_object .
  INTERFACES zif_capi_callable .

  METHODS get_name
    RETURNING
      VALUE(rv_name) TYPE string .
  METHODS get_id
    RETURNING
      VALUE(rv_id) TYPE guid_32 .
ENDINTERFACE.
