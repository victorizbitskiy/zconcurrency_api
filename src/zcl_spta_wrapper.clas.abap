class ZCL_SPTA_WRAPPER definition
  public
  create public .

public section.

  class-methods SERIALIZE
    importing
      !IO_TASK type ref to ZCL_ABSTRACT_TASK
    returning
      value(RV_TASK) type XSTRING .
  class-methods DESERIALIZE
    importing
      !IV_TASK type XSTRING
    returning
      value(RO_TASK) type ref to ZCL_ABSTRACT_TASK .
  class-methods PROGRESS_INDICATOR
    importing
      !IV_COMPLETED type I optional
      !IV_TOTAL type I optional
      !IV_TEXT type STRING optional .
  methods CONSTRUCTOR
    importing
      !IV_SERVER_GROUP type RFCGR default SPACE
      !IV_MAX_NO_OF_TASKS type I default 10
      !IV_NO_RESUBMISSION_ON_ERROR type BOOLE_D default SPACE
      !IO_MESSAGE_HANDLER type ref to ZIF_MESSAGE_HANDLER .
  methods START
    importing
      !IO_TASKS type ref to ZIF_COLLECTION
    returning
      value(RO_RESULTS) type ref to ZIF_COLLECTION .
protected section.
private section.

  data MV_SERVER_GROUP type RFCGR .
  data MV_MAX_NO_OF_TASKS type I .
  data MV_NO_RESUBMISSION_ON_ERROR type BOOLE_D .
  data MO_MESSAGE_HANDLER type ref to ZIF_MESSAGE_HANDLER .
ENDCLASS.



CLASS ZCL_SPTA_WRAPPER IMPLEMENTATION.


  method CONSTRUCTOR.

    mv_server_group = iv_server_group.
    mv_max_no_of_tasks = iv_max_no_of_tasks.
    mv_no_resubmission_on_error = iv_no_resubmission_on_error.
    mo_message_handler = io_message_handler.

  endmethod.


  method DESERIALIZE.

    CALL TRANSFORMATION id_indent
      SOURCE XML iv_task
      RESULT obj = ro_task.

  endmethod.


  method PROGRESS_INDICATOR.

    DATA: lv_percentage TYPE i,
          lv_text TYPE char50,
          lv_completed TYPE char5,
          lv_total TYPE char5.

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


  endmethod.


  method SERIALIZE.

    CALL TRANSFORMATION id_indent
      SOURCE obj = io_task
      RESULT XML rv_task.

  endmethod.


  method START.

    DATA: lo_spta_gateway TYPE REF TO zcl_spta_gateway,
          lo_tasks TYPE REF TO zcl_collection,
          lo_results TYPE REF TO zcl_collection.

    lo_tasks ?= io_tasks.
    CREATE OBJECT lo_results.

    CREATE OBJECT lo_spta_gateway
      EXPORTING
        io_tasks                    = lo_tasks
        iv_no_resubmission_on_error = mv_no_resubmission_on_error
        io_message_handler          = mo_message_handler
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
        user_param               = lo_spta_gateway
      EXCEPTIONS
        invalid_server_group     = 1
        no_resources_available   = 2
        OTHERS                   = 3.
    IF sy-subrc = 0.
      ro_results ?= lo_spta_gateway->mo_results.
    ENDIF.


  endmethod.
ENDCLASS.
