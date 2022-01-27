INTERFACE zif_capi_collection
  PUBLIC .


  METHODS size
    RETURNING
      VALUE(rv_result) TYPE i .
  METHODS is_empty
    RETURNING
      VALUE(rv_result) TYPE boole_d .
  METHODS get_item
    IMPORTING
      !iv_index        TYPE i
    RETURNING
      VALUE(ro_result) TYPE REF TO object .
  METHODS add
    IMPORTING
      !ir_object TYPE REF TO object .
  METHODS remove_index
    IMPORTING
      !iv_index TYPE i .
  METHODS remove
    IMPORTING
      !ir_item TYPE REF TO object .
  METHODS clear .
  METHODS get_iterator
    RETURNING
      VALUE(ro_result) TYPE REF TO zif_capi_iterator .
ENDINTERFACE.
