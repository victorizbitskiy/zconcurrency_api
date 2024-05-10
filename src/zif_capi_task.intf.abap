INTERFACE zif_capi_task
  PUBLIC .


  INTERFACES if_serializable_object .
  INTERFACES zif_capi_callable .

  METHODS get_name
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS get_id
    RETURNING
      VALUE(rv_result) TYPE guid_32 .
  METHODS get_obj_id
    RETURNING
      VALUE(rv_result) TYPE string .
ENDINTERFACE.
