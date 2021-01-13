*&---------------------------------------------------------------------*
*& Include          ZCONCURRENCY_API_EXAMPLE_CLD
*&---------------------------------------------------------------------*
CLASS lcl_app DEFINITION FINAL.
  PUBLIC SECTION.

    CLASS-METHODS: main.

ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_context DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_context DEFINITION  FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    TYPES: BEGIN OF mty_params,
             param TYPE i,
           END OF mty_params.

    METHODS: constructor IMPORTING is_params TYPE mty_params,
             get RETURNING VALUE(rs_params) TYPE mty_params.

    DATA: ms_params TYPE mty_params.
ENDCLASS.                    "lcl_context DEFINITION
*----------------------------------------------------------------------*
*       CLASS lcl_task DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_task DEFINITION INHERITING FROM zcl_capi_abstract_task  FINAL.
  PUBLIC SECTION.

    DATA: mo_context TYPE REF TO lcl_context,
          mv_res     TYPE i.

    METHODS: constructor IMPORTING io_context TYPE REF TO lcl_context,
             zif_capi_callable~call REDEFINITION.

ENDCLASS.                    "lcl_task DEFINITION
*----------------------------------------------------------------------*
*       CLASS lcl_result DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES: if_serializable_object.

    METHODS: constructor IMPORTING iv_param  TYPE i
                                   iv_result TYPE i,
             get RETURNING VALUE(rv_result) TYPE char20.

  PRIVATE SECTION.
    DATA: mv_param TYPE i.
    DATA: mv_result TYPE i.

ENDCLASS.                    "lcl_result DEFINITION
