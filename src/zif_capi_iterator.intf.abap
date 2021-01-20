INTERFACE zif_capi_iterator
  PUBLIC .


  METHODS get_index
    RETURNING
      VALUE(rv_index) TYPE i .
  METHODS has_next
    RETURNING
      VALUE(rv_hasnext) TYPE boole_d .
  METHODS next
    RETURNING
      VALUE(ro_object) TYPE REF TO object .
  METHODS first
    RETURNING
      VALUE(ro_object) TYPE REF TO object .
  METHODS last
    RETURNING
      VALUE(ro_object) TYPE REF TO object .
  METHODS current
    RETURNING
      VALUE(ro_object) TYPE REF TO object .
ENDINTERFACE.
