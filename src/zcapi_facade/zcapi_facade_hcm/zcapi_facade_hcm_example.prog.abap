*&---------------------------------------------------------------------*
*& Report ZCAPI_FACADE_HCM_DEMO
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcapi_facade_hcm_demo.

INCLUDE: zcapi_facade_hcm_demo_cld,
         zcapi_facade_hcm_demo_cli.

START-OF-SELECTION.
  lcl_app=>start_of_selection( ).

END-OF-SELECTION.
  lcl_app=>end_of_selection( ).
