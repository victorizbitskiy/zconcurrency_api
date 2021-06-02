*&---------------------------------------------------------------------*
*& Include          ZCONCURRENCY_API_EXAMPLE_CLI
*&---------------------------------------------------------------------*
CLASS lcl_app IMPLEMENTATION.
  METHOD main.
    CONSTANTS: lc_server_group TYPE rfcgr VALUE 'parallel_generators'.

    DATA: lo_tasks                 TYPE REF TO zcl_capi_collection,
          lo_task                  TYPE REF TO lcl_task,
          lo_context               TYPE REF TO lcl_context,
          ls_params                TYPE lcl_context=>ty_params,
          lo_executor              TYPE REF TO zif_capi_executor_service,
          lo_message_handler       TYPE REF TO zcl_capi_message_handler,
          lt_message_list          TYPE zif_capi_message_handler=>ty_message_list_tab,
          lo_results               TYPE REF TO zif_capi_collection,
          lo_results_iterator      TYPE REF TO zif_capi_iterator,
          lo_result                TYPE REF TO lcl_result,
          lv_result                TYPE string,
          lo_capi_tasks_invocation TYPE REF TO zcx_capi_tasks_invocation,
          lv_message_text          TYPE string,
          lv_max_no_of_tasks       TYPE i.

    FIELD-SYMBOLS: <ls_message_list> LIKE LINE OF lt_message_list.

*   Create collection of tasks
    CREATE OBJECT lo_tasks.

    DO 10 TIMES.
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
    lv_max_no_of_tasks = zcl_capi_thread_pool_executor=>max_no_of_tasks( lc_server_group ).

    lo_executor = zcl_capi_executors=>new_fixed_thread_pool( iv_server_group             = lc_server_group
                                                             iv_n_threads                = lv_max_no_of_tasks
                                                             iv_no_resubmission_on_error = abap_false
                                                             io_capi_message_handler     = lo_message_handler ).
    TRY.
        lo_results = lo_executor->invoke_all( lo_tasks ).
        lo_results_iterator = lo_results->get_iterator( ).

        IF lo_message_handler->zif_capi_message_handler~has_messages( ) = abap_true.

          lt_message_list = lo_message_handler->zif_capi_message_handler~get_message_list( ).

          LOOP AT lt_message_list ASSIGNING <ls_message_list>.
            WRITE: / <ls_message_list>-task_id,
                     <ls_message_list>-task_name,
                     <ls_message_list>-rfcsubrc,
                     <ls_message_list>-rfcmsg.
          ENDLOOP.

        ELSE.

          WHILE lo_results_iterator->has_next( ) = abap_true.
            lo_result ?= lo_results_iterator->next( ).
            lv_result = lo_result->get( ).
            WRITE: / lv_result.
          ENDWHILE.

        ENDIF.

      CATCH zcx_capi_tasks_invocation INTO lo_capi_tasks_invocation.
        lv_message_text = lo_capi_tasks_invocation->get_text( ).
        WRITE lv_message_text.
    ENDTRY.

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
  ENDMETHOD.

  METHOD get.
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
    super->constructor( ).
    mo_context = io_context.
  ENDMETHOD.

  METHOD zif_capi_callable~call.
    DATA: ls_params TYPE lcl_context=>ty_params.

    ls_params = mo_context->get( ).
    mv_res = ls_params-param ** 2.

    CREATE OBJECT ro_result
      TYPE
      lcl_result
      EXPORTING
        iv_param  = ls_params-param
        iv_result = mv_res.

  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
*       CLASS lcl_result IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS lcl_result IMPLEMENTATION.
  METHOD constructor.
    mv_param = iv_param.
    mv_result = iv_result.
  ENDMETHOD.

  METHOD get.
    DATA: lv_param  TYPE string,
          lv_result TYPE string.

    lv_param = mv_param.
    lv_result = mv_result.

    CONDENSE lv_param.
    CONDENSE lv_result.
    CONCATENATE lv_param ` -> ` lv_result INTO rv_result.

  ENDMETHOD.
ENDCLASS.
