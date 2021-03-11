CLASS zcl_capi_facade_hcm_abstr_cntx DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_capi_facade_hcm_context .
  PROTECTED SECTION.

    DATA mt_pernrs TYPE zif_capi_facade_hcm_context=>ty_t_pernrs .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_FACADE_HCM_ABSTR_CNTX IMPLEMENTATION.


  METHOD zif_capi_facade_hcm_context~get_pernrs.
    rt_pernrs = mt_pernrs.
  ENDMETHOD.


  METHOD zif_capi_facade_hcm_context~set_pernrs.
    mt_pernrs = it_pernrs.
  ENDMETHOD.
ENDCLASS.
