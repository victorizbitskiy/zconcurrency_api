*&---------------------------------------------------------------------*
*& Report ZCAPI_FACADE_HCM_EXAMPLE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcapi_facade_hcm_example.

INCLUDE: zcapi_facade_hcm_example_cld,
         zcapi_facade_hcm_example_cli.

START-OF-SELECTION.
  lcl_app=>start_of_selection( ).

END-OF-SELECTION.
  lcl_app=>end_of_selection( ).
