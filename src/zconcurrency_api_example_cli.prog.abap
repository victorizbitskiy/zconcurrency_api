*&---------------------------------------------------------------------*
*& Include          ZCONCURRENCY_API_EXAMPLE_CLI
*&---------------------------------------------------------------------*
CLASS lcl_app IMPLEMENTATION.
  METHOD main.
    DATA: lo_tasks            TYPE REF TO zcl_capi_collection,
          lo_task             TYPE REF TO lcl_task,
          lo_context          TYPE REF TO lcl_context,
          ls_params           TYPE lcl_context=>mty_params,
          lo_executor         TYPE REF TO zcl_capi_executor_service,
          lo_message_handler  TYPE REF TO zcl_capi_message_handler,
          lo_results          TYPE REF TO zif_capi_collection,
          lo_results_iterator TYPE REF TO zif_capi_iterator,
          lo_result           TYPE REF TO lcl_result,
          lv_result           TYPE char20.

*   Create collection of tasks
    CREATE OBJECT lo_tasks.

    DO 5 TIMES.
      ls_params-param = sy-index.

*     Optional object. It contains task parameters
      CREATE OBJECT lo_context
        EXPORTING
          is_params = ls_params.

      CREATE OBJECT lo_task
        EXPORTING
          io_context = lo_context.

      lo_tasks->zif_capi_collection~add( lo_task ).
    ENDDO.

    CREATE OBJECT lo_message_handler.

    CREATE OBJECT lo_executor
      EXPORTING
        iv_server_group             = 'parallel_generators'
        iv_max_no_of_tasks          = 2
        iv_no_resubmission_on_error = abap_false
        io_capi_message_handler     = lo_message_handler.

*   Main method
    lo_results = lo_executor->zif_capi_executor_service~invoke_all( lo_tasks ).

    lo_results_iterator = lo_results->get_iterator( ).

    WHILE lo_results_iterator->has_next( ) = abap_true.
      lo_result ?= lo_results_iterator->next( ).
      lv_result = lo_result->get( ).
      WRITE: / lv_result.
    ENDWHILE.

  ENDMETHOD.
ENDCLASS.
*----------------------------------------------------------------------*
*       CLASS lcl_context IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_context IMPLEMENTATION.
  METHOD constructor.
    ms_params = is_params.
  ENDMETHOD.                    "constructor

  METHOD get.
    rs_params = ms_params.
  ENDMETHOD.                    "lif_context~get
ENDCLASS.                    "lcl_context IMPLEMENTATION

*----------------------------------------------------------------------*
*       CLASS lcl_task DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_task IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.                    "constructor

  METHOD zif_capi_callable~call.

*    Uncomment this if you want to test the automatic restart of the task after a dump {

*    DATA: lv_dump_test TYPE boole_d
*    FIELD-SYMBOLS: <lfs_any> TYPE ANY.

*    IF lv_dump_test = abap_true.
*      <lfs_any> = 1.
*    ENDIF.
*    }

    mv_res = mo_context->ms_params-param ** 2.

*   Testing the progress bar
*    WAIT UP TO 2 SECONDS.

    CREATE OBJECT ro_result
      TYPE
      lcl_result
      EXPORTING
        iv_param  = mo_context->ms_params-param
        iv_result = mv_res.

  ENDMETHOD.                    "get
ENDCLASS.                    "lcl_task DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_result IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_param = iv_param.
    mv_result = iv_result.
  ENDMETHOD.                    "constructor

  METHOD get.
    DATA: lv_param  TYPE char10,
          lv_result TYPE char10.

    lv_param = mv_param.
    lv_result = mv_result.

    CONDENSE: lv_param, lv_result.
    CONCATENATE lv_param ` -> ` lv_result INTO rv_result.

  ENDMETHOD.                    "constructor

ENDCLASS.                    "lcl_result IMPLEMENTATION
