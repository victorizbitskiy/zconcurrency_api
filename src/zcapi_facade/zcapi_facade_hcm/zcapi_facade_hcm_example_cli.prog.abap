*&---------------------------------------------------------------------*
*& Include          ZCAPI_FACADE_HCM_EXAMPLE_CLI
*&---------------------------------------------------------------------*
CLASS lcl_app IMPLEMENTATION.
  METHOD start_of_selection.
    DATA: ls_pernrs LIKE LINE OF mt_pernrs.

*   Modeling the selection of personnel numbers
    DO 10 TIMES.
      ls_pernrs-sign = 'I'.
      ls_pernrs-option = 'EQ'.
      ls_pernrs-low = sy-index.
      APPEND ls_pernrs TO mt_pernrs.
    ENDDO.

  ENDMETHOD.

  METHOD end_of_selection.
    DATA: lv_package_size    TYPE int4,
          ls_params          TYPE lcl_context=>ty_params,
          lo_context         TYPE REF TO lcl_context,
          lo_capi_facade_hcm TYPE REF TO zcl_capi_facade_hcm,
          lt_employees       TYPE lcl_result=>ty_t_employees.

    FIELD-SYMBOLS: <ls_employees> LIKE LINE OF lt_employees.

*   2 Pernr number per task. For example only.
*   Use the default '1000'.
    lv_package_size = 2.

    ls_params-begda = sy-datum.
    ls_params-endda = sy-datum.

    CREATE OBJECT lo_context
      EXPORTING
        is_params = ls_params.

    CREATE OBJECT lo_capi_facade_hcm
      EXPORTING
        io_context         = lo_context
        it_pernrs          = mt_pernrs
        iv_task_class_name = 'LCL_TASK'
        iv_package_size    = lv_package_size.
*
    lo_capi_facade_hcm->execute( IMPORTING et_result = lt_employees ).

    LOOP AT lt_employees ASSIGNING <ls_employees>.
      WRITE: / <ls_employees>-pernr, <ls_employees>-ename.
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_context IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    ms_params = is_params.
  ENDMETHOD.

  METHOD get_params.
    rs_params = ms_params.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_task DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    DATA: lo_context TYPE REF TO lcl_context.

*   Set Pernrs numbers to mt_pernrs of Task
    super->constructor( io_context ).

*   Set Context parameters
    lo_context ?= io_context.
    ms_params = lo_context->get_params( ).

  ENDMETHOD.

  METHOD zif_capi_callable~call.
    DATA: lt_employees TYPE lcl_result=>ty_t_employees,
          ls_employees LIKE LINE OF lt_employees.

    FIELD-SYMBOLS: <ls_pernr> LIKE LINE OF mt_pernrs.

    LOOP AT mt_pernrs ASSIGNING <ls_pernr>.
      ls_employees-pernr = <ls_pernr>-low.

      CASE <ls_pernr>-low.
        WHEN 00000001.
          ls_employees-ename = 'John Smyth 1'.
        WHEN 00000002.
          ls_employees-ename = 'John Smyth 2'.
        WHEN 00000003.
          ls_employees-ename = 'John Smyth 3'.
        WHEN 00000004.
          ls_employees-ename = 'John Smyth 4'.
        WHEN 00000005.
          ls_employees-ename = 'John Smyth 5'.
        WHEN 00000006.
          ls_employees-ename = 'John Smyth 6'.
        WHEN 00000007.
          ls_employees-ename = 'John Smyth 7'.
        WHEN 00000008.
          ls_employees-ename = 'John Smyth 8'.
        WHEN 00000009.
          ls_employees-ename = 'John Smyth 9'.
        WHEN 00000010.
          ls_employees-ename = 'John Smyth 10'.
        WHEN OTHERS.
      ENDCASE.

      INSERT ls_employees INTO TABLE lt_employees.
    ENDLOOP.

    CREATE OBJECT ro_result
      TYPE
      lcl_result
      EXPORTING
        it_employees = lt_employees.

  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_result IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mt_employees = it_employees.
  ENDMETHOD.

  METHOD zif_capi_facade_hcm_result~get.
    et_result = mt_employees.
  ENDMETHOD.                    "get
ENDCLASS.
