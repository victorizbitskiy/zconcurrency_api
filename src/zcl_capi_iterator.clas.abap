class ZCL_CAPI_ITERATOR definition
  public
  create public .

public section.

  interfaces ZIF_CAPI_ITERATOR .

  methods CONSTRUCTOR
    importing
      !IR_COLLECTION type ref to ZIF_CAPI_COLLECTION .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mr_collection TYPE REF TO zif_capi_collection .
    DATA mv_index TYPE i VALUE 0 ##NO_TEXT.
ENDCLASS.



CLASS ZCL_CAPI_ITERATOR IMPLEMENTATION.


  METHOD constructor.

    mr_collection = ir_collection.

  ENDMETHOD.


  METHOD zif_capi_iterator~current.
    mv_index = mv_index + 1.
    ro_object = mr_collection->get_item( mv_index ).
  ENDMETHOD.


  METHOD zif_capi_iterator~first.
    mv_index = mv_index + 1.
    ro_object = mr_collection->get_item( mv_index ).
  ENDMETHOD.


  METHOD zif_capi_iterator~get_index.
    rv_index = mv_index.
  ENDMETHOD.


  METHOD zif_capi_iterator~has_next.
    IF mv_index < mr_collection->size( ).
      rv_hasnext = abap_true.
    ELSE.
      rv_hasnext = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD zif_capi_iterator~last.
    mv_index = mr_collection->size( ).
    ro_object = mr_collection->get_item( mv_index ).
  ENDMETHOD.


  METHOD zif_capi_iterator~next.
    mv_index = mv_index + 1.
    ro_object = mr_collection->get_item( mv_index ).
  ENDMETHOD.
ENDCLASS.
