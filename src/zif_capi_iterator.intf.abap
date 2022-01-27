INTERFACE zif_capi_iterator
  PUBLIC .


  METHODS get_index
    RETURNING
      VALUE(rv_result) TYPE i .
  METHODS has_next
    RETURNING
      VALUE(rv_result) TYPE boole_d .
  METHODS next
    RETURNING
      VALUE(ro_result) TYPE REF TO object .
  METHODS first
    RETURNING
      VALUE(ro_result) TYPE REF TO object .
  METHODS last
    RETURNING
      VALUE(ro_result) TYPE REF TO object .
  METHODS current
    RETURNING
      VALUE(ro_result) TYPE REF TO object .
ENDINTERFACE.
