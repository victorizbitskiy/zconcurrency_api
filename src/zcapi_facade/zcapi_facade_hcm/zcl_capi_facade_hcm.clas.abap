CLASS zcl_capi_facade_hcm DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor
      IMPORTING
        !io_context         TYPE REF TO zcl_capi_facade_hcm_abstr_cntx
        !it_pernrs          TYPE zif_capi_facade_hcm_context=>ty_t_pernrs
        !iv_task_class_name TYPE string
        !iv_package_size    TYPE i DEFAULT 1000 .
    METHODS execute
      IMPORTING
        !iv_server_group TYPE rfcgr DEFAULT 'parallel_generators'
      EXPORTING
        !et_result       TYPE ANY TABLE
      RAISING
        zcx_capi_tasks_invocation .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mo_context TYPE REF TO zcl_capi_facade_hcm_abstr_cntx .
    DATA mt_pernrs TYPE zif_capi_facade_hcm_context=>ty_t_pernrs .
    DATA mv_task_class_name TYPE string .
    DATA mv_package_size TYPE i .

    METHODS error_process
      IMPORTING
        !io_message_handler TYPE REF TO zif_capi_message_handler .
    METHODS results_to_table
      IMPORTING
        !io_results TYPE REF TO zif_capi_collection
      EXPORTING
        !et_result  TYPE ANY TABLE .
    METHODS max_no_of_tasks
      IMPORTING
        !iv_server_group          TYPE rfcgr OPTIONAL
      RETURNING
        VALUE(rv_max_no_of_tasks) TYPE i .
    METHODS long_class_name
      RETURNING
        VALUE(rv_long_class_name) TYPE string .
ENDCLASS.



CLASS ZCL_CAPI_FACADE_HCM IMPLEMENTATION.


  METHOD constructor.
    mo_context = io_context.
    mt_pernrs = it_pernrs.
    mv_task_class_name = iv_task_class_name.
    mv_package_size = iv_package_size.
  ENDMETHOD.


  METHOD error_process.
    DATA: lt_message_list        TYPE zif_capi_message_handler=>ty_message_list_tab,
          ls_error_detail_header LIKE LINE OF lt_message_list.

    FIELD-SYMBOLS: <ls_message_list> LIKE LINE OF lt_message_list.

    FORMAT HOTSPOT ON.
    FORMAT COLOR 6.

    WRITE: / 'Errors occurred when tasks were executed in parallel. The data is inconsistent.'(001).
    WRITE: / 'Please restart the report.'(002).
    WRITE: / 'If the error persists after restarting, contact support.'(003).

    FORMAT HOTSPOT OFF.
    FORMAT RESET INTENSIFIED ON.
    SKIP.

    WRITE: / 'Details of errors:'(004).
    ls_error_detail_header-task_name = 'Task name'(005).
    ls_error_detail_header-rfcmsg = 'Error description'(006).
    WRITE: / ls_error_detail_header-task_name, ls_error_detail_header-rfcmsg.

    lt_message_list = io_message_handler->get_message_list( ).
    LOOP AT lt_message_list ASSIGNING <ls_message_list>.
      WRITE: / <ls_message_list>-task_name, <ls_message_list>-rfcmsg.
    ENDLOOP.
  ENDMETHOD.


  METHOD execute.
    DATA: lv_pos_till         TYPE i,
          lv_number_of_pernrs TYPE i,
          lt_pernrs           LIKE mt_pernrs,
          lt_pernrs_part      LIKE mt_pernrs,
          lv_long_class_name  TYPE string.

    DATA: lo_tasks           TYPE REF TO zcl_capi_collection,
          lo_task            TYPE REF TO zcl_capi_facade_hcm_abstr_task,
          lo_executor        TYPE REF TO zif_capi_executor_service,
          lo_message_handler TYPE REF TO zcl_capi_message_handler,
          lo_results         TYPE REF TO zif_capi_collection.

    DATA: lv_max_no_of_tasks TYPE i.

*   The execute( ) method is an implementation of the Facade structural pattern.
*   It is designed to simplify the parallelization process and use the Abap Concurrency API.

    lv_long_class_name = long_class_name( ).
    lt_pernrs = mt_pernrs.

    CREATE OBJECT lo_tasks.

    lv_number_of_pernrs = lines( lt_pernrs ).

*   Divide personnel numbers into parts for each task
    DO.
*     Out of personnel numbers?
      IF lv_number_of_pernrs IS INITIAL.
        EXIT. " Yes
      ENDIF.

      IF lv_number_of_pernrs < mv_package_size.
        lv_pos_till = lv_number_of_pernrs.
      ELSE.
        lv_pos_till = mv_package_size.
      ENDIF.

      APPEND LINES OF lt_pernrs FROM 1 TO lv_pos_till TO lt_pernrs_part.
      DELETE lt_pernrs FROM 1 TO lv_pos_till.

      TRY.
          mo_context->zif_capi_facade_hcm_context~set_pernrs( lt_pernrs_part ).

          CREATE OBJECT lo_task TYPE (lv_long_class_name)
            EXPORTING
              io_context = mo_context.

          lo_tasks->zif_capi_collection~add( lo_task ).

        CATCH cx_root.
          MESSAGE 'The task object could not be created'(000) TYPE 'E'.
      ENDTRY.

      lv_number_of_pernrs = lines( lt_pernrs ).
      CLEAR: lt_pernrs_part.
    ENDDO.

    CREATE OBJECT lo_message_handler.
    lv_max_no_of_tasks = max_no_of_tasks( iv_server_group ).

    lo_executor = zcl_capi_executors=>new_fixed_thread_pool( iv_server_group             = iv_server_group
                                                             iv_n_threads                = lv_max_no_of_tasks
                                                             iv_no_resubmission_on_error = abap_false
                                                             io_capi_message_handler     = lo_message_handler ).
*   Let's start the tasks for execution.
    lo_results = lo_executor->invoke_all( lo_tasks ).

    IF lo_message_handler->zif_capi_message_handler~has_messages( ) = abap_true.
      error_process( lo_message_handler ).
    ELSE.
      results_to_table( EXPORTING io_results = lo_results
                        IMPORTING et_result = et_result ).
    ENDIF.
  ENDMETHOD.


  METHOD long_class_name.
    DATA: lo_class      TYPE REF TO cl_oo_class,
          lv_class_name TYPE seoclsname.

*   This is a global class?
    TRY.
        lv_class_name = mv_task_class_name.
        lo_class ?= cl_oo_class=>get_instance( lv_class_name ).

*     Yes
        rv_long_class_name = mv_task_class_name.

      CATCH cx_root.
*     Nope
        CONCATENATE '\' 'PROGRAM=' sy-cprog '\CLASS=' mv_task_class_name INTO rv_long_class_name.
    ENDTRY.
  ENDMETHOD.


  METHOD max_no_of_tasks.
    DATA: lv_free_pbt_wps TYPE i.

    CALL FUNCTION 'SPBT_INITIALIZE'
      EXPORTING
        group_name                     = iv_server_group
      IMPORTING
*       MAX_PBT_WPS                    =
        free_pbt_wps                   = lv_free_pbt_wps
      EXCEPTIONS
        invalid_group_name             = 1
        internal_error                 = 2
        pbt_env_already_initialized    = 3
        currently_no_resources_avail   = 4
        no_pbt_resources_found         = 5
        cant_init_different_pbt_groups = 6
        OTHERS                         = 7.
    IF sy-subrc = 0.
      rv_max_no_of_tasks = lv_free_pbt_wps * 40 / 100.
    ELSE.
      rv_max_no_of_tasks = 5.
    ENDIF.
  ENDMETHOD.


  METHOD results_to_table.
    DATA: lo_data             TYPE REF TO data,
          lo_results_iterator TYPE REF TO zif_capi_iterator,
          lo_result           TYPE REF TO zif_capi_facade_hcm_result.

    FIELD-SYMBOLS: <lt_any> TYPE ANY TABLE.

    lo_results_iterator = io_results->get_iterator( ).

    CREATE DATA lo_data LIKE et_result.
    ASSIGN lo_data->* TO <lt_any>.

    IF <lt_any> IS ASSIGNED.
      WHILE lo_results_iterator->has_next( ) = abap_true.
        lo_result ?= lo_results_iterator->next( ).
        CLEAR <lt_any>.
        lo_result->get( IMPORTING et_result = <lt_any> ).
        INSERT LINES OF <lt_any> INTO TABLE et_result.
      ENDWHILE.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
