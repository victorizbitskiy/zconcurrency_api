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
protected section.

  class-data GV_TASK_COUNTER type I .
  data MV_ID type GUID_32 .
  data MV_NAME type STRING .

  methods CREATE_TASK_NAME .
  methods CREATE_TASK_ID .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CAPI_ABSTRACT_TASK IMPLEMENTATION.


  METHOD constructor.

    create_task_id( ).

    IF iv_name IS SUPPLIED.
      mv_name = iv_name.
    ELSE.
      create_task_name( ).
    ENDIF.

  ENDMETHOD.


  METHOD create_task_id.

    CALL FUNCTION 'GUID_CREATE'
      IMPORTING
        ev_guid_32 = mv_id.

  ENDMETHOD.


  METHOD create_task_name.
    DATA: lv_task_counter TYPE string.

    lv_task_counter = gv_task_counter = gv_task_counter + 1.
    CONCATENATE 'task_' lv_task_counter INTO mv_name.

  ENDMETHOD.


  METHOD zif_capi_callable~call.
*   This method needs to be overridden
  ENDMETHOD.


  METHOD zif_capi_task~get_id.
    rv_id = mv_id.
  ENDMETHOD.


  METHOD zif_capi_task~get_name.
    rv_name = mv_name.
  ENDMETHOD.
ENDCLASS.
