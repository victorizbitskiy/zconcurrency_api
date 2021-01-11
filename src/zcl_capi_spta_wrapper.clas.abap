CLASS zcl_capi_spta_wrapper DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS serialize
      IMPORTING
        !io_task       TYPE REF TO zcl_capi_abstract_task
      RETURNING
        VALUE(rv_task) TYPE xstring .
    CLASS-METHODS deserialize
      IMPORTING
        !iv_task       TYPE xstring
      RETURNING
        VALUE(ro_task) TYPE REF TO zcl_capi_abstract_task .
    CLASS-METHODS progress_indicator
      IMPORTING
        !iv_completed TYPE i OPTIONAL
        !iv_total     TYPE i OPTIONAL
        !iv_text      TYPE string OPTIONAL .
    METHODS constructor
      IMPORTING
        !iv_server_group             TYPE rfcgr DEFAULT space
        !iv_max_no_of_tasks          TYPE i DEFAULT 10
        !iv_no_resubmission_on_error TYPE boole_d DEFAULT space
        !io_capi_message_handler     TYPE REF TO zif_capi_message_handler .
    METHODS start
      IMPORTING
        !io_tasks         TYPE REF TO zif_capi_collection
      RETURNING
        VALUE(ro_results) TYPE REF TO zif_capi_collection .
  PROTECTED SECTION.
  PRIVATE SECTION.

    DATA mv_server_group TYPE rfcgr .
    DATA mv_max_no_of_tasks TYPE i .
    DATA mv_no_resubmission_on_error TYPE boole_d .
    DATA mo_capi_message_handler TYPE REF TO zif_capi_message_handler .
ENDCLASS.



CLASS ZCL_CAPI_SPTA_WRAPPER IMPLEMENTATION.


  METHOD constructor.

    mv_server_group = iv_server_group.
    mv_max_no_of_tasks = iv_max_no_of_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_capi_message_handler = io_capi_message_handler.

  ENDMETHOD.


  METHOD deserialize.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_task
      RESULT obj = ro_task.

  ENDMETHOD.


  METHOD progress_indicator.

    DATA: lv_percentage TYPE i,
          lv_text       TYPE char50,
          lv_completed  TYPE char5,
          lv_total      TYPE char5.

    IF iv_completed IS SUPPLIED AND iv_total IS SUPPLIED.

      IF iv_total IS NOT INITIAL.
        lv_percentage = ( iv_completed * 100 ) / iv_total.
      ENDIF.

      lv_completed = iv_completed.
      lv_total = iv_total.
      CONDENSE: lv_completed, lv_total.
      CONCATENATE 'Completed'(001) lv_completed 'of'(002) lv_total INTO lv_text SEPARATED BY space.

    ELSE.
      lv_percentage = 0.
      lv_text = iv_text.
    ENDIF.

    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
      EXPORTING
        percentage = lv_percentage
        text       = lv_text.


  ENDMETHOD.


  METHOD serialize.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_task
      RESULT XML rv_task.

  ENDMETHOD.


  METHOD start.

    DATA: lo_capi_spta_gateway TYPE REF TO zcl_capi_spta_gateway,
          lo_tasks             TYPE REF TO zcl_capi_collection,
          lo_results           TYPE REF TO zcl_capi_collection.

    lo_tasks ?= io_tasks.
    CREATE OBJECT lo_results.

    CREATE OBJECT lo_capi_spta_gateway
      EXPORTING
        io_tasks                    = lo_tasks
        iv_no_resubmission_on_error = mv_no_resubmission_on_error
        io_capi_message_handler     = mo_capi_message_handler
        io_results                  = lo_results.

    CALL FUNCTION 'SPTA_PARA_PROCESS_START_2'
      EXPORTING
        server_group             = mv_server_group
        max_no_of_tasks          = mv_max_no_of_tasks
        before_rfc_callback_form = 'BEFORE_RFC'
        in_rfc_callback_form     = 'IN_RFC'
        after_rfc_callback_form  = 'AFTER_RFC'
        callback_prog            = 'ZCONCURRENCY_API'
      CHANGING
        user_param               = lo_capi_spta_gateway
      EXCEPTIONS
        invalid_server_group     = 1
        no_resources_available   = 2
        OTHERS                   = 3.
    IF sy-subrc = 0.
      ro_results ?= lo_capi_spta_gateway->mo_results.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
