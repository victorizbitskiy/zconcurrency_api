CLASS zcl_capi_iterator DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_iterator .

    METHODS constructor
      IMPORTING
        !ir_collection TYPE REF TO zif_capi_collection .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mr_collection TYPE REF TO zif_capi_collection .
    DATA mv_index TYPE i VALUE 0.
ENDCLASS.



CLASS ZCL_CAPI_ITERATOR IMPLEMENTATION.


  METHOD constructor.
    mr_collection = ir_collection.
  ENDMETHOD.


  METHOD zif_capi_iterator~current.

    mv_index = mv_index + 1.
    ro_result = mr_collection->get_item( mv_index ).

  ENDMETHOD.


  METHOD zif_capi_iterator~first.

    mv_index = mv_index + 1.
    ro_result = mr_collection->get_item( mv_index ).

  ENDMETHOD.


  METHOD zif_capi_iterator~get_index.
    rv_result = mv_index.
  ENDMETHOD.


  METHOD zif_capi_iterator~has_next.

    IF mv_index < mr_collection->size( ).
      rv_result = abap_true.
    ELSE.
      rv_result = abap_false.
    ENDIF.

  ENDMETHOD.


  METHOD zif_capi_iterator~last.

    mv_index = mr_collection->size( ).
    ro_result = mr_collection->get_item( mv_index ).

  ENDMETHOD.


  METHOD zif_capi_iterator~next.

    mv_index = mv_index + 1.
    ro_result = mr_collection->get_item( mv_index ).

  ENDMETHOD.
ENDCLASS.
