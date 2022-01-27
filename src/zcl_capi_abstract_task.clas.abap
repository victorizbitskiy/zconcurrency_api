class ZCL_CAPI_ABSTRACT_TASK definition
  public
  abstract
  create public .

public section.

  interfaces ZIF_CAPI_CALLABLE .
  interfaces IF_SERIALIZABLE_OBJECT .
  interfaces ZIF_CAPI_TASK .

  methods CONSTRUCTOR
    importing
      !IV_NAME type STRING optional .
  PROTECTED SECTION.

    CLASS-DATA gv_tasks_quantity TYPE i .
    DATA mv_id TYPE guid_32 .
    DATA mv_name TYPE string .

    METHODS create_task_name .
    METHODS create_task_id .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_ABSTRACT_TASK IMPLEMENTATION.


  METHOD constructor.

    create_task_id( ).

    IF iv_name IS INITIAL.
      create_task_name( ).
    ELSE.
      mv_name = iv_name.
    ENDIF.

  ENDMETHOD.


  METHOD create_task_id.

    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = mv_id.

  ENDMETHOD.


  METHOD create_task_name.

    DATA lv_tasks_quantity TYPE string.

    lv_tasks_quantity = gv_tasks_quantity = gv_tasks_quantity + 1.
    CONCATENATE 'task_' lv_tasks_quantity INTO mv_name.

  ENDMETHOD.


  METHOD zif_capi_callable~call.
    " This method needs to be overridden (REDEFINITION)
  ENDMETHOD.


  METHOD zif_capi_task~get_id.
    rv_result = mv_id.
  ENDMETHOD.


  METHOD zif_capi_task~get_name.
    rv_result = mv_name.
  ENDMETHOD.
ENDCLASS.
