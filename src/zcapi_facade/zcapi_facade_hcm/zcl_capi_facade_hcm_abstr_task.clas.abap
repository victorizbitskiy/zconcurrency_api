CLASS zcl_capi_facade_hcm_abstr_task DEFINITION
  PUBLIC
  INHERITING FROM zcl_capi_abstract_task
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !iv_name    TYPE string OPTIONAL
        !io_context TYPE REF TO zcl_capi_facade_hcm_abstr_cntx .
  PROTECTED SECTION.

    DATA mt_pernrs TYPE zif_capi_facade_hcm_context=>ty_t_pernrs .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_FACADE_HCM_ABSTR_TASK IMPLEMENTATION.


  METHOD constructor.
    super->constructor( iv_name ).
    mt_pernrs = io_context->zif_capi_facade_hcm_context~get_pernrs( ).
  ENDMETHOD.
ENDCLASS.
